-- Create view + grants, then force PostgREST schema reload

create or replace view public.v_entitlements as
select
  tm.user_id,
  tm.tenant_id,
  t.workspace_name,
  tm.role,
  case
    when t.trial_started_at is not null
     and t.trial_ends_at is not null
     and now() < t.trial_ends_at
      then 'core'
    else coalesce(t.subscription_tier::text, 'free')
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
join public.tenants t on t.id = tm.tenant_id;

revoke all on public.v_entitlements from public;
grant select on public.v_entitlements to authenticated;

-- PostgREST listens on channel "pgrst"
notify pgrst, 'reload schema';