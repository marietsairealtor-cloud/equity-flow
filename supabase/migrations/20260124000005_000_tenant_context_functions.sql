-- Tenant context helpers (required by documents RLS)

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
as $m$
  select coalesce(
    nullif(auth.jwt()->>'tenant_id','')::uuid,
    nullif(current_setting('app.tenant_id', true),'')::uuid
  );
$m$;

create or replace function public.tenant_write_allowed(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $m$
  select
    p_tenant_id is not null
    and exists (select 1 from public.tenants t where t.id = p_tenant_id)
    and exists (
      select 1
      from public.tenant_memberships tm
      where tm.tenant_id = p_tenant_id
        and tm.user_id = auth.uid()
    );
$m$;

create or replace function public.can_write_current_tenant()
returns boolean
language sql
stable
as $m$
  select public.tenant_write_allowed(public.current_tenant_id());
$m$;

grant execute on function public.current_tenant_id() to authenticated;
grant execute on function public.tenant_write_allowed(uuid) to authenticated;
grant execute on function public.can_write_current_tenant() to authenticated;