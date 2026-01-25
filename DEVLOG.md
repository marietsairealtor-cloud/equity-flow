# Dev Log

## 2026-01-25 — Week 2 complete
Commit: 3798444

- Deals optimistic concurrency (row_version) proof passed (two-tab conflict test).
- Auth/session stable on http://localhost:3001 (avoid 127.0.0.1 cookie split).
- Workspace selection + gating via get_entitlements() working.
- Invites end-to-end (create/list/revoke + accept flows present), seat primitives in place.
- DB migrations pushed; remote database up to date.

## 2026-01-25 — Week 3 started: Upgrade & Save idempotency
Commit: 4e5a0cf

- Added deals.idempotency_key + unique (tenant_id, idempotency_key).
- Replaced provision_upgrade_save with single PostgREST-friendly signature:
  provision_upgrade_save(p_first_deal jsonb, p_idempotency_key text, p_workspace_name text)
- Verified retry returns the same deal_id for same idempotency_key.

