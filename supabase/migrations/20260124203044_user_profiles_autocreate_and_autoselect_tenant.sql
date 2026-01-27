-- Ensure user_profiles exists + is populated, and current_tenant_id is auto-selected.
-- Fixes "no workspace" when profile row is missing.

create table if not exists public.user_profiles (
  user_id uuid primary key,
  current_tenant_id uuid null,
  created_at timestamptz not null default now()
);

-- Backfill profiles for any user that already has memberships
insert into public.user_profiles (user_id)
select distinct tm.user_id
from public.tenant_memberships tm
left join public.user_profiles up on up.user_id = tm.user_id
where up.user_id is null;

create or replace function public.ensure_user_profile_and_tenant()
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid;
  v_cur uuid;
  v_first uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    return;
  end if;

  insert into public.user_profiles (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  select current_tenant_id into v_cur
  from public.user_profiles
  where user_id = v_uid;

  if v_cur is null then
    select tm.tenant_id into v_first
    from public.tenant_memberships tm
    where tm.user_id = v_uid
    order by tm.created_at asc
    limit 1;

    if v_first is not null then
      update public.user_profiles
      set current_tenant_id = v_first
      where user_id = v_uid;
    end if;
  end if;
end $$;

revoke all on function public.ensure_user_profile_and_tenant() from public;
grant execute on function public.ensure_user_profile_and_tenant() to authenticated;

-- Auto-heal profile/selection whenever the app asks for entitlements
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
as $$
  with _ensure as (
    select public.ensure_user_profile_and_tenant()
  )
  select
    t.id as tenant_id,
    t.workspace_name,
    tm.role,
    t.subscription_tier,
    t.subscription_status as status,
    t.trial_ends_at
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
    and tm.tenant_id = public.current_tenant_id()
  limit 1;
$$;

revoke all on function public.get_entitlements() from public;
grant execute on function public.get_entitlements() to authenticated;
