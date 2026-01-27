-- (comment cleaned: removed schema-cache wording)

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
join public.tenants t on t.id = tm.tenant_id;

-- RLS on views uses underlying tables' RLS.
-- Ensure tenant_memberships RLS allows selecting own rows (should already).
-- If not, you must add it later.

grant select on public.v_entitlements to authenticated;