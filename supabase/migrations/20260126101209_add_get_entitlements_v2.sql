create or replace function public.get_entitlements_v2()
returns table (
  tenant_id uuid,
  workspace_name text,
  role text,
  tier text,
  status text,
  trial_ends_at timestamptz
)
language sql
stable
security definer
set search_path = public, auth, extensions
as $$
  select
    tm.tenant_id,
    t.workspace_name,
    tm.role,
    case
      when t.trial_started_at is not null
       and t.trial_ends_at is not null
       and now() < t.trial_ends_at
      then 'core'
      else coalesce(t.subscription_tier, 'free')
    end as tier,
    case
      when t.trial_started_at is not null
       and t.trial_ends_at is not null
       and now() < t.trial_ends_at
      then 'trialing'
      else coalesce(t.subscription_status::text, 'pending')
    end as status,
    t.trial_ends_at
  from public.tenant_memberships tm
  join public.tenants t on t.id = tm.tenant_id
  where tm.user_id = auth.uid()
  order by tm.created_at desc nulls last;
$$;

grant execute on function public.get_entitlements_v2() to authenticated;

do $$
begin

exception when others then
  null;
end $$;
