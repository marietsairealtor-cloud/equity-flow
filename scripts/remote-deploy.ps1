$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==============================="
Write-Host "REMOTE DEPLOY (HOSTED SUPABASE)"
Write-Host "==============================="
Write-Host ""

# Show link info (best-effort)
try { cmd /c "npx supabase projects list" } catch {}
try { cmd /c "npx supabase status" } catch {}

$confirm = Read-Host "Type EXACTLY: DEPLOY REMOTE"
if ($confirm -ne "DEPLOY REMOTE") {
  Write-Error "Cancelled."
  exit 1
}

# Require explicit env flag too
if ($env:ALLOW_REMOTE -ne "1") {
  Write-Error "Refused. Set ALLOW_REMOTE=1 for this session, then rerun."
  exit 1
}

cmd /c "npx supabase db push"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "OK: remote deploy finished."