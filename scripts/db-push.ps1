param(
  [switch]$Remote,
  [switch]$Local,
  [switch]$DryRun,
  [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Die([string]$msg) {
  Write-Error $msg
  exit 1
}

function Main {
  param(
    [switch]$Remote,
    [switch]$Local,
    [switch]$DryRun
  )

  $mode = $null
  if ($Remote -and $Local) { Die "Choose exactly one: -Remote OR -Local" }
  if ($Remote) { $mode = "remote" }
  if ($Local)  { $mode = "local" }

  $hasAccessToken = [bool]$env:SUPABASE_ACCESS_TOKEN

  if (-not $mode) {
    Die "MODE_REQUIRED: run `npm run db:push:remote` or `npm run db:push:local` (no default)."
  }

  if ($mode -eq "remote" -and -not $hasAccessToken) {
    Die "REMOTE_REQUIRES_SUPABASE_ACCESS_TOKEN: set `$env:SUPABASE_ACCESS_TOKEN = 'sbp_...' before remote pushes."
  }

  if ($DryRun) {
    Write-Host "DRYRUN: npx supabase db push ($mode)"
    exit 0
  }

  Write-Host "Running: npx supabase db push ($mode)"
  npx supabase db push
}

function SelfTest {
  Write-Host "`nPROVE: ambiguous call must fail"
  & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
  if ($LASTEXITCODE -eq 0) { throw "Guardrail did NOT fail under ambiguity." }
  Write-Host "Expected failure captured (exit code $LASTEXITCODE)."

  Write-Host "`nPROVE: explicit local dryrun should pass"
  & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Local -DryRun
  if ($LASTEXITCODE -ne 0) { throw "Local dryrun should have passed (exit code $LASTEXITCODE)." }

  Write-Host "`nPROVE: explicit remote dryrun should fail if token missing"
  Remove-Item Env:SUPABASE_ACCESS_TOKEN -ErrorAction SilentlyContinue
  & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Remote -DryRun
  if ($LASTEXITCODE -eq 0) { throw "Remote without token should have failed." }
  Write-Host "Expected failure captured (exit code $LASTEXITCODE)."

  Write-Host "`nGuardrail proven."
  exit 0
}

if ($SelfTest) { SelfTest }

Main -Remote:$Remote -Local:$Local -DryRun:$DryRun