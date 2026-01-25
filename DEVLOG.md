# Dev Log

## 2026-01-25 — Week 2 complete
Commit: 3798444

- Deals optimistic concurrency (row_version) proof passed (two-tab conflict test).
- Auth/session stable on http://localhost:3001 (avoid 127.0.0.1 cookie split).
- Workspace selection + gating via get_entitlements() working.
- Invites end-to-end (create/list/revoke + accept flows present), seat primitives in place.
- DB migrations pushed; remote database up to date.

