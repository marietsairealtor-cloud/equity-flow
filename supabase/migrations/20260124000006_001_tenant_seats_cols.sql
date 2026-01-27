-- Tenants: seat_limit + seat_count (needed by get_current_tenant_seats + seat enforcement)

alter table public.tenants
  add column if not exists seat_limit int not null default 100,
  add column if not exists seat_count int not null default 0;

-- Backfill seat_count from memberships
update public.tenants t
set seat_count = coalesce(m.cnt, 0)
from (
  select tenant_id, count(*)::int as cnt
  from public.tenant_memberships
  group by tenant_id
) m
where m.tenant_id = t.id;

update public.tenants set seat_count = 0 where seat_count is null;

-- Keep seat_count in sync
create or replace function public._sync_tenant_seat_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $m$
declare
  v_tenant_id uuid := coalesce(new.tenant_id, old.tenant_id);
begin
  update public.tenants t
  set seat_count = (
    select count(*)::int
    from public.tenant_memberships tm
    where tm.tenant_id = v_tenant_id
  )
  where t.id = v_tenant_id;

  return null;
end;
$m$;

drop trigger if exists trg_sync_tenant_seat_count_ins on public.tenant_memberships;
drop trigger if exists trg_sync_tenant_seat_count_del on public.tenant_memberships;

create trigger trg_sync_tenant_seat_count_ins
after insert on public.tenant_memberships
for each row execute function public._sync_tenant_seat_count();

create trigger trg_sync_tenant_seat_count_del
after delete on public.tenant_memberships
for each row execute function public._sync_tenant_seat_count();