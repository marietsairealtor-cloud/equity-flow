# Storage Spec (v1)

## Scope
Doc-only. No bucket/policy/RLS changes in this session.

## Goals
- Predictable storage cost (caps + enforcement plan)
- Simple mental model for users
- Works with multi-tenant isolation and deal-scoped files

## Buckets
### 1) deal-files
Single bucket for both photos and videos.
Reason: simplest ops, consistent URLs/paths, one policy surface.

## Object key convention
	enant/{tenant_id}/deal/{deal_id}/{kind}/{yyyy}/{mm}/{uuid}_{original_name}

- kind ∈ photo|video|doc|other
- Always include 	enant_id + deal_id in the path for deterministic authorization.

## Limits (Core defaults)
### Per-file
- Photos: max 15 MB
- Videos: max 250 MB
- Docs: max 25 MB

### Per-deal (soft caps)
- Photos: 200
- Videos: 20
- Total per deal: 3 GB

### Per-workspace (hard caps)
- Total stored: 50 GB
- Monthly upload: 25 GB

## Enforcement plan
### Client-side (immediate)
- Validate MIME + size before upload.
- Show remaining workspace quota (from server).
- Block uploads when quota would be exceeded.

### Server-side (authoritative)
- Upload workflow uses a server endpoint / RPC to request an upload grant:
  - Inputs: tenant_id, deal_id, kind, content_type, content_length
  - Checks: seat/tier access, tenant resolved, deal belongs to tenant, caps.
  - Returns: allowed=true/false + reason + normalized object path.

- Actual upload uses signed upload URL (or signed policy) restricted to that object key.
- On completion, client calls finalize endpoint:
  - Records object metadata (size, kind, content_type, path, created_by).

### Data model (future)
Table: deal_documents
- id, tenant_id, deal_id, kind, path, size_bytes, content_type, created_by, created_at
Indexes: (tenant_id, deal_id), (tenant_id)

### Cleanup
- When a deal is deleted (or archived), optionally enqueue cleanup to remove 	enant/{tenant_id}/deal/{deal_id}/...
- When over cap: enforce “no new uploads” rather than auto-deleting.

## Access control
- Reads: only members of tenant with resolved tenant_id matching object path.
- Writes: only after server grant; object path must match tenant/deal.

## Open decisions (explicit)
- Exact cap numbers (above are defaults; confirm before billing).
- Whether monthly upload cap resets on billing cycle or calendar month.
- Whether to allow “read-only access” to existing files when past_due/locked.
