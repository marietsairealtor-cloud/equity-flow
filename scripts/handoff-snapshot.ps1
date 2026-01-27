param(
  [int]$Port = 3001
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-LastExitCode {
  if ($null -eq $global:LASTEXITCODE) { return 0 }
  return [int]$global:LASTEXITCODE
}

function Try-GetListener([int]$p) {
  try {
    $c = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop | Select-Object -First 1
    if ($null -ne $c) { return $true }
    return $false
  } catch {
    return $false
  }
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = Join-Path (Get-Location) "docs"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outFile = Join-Path $outDir ("handoff_snapshot_{0}.txt" -f $ts)

$branch = (git rev-parse --abbrev-ref HEAD) 2>$null
$head   = (git rev-parse HEAD) 2>$null
$status = (git status -sb) 2>$null
$log1   = (git log -1 --oneline) 2>$null

$node = (node -v) 2>$null
$npmv = (npm -v) 2>$null

$sbv = ""
try { $sbv = (npx supabase -v) 2>$null } catch { $sbv = "" }

$nextv = ""
try {
  $pj = Get-Content (Join-Path (Get-Location) "package.json") -Raw | ConvertFrom-Json
  if ($pj.dependencies.PSObject.Properties.Match("next").Count) { $nextv = $pj.dependencies.next }
  elseif ($pj.devDependencies.PSObject.Properties.Match("next").Count) { $nextv = $pj.devDependencies.next }
} catch { $nextv = "" }

$dbSet = [bool]$env:DATABASE_URL
$tokSet = [bool]$env:SUPABASE_ACCESS_TOKEN

$hasListener = Try-GetListener $Port

# Build probe
$buildOut = @()
$buildOut += "----- npm run build (begin) -----"
try {
  $p = Start-Process -FilePath (Get-Command npm.cmd -ErrorAction Stop).Source -ArgumentList @("run","build") -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\handoff_build_out.txt" -RedirectStandardError "$env:TEMP\handoff_build_err.txt"
  $o = @()
  if (Test-Path "$env:TEMP\handoff_build_out.txt") { $o += Get-Content "$env:TEMP\handoff_build_out.txt" }
  if (Test-Path "$env:TEMP\handoff_build_err.txt") { $o += Get-Content "$env:TEMP\handoff_build_err.txt" }
  $buildOut += $o
  $buildOut += ("exit code: {0}" -f $p.ExitCode)
} catch {
  $buildOut += ("npm run build failed to execute: {0}" -f $_.Exception.Message)
}
$buildOut += "----- npm run build (end) -----"

$text = @()
$text += ("=== HANDOFF SNAPSHOT ({0}) ===" -f $ts)
$text += ""
$text += "## A) State header"
$text += ("Branch: {0}" -f $branch)
$text += ("HEAD:   {0}" -f $head)
$text += ""
$text += "git status -sb:"
$text += $status
$text += ""
$text += "git log -1 --oneline:"
$text += $log1
$text += ""
$text += "Versions:"
$text += ("node: {0}" -f $node)
$text += ("npm:  {0}" -f $npmv)
$text += ("supabase: {0}" -f $sbv)
$text += ("next: {0}" -f $nextv)
$text += ""
$text += "Env flags present (no secrets printed):"
$text += ("DATABASE_URL set: {0}" -f $dbSet)
$text += ("SUPABASE_ACCESS_TOKEN set: {0}" -f $tokSet)
$text += ""
$text += ("Port {0} usage:" -f $Port)
$text += ("Listener on {0}: {1}" -f $Port, $hasListener)
$text += ""
$text += "## D) Diff summary"
$text += ""
$text += ""
$text += "## C) Build probe (npm run build) - output below"
$text += $buildOut

# Write UTF-8 no BOM
[System.IO.File]::WriteAllText($outFile, ($text -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("Wrote: {0}" -f $outFile)