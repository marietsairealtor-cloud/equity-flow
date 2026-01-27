-- user_profiles: enable self access so the row can exist and be read/updated by the owner
alter table public.user_profiles enable row level security;

drop policy if exists user_profiles_select_own on public.user_profiles;
create policy user_profiles_select_own
on public.user_profiles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists user_profiles_insert_own on public.user_profiles;
create policy user_profiles_insert_own
on public.user_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists user_profiles_update_own on public.user_profiles;
create policy user_profiles_update_own
on public.user_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- list all workspaces for the current user (does NOT depend on current_tenant_id)
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
as $function$
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
  order by tm.created_at desc;
$function$;

revoke all on function public.get_my_workspaces() from public;
grant execute on function public.get_my_workspaces() to authenticated;