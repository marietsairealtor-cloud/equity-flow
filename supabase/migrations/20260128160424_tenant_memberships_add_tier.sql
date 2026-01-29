begin;

alter table public.tenant_memberships
  add column if not exists tier text;

-- Backfill from tenants.subscription_tier (enum) if present, else default 'core'
do $do$
begin
  if to_regclass('public.tenants') is not null and exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name='tenants' and column_name='subscription_tier'
  ) then
    update public.tenant_memberships tm
    set tier = coalesce(tm.tier, t.subscription_tier::text, 'core')
    from public.tenants t
    where t.id = tm.tenant_id;
  else
    update public.tenant_memberships
    set tier = coalesce(tier, 'core');
  end if;
end
$do$;

commit;