# Contracts (single source of truth)

Last updated: 2026-01-25

## 1) Tenant context contract (authoritative)

**Single source of truth:** public.user_profiles.current_tenant_id

Rules:
- UI + server routes must treat user_profiles.current_tenant_id as authoritative for “current workspace”.
- JWT 	enant_id claim may be stale and must not be treated as authoritative for current tenant selection.
- SQL editor / admin contexts may set a tenant override via set_config('app.tenant_id', '<uuid>', true).

Resolution:
- public.current_user_id() resolves the current user id (prefers uth.uid(), falls back to JWT sub when needed).
- public.current_tenant_id() resolves current tenant in this order:
  1) current_setting('app.tenant_id', true) (if set)
  2) user_profiles.current_tenant_id via current_user_id()

Selection:
- Workspace switching must update user_profiles.current_tenant_id (via RPC or API route calling that RPC).
- Reads/writes must be scoped by current_tenant_id() (RLS + RPC filters).

## 2) Write-gating rules (billing/access)

Write allowed only when tenant access is permitted:
- public.tenant_write_allowed(p_tenant_id uuid) returns true only when:
  - 	enants.subscription_status IN ('trialing','active')
- public.can_write_current_tenant() delegates to:
  - 	enant_write_allowed(current_tenant_id())

All write RPCs must enforce:
- tenant_id matches current_tenant_id()
- can_write_current_tenant() is true (or return deterministic error)

## 3) Status enums (canonical)

### Deal status
Enum: public.deal_status

Canonical values:
- New
- Contacted
- Appointment Set
- Offer Made
- Under Contract
- Closed/Assigned
- Dead

Notes:
- public.deals.status is public.deal_status with default New.
- No CHECK constraints on deals.status (enum is the constraint).

### Subscription status (billing/access)
Enum: public.subscription_status

Canonical values:
- pending
- 	rialing
- ctive
- past_due
- canceled
- locked

Write gating depends on:
- allowed: 	rialing, ctive
- denied: everything else

### Subscription tier (product)
Tier values in app:
- ree
- core

## 4) RPC naming + signatures (stable)

Tenant + entitlements:
- public.get_entitlements() -> setof (tenant_id, workspace_name, role, tier, status, trial_ends_at)
- public.set_current_tenant(p_tenant_id uuid) -> void/record (validates membership; updates user_profiles.current_tenant_id)

Provisioning:
- public.provision_upgrade_save(p_workspace_name text, p_first_deal jsonb) -> { tenant_id uuid, deal_id uuid }
  - SECURITY DEFINER
  - authenticated only
  - idempotent (reuses first membership if exists)

Deals:
- public.get_deal(p_deal_id uuid) -> deal
  - must enforce: d.id = p_deal_id AND d.tenant_id = current_tenant_id()
- public.update_deal_status_rpc(p_deal_id uuid, p_status public.deal_status, p_expected_row_version int) -> deal
  - enforces tenant match + write allowed
  - enforces optimistic concurrency via ow_version
  - increments ow_version on success

Invites / members / seats:
- public.create_invite_rpc(...) -> invite
- public.accept_invite(...) -> membership
- public.revoke_invite_rpc(p_invite_id uuid) -> void
- public.get_invites_rpc(...) -> setof invites
- public.get_tenant_members(p_tenant_id uuid) -> setof (user_id, email, role, ...)
- public.remove_member_rpc(...) -> void

Billing transitions:
- public.start_trial(p_tenant_id uuid) -> tenant
- public.expire_trials() -> int

## 5) Error contract (deterministic)

RPCs/routes should return deterministic errors for:
- AUTH_REQUIRED
- WRITE_NOT_ALLOWED
- CONFLICT_OR_NOT_FOUND (used for row_version mismatch and/or tenant mismatch)
- NOT_MEMBER (when selecting/switching tenant without membership)

## 6) Debug surface policy

Default: no debug routes or debug RPCs in production.
If any debug functionality exists:
- must be removed from production build OR admin-gated at route + enforced by DB privileges/RLS
- debug RPCs must not be executable by non-admin roles
