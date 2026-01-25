create or replace function public.start_trial(p_tenant_id uuid)
returns public.tenants
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  t public.tenants;
begin
  if p_tenant_id is null then
    raise exception 'TENANT_REQUIRED';
  end if;

  if not public.is_owner_or_admin(p_tenant_id) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select * into t
  from public.tenants
  where id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  -- Idempotent: only start if currently pending
  if t.subscription_status = 'pending'::public.subscription_status then
    update public.tenants
    set
      subscription_status = 'trialing'::public.subscription_status,
      trial_started_at = now(),
      trial_ends_at = now() + interval '14 days'
    where id = p_tenant_id
    returning * into t;
  end if;

  return t;
end $$;

revoke all on function public.start_trial(uuid) from public;
grant execute on function public.start_trial(uuid) to authenticated;