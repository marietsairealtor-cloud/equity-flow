# Tenant Resolution (Lock)

## Precedence (source of truth)
1) `user_profiles.current_tenant_id` (lookup by `auth.uid()`)
2) `current_setting('app.tenant_id', true)` (dev/test override only)
3) `auth.jwt()->>'tenant_id'` (optional/last; only when `app.enable_jwt_tenant` is truthy)

## Null fallback
If `user_profiles.current_tenant_id` is NULL:
- fall back to dev override,
- then JWT (if enabled),
- else return NULL (RLS should deny by design).

## Mismatch behavior (explicitly non-breaking)
If profile tenant and JWT tenant are both non-NULL and differ:
- resolver prefers profile tenant and returns it
- `tenant_id_mismatch()` returns true
- no exceptions; no side effects in `current_tenant_id()`

## Canonical functions
- `public.current_tenant_id()` — stable, pure resolver
- `public.tenant_id_mismatch()` — stable boolean
- `public.log_tenant_mismatch(jsonb)` — side effects; call only from RPC entrypoints or middleware
- `public.find_jwt_tenant_refs()` — find drift (policies/functions using JWT tenant_id directly)
- `public.assert_no_jwt_tenant_refs()` — enforcement gate (call from proof loop)

## Enforcement rule
No RLS policy or helper function may reference `auth.jwt()->>'tenant_id'` directly.
Use `public.current_tenant_id()` (and `public.tenant_write_allowed(...)` / `public.can_write_current_tenant()`).