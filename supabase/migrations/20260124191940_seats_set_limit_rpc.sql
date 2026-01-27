create or replace function public.set_current_tenant_seat_limit(p_seat_limit int)
returns table(tenant_id uuid, seat_limit int, seat_count int)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $function$
declare
  v_tenant uuid;
begin
  v_tenant := public.current_tenant_id();
  if v_tenant is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.is_owner_or_admin(v_tenant) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  if p_seat_limit is null or p_seat_limit < 1 then
    raise exception 'INVALID_SEAT_LIMIT';
  end if;

  update public.tenants
  set seat_limit = p_seat_limit
  where id = v_tenant;

  return query
  select t.id, t.seat_limit, t.seat_count
  from public.tenants t
  where t.id = v_tenant;
end $function$;

revoke all on function public.set_current_tenant_seat_limit(int) from public;
grant execute on function public.set_current_tenant_seat_limit(int) to authenticated;