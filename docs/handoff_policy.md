# Cross-Chat Handoff Policy (v1)

## 1) Source of truth
- `docs/now.md` is the single source of truth for:
  - date/timezone, mode (local/remote), host, blocker, goal, do-not-touch.
- `docs/handoff_latest.txt` is the single artifact to paste into the next chat.

## 2) When to update `docs/now.md`
Update `docs/now.md` immediately when ANY of these change:
- Goal, blocker, mode, host, target DB
- “Do not touch” list
- Repro command(s)
- Probe command(s)
- Last known good probe result

If nothing changed, do not edit `docs/now.md`.

## 3) When `docs/now.md` is required
A handoff is invalid unless `docs/now.md` contains, at minimum:
- Date (with timezone)
- Goal
- Mode
- Host
- Blocker (or “none”)
- Repro
- Expected vs Actual
- Last change + file list
- Probe + last known good probe
- Next step
- Do-not-touch list

## 4) Handoff generation (the only approved way)
- Run: `npm run handoff`
- Outputs must be created:
  - `docs/handoff_snapshot_*.txt`
  - `docs/handoff_latest.txt` (must equal the newest snapshot)
- Clipboard must contain the full snapshot text.

## 5) What the snapshot must include (required sections)
Snapshot must include, in order:
A) Header: Date, timezone, mode, host, target DB
B) Goal + Blocker
C) `npx supabase status` output
D) Probe output (at least: `npm run build`)
E) App runtime info (if available): node/npm versions, git branch
F) Git summary:
   - `git status --porcelain`
   - `git diff --stat` (or explicit “no diff”)
G) Next step + do-not-touch

If any section fails to collect, snapshot must include the error text inline and still write both files.

## 6) Rule: no migration / schema drift in “handoff work”
While the goal is “handoff automation”:
- Do not touch: billing/pricing/tiers/invites/storage/RLS/old migrations/feature work.
- Do not run `supabase db push/reset` unless the goal explicitly says local DB debugging.
- If a command changes state, it must be declared in `docs/now.md` first.

## 7) PowerShell safety rules (non-negotiable)
- Never generate SQL/migrations via PowerShell interpolated strings.
- Never emit dollar-quoted tags like `$function$` / `$tag$` from PowerShell.
- Prefer:
  - single-quoted here-strings `@' ... '@` for any literal blocks
  - writing plain text files without embedded SQL execution
- If a script must call SQL, it must call a `.sql` file that already exists on disk (no inline SQL).

## 8) Passing criteria for “handoff is done”
Handoff is considered complete only if:
- `npm run handoff` succeeds end-to-end
- both output files exist
- `docs/handoff_latest.txt` contains all required sections A–G
- `npm run build` output is captured (pass or fail is fine; must be captured)
- next step is explicit and matches do-not-touch constraints

## 9) What to paste into the next chat
Paste ONLY:
- `docs/handoff_latest.txt`
Do not paraphrase. Do not summarize.

## 10) If something fails
If `npm run handoff` fails:
- Do not “try random fixes.”
- Update `docs/now.md`:
  - Blocker = exact error
  - Actual = exact error
  - Hypothesis = 1 sentence
  - Next step = 1 command to verify/fix
- Re-run `npm run handoff`.
