Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$msg) { Write-Host "HARD_GATE_FAIL: $msg"; exit 1 }
function Ok([string]$msg) { Write-Host "HARD_GATE_OK: $msg" }

# Policy reminder:
# - Use PowerShell for .ps1 scripts + file ops
# - Use cmd.exe for npm/npx/docker (invoked via cmd /c)

$repoRoot = Get-Location
$nowPath = Join-Path $repoRoot "docs\now.md"
$envPath = Join-Path $repoRoot ".env.local"
$handoffLatest = Join-Path $repoRoot "docs\handoff_latest.txt"
$handoffGlob = Join-Path $repoRoot "docs\handoff_snapshot_*.txt"
$gitignorePath = Join-Path $repoRoot ".gitignore"

if (-not (Test-Path -LiteralPath $nowPath)) { Fail "Missing docs/now.md" }

# ----- (A) docs/now.md required fields present + NON-BLANK -----
$nowLines = Get-Content -LiteralPath $nowPath
$required = @(
  "Date","Goal","Mode","Host",
  "Repro","Expected","Actual",
  "Last change","Target DB",
  "Hypothesis","Test","Patch",
  "Which file changes","Next step"
)

$missing = @()
$blank = @()

foreach ($k in $required) {
  $found = $false
  foreach ($line in $nowLines) {
    if ($line -match ("^\s*" + [regex]::Escape($k) + "\s*:\s*(.*)\s*$")) {
      $found = $true
      $val = $Matches[1]
      if ([string]::IsNullOrWhiteSpace($val)) { $blank += $k }
      break
    }
  }
  if (-not $found) { $missing += $k }
}

if ($missing.Count -gt 0) { Fail ("docs/now.md missing required field(s): " + ($missing -join ", ")) }
if ($blank.Count -gt 0)   { Fail ("docs/now.md blank required field(s): " + ($blank -join ", ")) }
Ok "docs/now.md required fields present + non-blank"

# ----- (B) Probe block hygiene: commands only (no bullets/labels/prose) -----
$probeIdx = -1
for ($i=0; $i -lt $nowLines.Count; $i++) {
  if ($nowLines[$i] -match '^\s*Probe\s*:\s*$') { $probeIdx = $i; break }
}
if ($probeIdx -lt 0) { Fail "docs/now.md missing literal 'Probe:' line" }

$probeCmds = @()
for ($i=$probeIdx+1; $i -lt $nowLines.Count; $i++) {
  $l = $nowLines[$i].Trim()
  if ($l -eq "") { break }
  $probeCmds += $l
}
if ($probeCmds.Count -lt 1) { Fail "Probe block has no commands" }

$bad = @()
foreach ($c in $probeCmds) {
  if ($c -match '^\s*[-•*]') { $bad += $c; continue }
  if ($c -match '^\s*(Local|Remote|Run\s+in|Cmd)\s*:') { $bad += $c; continue }
  if ($c -match ';\s*$') { $bad += $c; continue }
  if ($c -notmatch '^(powershell|cmd|npm|npx)\b') { $bad += $c; continue }
}
if ($bad.Count -gt 0) { Fail ("Probe block contains non-command/dirty line(s): " + ($bad -join " | ")) }
Ok "Probe block commands-only"

# ----- (C) Run canonical loop (single pass) -----
Ok "Running canonical loop: start -> status-env -> build -> handoff"

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/supabase-ensure.ps1 start
if ($LASTEXITCODE -ne 0) { Fail "supabase-ensure.ps1 start failed (exit $LASTEXITCODE)" }

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/supabase-ensure.ps1 status-env
if ($LASTEXITCODE -ne 0) { Fail "supabase-ensure.ps1 status-env failed (exit $LASTEXITCODE)" }

cmd /c "npm run build"
if ($LASTEXITCODE -ne 0) { Fail "npm run build failed (exit $LASTEXITCODE)" }

cmd /c "npm run handoff"
if ($LASTEXITCODE -ne 0) { Fail "npm run handoff failed (exit $LASTEXITCODE)" }

Ok "Canonical loop ran"

# ----- (D) .env.local exists + basic expected keys -----
if (-not (Test-Path -LiteralPath $envPath)) { Fail ".env.local not written" }
$envText = Get-Content -Raw -LiteralPath $envPath
foreach ($needle in @("NEXT_PUBLIC_SUPABASE_URL=","NEXT_PUBLIC_SUPABASE_ANON_KEY=")) {
  if ($envText -notmatch [regex]::Escape($needle)) { Fail ".env.local missing: $needle" }
}
Ok ".env.local present with expected keys"

# ----- (E) Handoff artifacts written + sections C–G present -----
if (-not (Test-Path -LiteralPath $handoffLatest)) { Fail "docs/handoff_latest.txt not written" }

$snaps = Get-ChildItem -Path $handoffGlob -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if (-not $snaps -or $snaps.Count -lt 1) { Fail "docs/handoff_snapshot_*.txt not found" }

$latestText = Get-Content -Raw -LiteralPath $handoffLatest

foreach ($section in @("## C)","## D)","## E)","## F)","## G)")) {
  if ($latestText -notmatch [regex]::Escape($section)) { Fail "handoff_latest.txt missing section: $section" }
}
Ok "handoff_latest.txt contains sections C–G"

# ----- (F) Redaction rules (fail if secrets appear in snapshot) -----
$secretPatterns = @(
  "sb_secret_",
  "SUPABASE_SERVICE_ROLE_KEY",
  "service_role_key",
  "Secret Key\s*\|\s*[0-9a-f]{32,}",
  "postgresql:\/\/postgres:postgres@"
)

foreach ($p in $secretPatterns) {
  if ($latestText -match $p) { Fail "handoff_latest.txt contains secret pattern: $p" }
}
Ok "handoff_latest.txt appears redacted"

# ----- (G) .gitignore covers generated handoff artifacts -----
if (-not (Test-Path -LiteralPath $gitignorePath)) { Fail "Missing .gitignore" }
$gi = Get-Content -Raw -LiteralPath $gitignorePath

$needIgnores = @(
  "docs/handoff_latest.txt",
  "docs/handoff_snapshot_*.txt"
)
foreach ($ig in $needIgnores) {
  if ($gi -notmatch [regex]::Escape($ig)) { Fail ".gitignore missing ignore: $ig" }
}
Ok ".gitignore ignores handoff artifacts"

Write-Host "HARD_GATE_PASS"
exit 0