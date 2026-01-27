-- Ensure start_trial transitions a workspace into trialing + core (no tier=free during trial)
-- This resolves gate/entitlements inconsistency.

create or replace function public.start_trial(p_tenant_id uuid, p_days integer default 14)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $20260126100752_fix_start_trial_sets_core_trialing$
declare
  v_trial_ends timestamptz := now() + (p_days || ' days')::interval;
begin
  update public.tenants t
    set subscription_status = 'trialing'::public.subscription_status,
        subscription_tier   = 'core',
        trial_started_at    = coalesce(t.trial_started_at, now()),
        trial_ends_at       = v_trial_ends
  where t.id = p_tenant_id;

  -- keep existing billing/audit logic if you have it elsewhere; this is the minimal state fix
end;
$20260126100752_fix_start_trial_sets_core_trialing$;

grant execute on function public.start_trial(uuid, integer) to authenticated;
grant execute on function public.start_trial(uuid) to authenticated;

do $20260126100752_fix_start_trial_sets_core_trialing$
begin

exception when others then
  null;
end $20260126100752_fix_start_trial_sets_core_trialing$;
