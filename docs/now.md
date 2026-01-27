Date: 2026-01-27 (America/Toronto)
Goal: Standardize cross-chat handoff so the next chat can continue with zero re-explaining.

Mode: local
Target DB: local Supabase stack (Docker required)
Host: http://localhost:3001

Blocker: intermittent Supabase status (container not found) unless stack is freshly started and kept running

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
- Verified end-to-end:
  - npm run handoff succeeds and writes snapshot + latest
  - Local proof loop can pass when stack is up: supabase start → supabase status → supabase db reset → supabase status

Last change:
- scripts/handoff-snapshot.ps1
  - Required now.md field gating
  - Captures: supabase status + probe output + build output + git diff summary
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
- Local proven loop (no db push):
  - npx supabase start
  - npx supabase status
  - npx supabase db reset
  - npx supabase status
- Build probe:
  - npm run build

Last known good probe:
- 2026-01-27: local proven loop passed (when stack running) + npm run build succeeded + npm run handoff succeeded (snapshot + latest written)

Next step:
- Keep stack up when capturing evidence (run start/status first)
- Run npm run handoff
- Paste docs/handoff_latest.txt into the next chat
- Commit/push any tracked file changes (if git status shows diffs)

Do-not-touch:
- billing/pricing/tiers
- invites
- storage
- RLS changes
- old migrations / migration history
- feature work beyond handoff automation + deterministic local bring-up/proof loop
