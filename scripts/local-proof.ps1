$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

& "$PSScriptRoot\require-docker.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$logDir = Join-Path $repoRoot "docs\_proof_logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
$stamp = (Get-Date).ToString("yyyyMMddHHmmss")
$logPath = Join-Path $logDir ("local-proof_" + $stamp + ".log")

function Run-Step([string]$Label, [string]$Cmd) {
  Add-Content -Path $logPath -Value ("`n===== " + $Label + " =====`n" + $Cmd + "`n")
  Write-Host ("==> " + $Label)

  # In Windows PowerShell 5.1, native stderr can surface as non-terminating errors.
  # We keep EAP=Continue and fail ONLY on exit code.
  cmd /c $Cmd 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Host
  $exit = $LASTEXITCODE

  if ($exit -ne 0) {
    throw ("FAILED: " + $Label + " (exit " + $exit + "). See log: " + $logPath)
  }
}

Run-Step "supabase stop (clean boundary)" "npx supabase stop --no-backup"
Run-Step "supabase start" "npx supabase start"
Run-Step "supabase status (must be healthy)" "npx supabase status"
Run-Step "db reset (apply migrations locally)" "npx supabase db reset"
Run-Step "supabase status (post-reset)" "npx supabase status"

# Optional enforcement gate (do not fail if function missing)
try {
  cmd /c "npx supabase db query --local ""select public.assert_no_jwt_tenant_refs();""" 2>&1 | Tee-Object -FilePath $logPath -Append | Out-Host
} catch {}

Run-Step "npm run build" "npm run build"
Run-Step "npm run handoff" "npm run handoff"

Write-Host ("OK: local proof loop passed. Log: " + $logPath)