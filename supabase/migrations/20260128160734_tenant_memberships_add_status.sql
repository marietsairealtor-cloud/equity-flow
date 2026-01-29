begin;

alter table public.tenant_memberships
  add column if not exists status text;

-- Backfill: default active
update public.tenant_memberships
set status = coalesce(status, 'active');

commit;