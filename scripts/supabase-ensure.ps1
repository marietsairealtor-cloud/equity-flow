param(
  [ValidateSet("status","start","stop")]
  [string]$Action = "status",
  [string]$Project = "equity-flow"
)

$ErrorActionPreference = "Continue"

function Remove-StuckSupabaseContainers([string]$Project) {
  $names = @()
  try { $names = docker ps -a --format "{{.Names}}" 2>$null } catch { return }
  if (-not $names) { return }
  $pattern = "^supabase_.*_${Project}$"
  $targets = $names | Where-Object { $_ -match $pattern }
  foreach ($n in $targets) {
    try { docker rm -f $n | Out-Null; Write-Host "Removed stuck container: $n" } catch {}
  }
}

function Ensure-Started([string]$Project) {
  $out = & npx supabase status 2>&1
  $code = $LASTEXITCODE
  $txt = ($out | Out-String)

  if ($code -eq 0 -and $txt -notmatch "No such container" -and $txt -notmatch "failed to inspect container health") {
    $out
    return 0
  }

  $startOut = & npx supabase start 2>&1
  $startTxt = ($startOut | Out-String)

  if ($startTxt -match "already in use" -or $startTxt -match "Conflict\.") {
    Remove-StuckSupabaseContainers -Project $Project
    $startOut = & npx supabase start 2>&1
  }

  $out2 = & npx supabase status 2>&1
  $code2 = $LASTEXITCODE

  $startOut
  $out2
  return $code2
}

switch ($Action) {
  "status" { exit (Ensure-Started -Project $Project) }
  "start"  {
    & npx supabase start | Out-Host
    if ($LASTEXITCODE -ne 0) {
      Remove-StuckSupabaseContainers -Project $Project
      & npx supabase start | Out-Host
    }
    & npx supabase status | Out-Host
    exit $LASTEXITCODE
  }
  "stop"   {
    & npx supabase stop | Out-Host
    Remove-StuckSupabaseContainers -Project $Project
    exit $LASTEXITCODE
  }
}
