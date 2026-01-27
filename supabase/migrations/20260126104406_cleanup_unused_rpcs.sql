-- Cleanup unused/failed schema-cache objects

drop view if exists public.v_entitlements;

drop function if exists public.get_entitlements_v2();

-- If created during earlier attempts; safe to drop if not used
drop function if exists public.start_trial_current_tenant_rpc();

do $20260126104406_cleanup_unused_rpcs$
begin

exception when others then
  null;
end $20260126104406_cleanup_unused_rpcs$;
