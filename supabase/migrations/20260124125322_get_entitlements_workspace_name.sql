begin;

drop function if exists public.get_entitlements();

create function public.get_entitlements()
returns table(
  tenant_id uuid,
  workspace_name text,
  role text,
  tier text,
  status public.subscription_status,
  trial_ends_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.id as tenant_id,
    t.workspace_name,
    (tm.role)::text as role,
    (t.subscription_tier)::text as tier,
    t.subscription_status as status,
    t.trial_ends_at
  from public.tenants t
  join public.tenant_memberships tm on tm.tenant_id = t.id
  where tm.user_id = auth.uid()
    and t.id = public.current_tenant_id()
  limit 1;
$$;

grant execute on function public.get_entitlements() to authenticated;

commit;
