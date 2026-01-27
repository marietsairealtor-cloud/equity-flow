-- Seat info (for UI + API checks)
create or replace function public.get_current_tenant_seats()
returns table(seat_limit int, seat_count int)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $20260124191422_seat_enforcement_ui_support$
  select t.seat_limit, t.seat_count
  from public.tenants t
  where t.id = public.current_tenant_id();
$20260124191422_seat_enforcement_ui_support$;

revoke all on function public.get_current_tenant_seats() from public;
grant execute on function public.get_current_tenant_seats() to authenticated;

-- Hard enforcement: block membership insert when full (covers any path)
create or replace function public.enforce_seat_limit_on_membership()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $20260124191422_seat_enforcement_ui_support$
declare
  v_limit int;
  v_count int;
begin
  select seat_limit, seat_count
    into v_limit, v_count
  from public.tenants
  where id = new.tenant_id
  for update;

  if v_limit is not null and v_count is not null and v_count >= v_limit then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  return new;
end $20260124191422_seat_enforcement_ui_support$;

drop trigger if exists trg_enforce_seat_limit_on_membership on public.tenant_memberships;
create trigger trg_enforce_seat_limit_on_membership
before insert on public.tenant_memberships
for each row
execute function public.enforce_seat_limit_on_membership();
