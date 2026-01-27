Date: 2026-01-26 (America/Toronto)
Goal: Standardize cross-chat handoff so the next chat can continue with zero re-explaining.

Mode: local
Target DB: local Supabase stack (Docker required)
Host: http://localhost:3001

Blocker: none

Repro:
- Run: npm run handoff
- Output:
  - docs/handoff_snapshot_*.txt
  - docs/handoff_latest.txt
- Snapshot must include: now.md fields + supabase status + probe output + build output + git diff summary (or explicit “no diff”)

Expected:
- Both files are created
- docs/handoff_latest.txt matches the newest snapshot
- Snapshot includes sections C–G: (C) supabase status, (D) probe output, (E) build output, (F) git status/diff summary, (G) environment/versions if available
- Snapshot is copied to clipboard

Actual:
- Not yet verified end-to-end after patch

Last change:
- scripts/handoff-snapshot.ps1
  - Added required now.md field gating
  - Captures: supabase status + probe output
  - Writes: docs/handoff_latest.txt
  - Copies snapshot to clipboard

Hypothesis:
- Prior handoff failures were caused by missing standardized metadata and unreliable command capture. Enforcing required fields + automated probes eliminates drift.

Test:
- Run: npm run handoff
- Confirm:
  - both files written
  - includes sections C–G
  - clipboard contains the full snapshot text

Probe:
- npm run build
Last known good probe:
- npm run build succeeded (per prior session notes)

Next step:
- Run npm run handoff
- Paste docs/handoff_latest.txt into the next chat

Do-not-touch:
- billing/pricing/tiers
- invites
- storage
- RLS changes
- old migrations / migration history
- feature work beyond handoff automation
Patch: Verified now.md fields + handoff script gating; next run should generate snapshot + latest + clipboard.
Which file changes: scripts/handoff-snapshot.ps1
Do not touch list: billing, pricing, tiers, invites, storage, RLS changes, old migrations, feature work beyond handoff automation
