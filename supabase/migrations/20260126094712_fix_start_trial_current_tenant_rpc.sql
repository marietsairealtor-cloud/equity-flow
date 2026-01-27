-- Ensure start_trial_current_tenant_rpc exists + is executable, then force PostgREST schema reload

create or replace function public.start_trial_current_tenant_rpc()
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_tid uuid := public.current_tenant_id();
  v_is_owner boolean;
  v_trial_started_at timestamptz;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if v_tid is null then
    raise exception 'NO_CURRENT_TENANT';
  end if;

  select exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = v_tid
      and tm.user_id = v_uid
      and tm.role = 'owner'
  ) into v_is_owner;

  if not v_is_owner then
    raise exception 'OWNER_ONLY';
  end if;

  select t.trial_started_at
    into v_trial_started_at
  from public.tenants t
  where t.id = v_tid;

  if v_trial_started_at is not null then
    raise exception 'TRIAL_ALREADY_USED';
  end if;

  perform public.start_trial(v_tid);

  return jsonb_build_object('ok', true, 'tenant_id', v_tid, 'status', 'trialing', 'tier', 'core');
end;
$$;

grant execute on function public.start_trial_current_tenant_rpc() to authenticated;

-- Force PostgREST to reload schema cache
do $$
begin
  perform pg_notify('pgrst', 'reload schema');
exception when others then
  -- ignore if notify channel not present; local supabase typically supports it
  null;
end $$;
