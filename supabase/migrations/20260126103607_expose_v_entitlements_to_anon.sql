-- Remove anon exposure (security hardening)
revoke all on public.v_entitlements from anon;
revoke all on public.v_entitlements from public;

grant select on public.v_entitlements to authenticated;