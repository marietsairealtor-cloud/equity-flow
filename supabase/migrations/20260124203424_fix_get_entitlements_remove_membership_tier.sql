-- Fix: tenant_memberships has no tier column. Tier is on tenants.
create or replace function public.get_entitlements()
returns table (
  tenant_id uuid,
  workspace_name text,
  role text,
  tier text,
  status public.subscription_status,
  trial_ends_at timestamptz
)
language sql
security definer
set search_path = public, extensions, pg_temp
as $20260124203424_fix_get_entitlements_remove_membership_tier$
  with _ensure as (
    select public.ensure_user_profile_and_tenant()
  )
  select
    t.id as tenant_id,
    t.workspace_name,
    tm.role,
    t.subscription_tier as tier,
    t.subscription_status as status,
    t.trial_ends_at
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
    and tm.tenant_id = public.current_tenant_id()
  limit 1;
$20260124203424_fix_get_entitlements_remove_membership_tier$;

revoke all on function public.get_entitlements() from public;
grant execute on function public.get_entitlements() to authenticated;

-- Also fix list rpc to use tenant tier
create or replace function public.get_my_workspaces()
returns table (
  tenant_id uuid,
  workspace_name text,
  role text,
  tier text,
  status public.subscription_status,
  trial_ends_at timestamptz
)
language sql
security definer
set search_path = public, extensions, pg_temp
as $20260124203424_fix_get_entitlements_remove_membership_tier$
  select
    t.id as tenant_id,
    t.workspace_name,
    tm.role,
    t.subscription_tier as tier,
    t.subscription_status as status,
    t.trial_ends_at
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
  order by tm.created_at desc;
$20260124203424_fix_get_entitlements_remove_membership_tier$;

revoke all on function public.get_my_workspaces() from public;
grant execute on function public.get_my_workspaces() to authenticated;
