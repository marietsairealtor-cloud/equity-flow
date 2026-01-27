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
    t.subscription_tier as tier,
    t.subscription_status as status,
    t.trial_ends_at
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
  order by tm.created_at desc;
$function$;

revoke all on function public.get_my_workspaces() from public;
grant execute on function public.get_my_workspaces() to authenticated;