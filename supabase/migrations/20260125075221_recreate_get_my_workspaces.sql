-- recreate get_my_workspaces with the correct OUT signature
drop function if exists public.get_my_workspaces();

create function public.get_my_workspaces()
returns table (
  tenant_id uuid,
  workspace_name text,
  role text,
  tier text,
  status public.subscription_status,
  trial_ends_at timestamptz,
  seat_limit int,
  seat_count int
)
language sql
stable
security definer
set search_path = public, auth
as $function$
  select
    t.id as tenant_id,
    t.workspace_name,
    tm.role::text as role,
    t.subscription_tier::text as tier,
    t.subscription_status as status,
    t.trial_ends_at,
    t.seat_limit,
    t.seat_count
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
  order by t.created_at desc;
$function$;

revoke all on function public.get_my_workspaces() from public;
grant execute on function public.get_my_workspaces() to authenticated;