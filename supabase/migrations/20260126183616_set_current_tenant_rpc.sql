-- set_current_tenant RPC (canonical; idempotent)
-- Note: uses a named dollar-quote tag (never $$) to avoid PowerShell $$ expansion issues.

drop function if exists public.set_current_tenant(uuid);

create function public.set_current_tenant(p_tenant_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $set_current_tenant$
declare
  v_user_id uuid;
  v_ok boolean;
begin
  v_user_id := public.current_user_id();

  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select exists (
    select 1
    from public.tenant_memberships tm
    where tm.user_id = v_user_id
      and tm.tenant_id = p_tenant_id
  ) into v_ok;

  if not v_ok then
    raise exception 'NOT_MEMBER' using errcode = '42501';
  end if;

  insert into public.user_profiles (user_id, current_tenant_id)
  values (v_user_id, p_tenant_id)
  on conflict (user_id)
  do update set current_tenant_id = excluded.current_tenant_id;

  return p_tenant_id;
end;
$set_current_tenant$;

revoke all on function public.set_current_tenant(uuid) from public;
grant execute on function public.set_current_tenant(uuid) to authenticated;