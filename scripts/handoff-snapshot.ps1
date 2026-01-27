param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Avoid mojibake in logs/snapshots
try {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
} catch {}

$repo = Get-Location
$docsDir = Join-Path $repo "docs"
$nowPath = Join-Path $docsDir "now.md"
$outDir  = $docsDir

if (!(Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir | Out-Null }

function Write-Utf8NoBom([string]$path, [string]$text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Die([string]$msg) {
  Write-Error $msg
  exit 1
}

function Get-FirstMatch([string]$text, [string]$pattern) {
  $m = [regex]::Match($text, $pattern, "IgnoreCase,Multiline")
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ""
}

function RequireField([string]$name, [string]$val) {
  if ([string]::IsNullOrWhiteSpace($val)) { Die "NOW_MD_REQUIRED: '$name' is blank. Fill docs/now.md." }
  if ($val -match "(?i)\bTODO\b") { Die "NOW_MD_REQUIRED: '$name' still contains TODO. Fill docs/now.md." }
}

function RunCmd([string]$cmd) {
  $tmp = Join-Path $env:TEMP ("handoff_{0}" -f ([guid]::NewGuid().ToString("N")))
  $outFile = "$tmp.out"
  $errFile = "$tmp.err"

  try {
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList @("/d","/s","/c",$cmd) -NoNewWindow -Wait -PassThru `
      -RedirectStandardOutput $outFile -RedirectStandardError $errFile

    $stdout = if (Test-Path $outFile) { Get-Content $outFile -Raw } else { "" }
    $stderr = if (Test-Path $errFile) { Get-Content $errFile -Raw } else { "" }
    $stdout = if ($null -ne $stdout) { [string]$stdout } else { "" }
$stderr = if ($null -ne $stderr) { [string]$stderr } else { "" }
$s = ($stdout + $stderr).TrimEnd()

    return [pscustomobject]@{
      ExitCode = $p.ExitCode
      Output   = $s
      Cmd      = $cmd
    }
  } finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $outFile, $errFile
  }
}

function Has-Listener3001() {
  try {
    $c = Get-NetTCPConnection -State Listen -LocalPort 3001 -ErrorAction Stop | Select-Object -First 1
    return [bool]$c
  } catch {
    return $false
  }
}

# ---- Require docs/now.md and completed required fields
if (!(Test-Path $nowPath)) {
  Die "NOW_MD_REQUIRED: docs/now.md missing."
}

$nowText = Get-Content $nowPath -Raw

$nowDate  = Get-FirstMatch $nowText '^\s*Date:\s*(.+)\s*$'
$goal     = Get-FirstMatch $nowText '^\s*Goal:\s*(.+)\s*$'
$blocker  = Get-FirstMatch $nowText '^\s*Blocker:\s*(.+)\s*$'
$mode     = Get-FirstMatch $nowText '^\s*Mode:\s*(.+)\s*$'
$nowHost  = Get-FirstMatch $nowText '^\s*Host:\s*(.+)\s*$'

$repro    = Get-FirstMatch $nowText '^\s*Repro:\s*(.+)\s*$'
$expect   = Get-FirstMatch $nowText '^\s*Expected:\s*(.+)\s*$'
$actual   = Get-FirstMatch $nowText '^\s*Actual:\s*(.+)\s*$'
$lastchg  = Get-FirstMatch $nowText '^\s*Last change:\s*(.+)\s*$'
$targetdb = Get-FirstMatch $nowText '^\s*Target DB:\s*(.+)\s*$'
$hypo     = Get-FirstMatch $nowText '^\s*Hypothesis:\s*(.+)\s*$'
$test     = Get-FirstMatch $nowText '^\s*Test:\s*(.+)\s*$'
$patch    = Get-FirstMatch $nowText '^\s*Patch:\s*(.+)\s*$'
$which    = Get-FirstMatch $nowText '^\s*Which file changes:\s*(.+)\s*$'
$probe    = Get-FirstMatch $nowText '^\s*Probe:\s*(.+)\s*$'
$lkgp     = Get-FirstMatch $nowText '^\s*Last known good probe:\s*(.+)\s*$'
$next     = Get-FirstMatch $nowText '^\s*Next step:\s*(.+)\s*$'
$dnttouch = Get-FirstMatch $nowText '^\s*Do not touch list:\s*(.+)\s*$'

RequireField "Date" $nowDate
RequireField "Goal" $goal
RequireField "Blocker" $blocker
RequireField "Mode" $mode
RequireField "Host" $nowHost
RequireField "Repro" $repro
RequireField "Expected" $expect
RequireField "Actual" $actual
RequireField "Last change" $lastchg
RequireField "Target DB" $targetdb
RequireField "Hypothesis" $hypo
RequireField "Test" $test
RequireField "Patch" $patch
RequireField "Which file changes" $which
RequireField "Probe" $probe
RequireField "Last known good probe" $lkgp
RequireField "Next step" $next
RequireField "Do not touch list" $dnttouch

if ($nowHost -ne "http://localhost:3001") { Die "NOW_MD_REQUIRED: Host must be exactly http://localhost:3001" }
if ($mode -notin @("local","remote")) { Die "NOW_MD_REQUIRED: Mode must be 'local' or 'remote'." }

# ---- Gather state (non-fatal command captures)
$branch = (RunCmd "git rev-parse --abbrev-ref HEAD").Output
$head   = (RunCmd "git rev-parse HEAD").Output
$status = (RunCmd "git status -sb").Output
$log1   = (RunCmd "git log -1 --oneline").Output
$diffStat = (RunCmd "git diff --stat").Output

$diffFullObj = RunCmd "git diff"
$diffFull = if ($diffFullObj.Output.Length -le 25000) { $diffFullObj.Output } else { "(git diff too large; see --stat above)" }

$nodeV = (RunCmd "node -v").Output
$npmV  = (RunCmd "npm -v").Output
$sbV   = (RunCmd "npx supabase --version").Output
$nextV = (RunCmd "npx next --version").Output

$dbSet  = [bool]$env:DATABASE_URL
$tokSet = [bool]$env:SUPABASE_ACCESS_TOKEN
$listen = Has-Listener3001

$localDbReady = $false
# ---- Probes (best-effort, never fatal)
$sbStatusObj = RunCmd "npx supabase status"
$sbStatus = "exit code: {0}`r`n{1}" -f $sbStatusObj.ExitCode, $sbStatusObj.Output

$probeObj = RunCmd $probe
$probeOut = "exit code: {0}`r`n{1}" -f $probeObj.ExitCode, $probeObj.Output

# Build can fail if another build holds .next/lock; record output anyway.
$buildObj = RunCmd "npm run build"
$buildOut = "exit code: {0}`r`n{1}" -f $buildObj.ExitCode, $buildObj.Output

# ---- Write snapshot
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$outFile = Join-Path $outDir ("handoff_snapshot_{0}.txt" -f $ts)
$latestPath = Join-Path $outDir "handoff_latest.txt"

$text = ""
$text += "=== HANDOFF SNAPSHOT ($ts) ===`r`n`r`n"
$text += "## A) State header`r`n"
$text += "Branch: $branch`r`n"
$text += "HEAD:   $head`r`n`r`n"
$text += "git status -sb:`r`n$status`r`n`r`n"
$text += "git log -1 --oneline:`r`n$log1`r`n`r`n"
$text += "Versions:`r`n"
$text += "node: $nodeV`r`n"
$text += "npm:  $npmV`r`n"
$text += "supabase: $sbV`r`n"
$text += "next: $nextV`r`n`r`n"
$text += "Env flags present (no secrets printed):`r`n"
$text += "DATABASE_URL set: $dbSet`r`n"
$text += "SUPABASE_ACCESS_TOKEN set: $tokSet`r`n`r`n"
$text += "Supabase local ready: $localDbReady`r`n`r`n"
$text += "Port 3001 usage:`r`n"
$text += "Listener on 3001: $listen`r`n`r`n"

$text += "## B) NOW (docs/now.md)`r`n"
$text += "Date: $nowDate`r`n"
$text += "Goal: $goal`r`n"
$text += "Blocker: $blocker`r`n"
$text += "Mode: $mode`r`n"
$text += "Host: $nowHost`r`n`r`n"
$text += "Repro: $repro`r`n"
$text += "Expected: $expect`r`n"
$text += "Actual: $actual`r`n`r`n"
$text += "Last change: $lastchg`r`n"
$text += "Target DB: $targetdb`r`n`r`n"
$text += "Hypothesis: $hypo`r`n"
$text += "Test: $test`r`n"
$text += "Patch: $patch`r`n"
$text += "Which file changes: $which`r`n"
$text += "Probe: $probe`r`n"
$text += "Last known good probe: $lkgp`r`n"
$text += "Next step: $next`r`n"
$text += "Do not touch list: $dnttouch`r`n`r`n"

$text += "## C) Supabase status (npx supabase status)`r`n"
$text += "----- supabase status (begin) -----`r`n"
$text += "$sbStatus`r`n"
$text += "----- supabase status (end) -----`r`n`r`n"

$text += "## D) Probe run (from NOW.Probe)`r`n"
$text += "----- probe (begin) -----`r`n"
$text += "$probeOut`r`n"
$text += "----- probe (end) -----`r`n`r`n"

$text += "## E) Build probe (npm run build)`r`n"
$text += "----- npm run build (begin) -----`r`n"
$text += "$buildOut`r`n"
$text += "----- npm run build (end) -----`r`n`r`n"

$text += "## F) Diff summary`r`n"
$text += "$diffStat`r`n`r`n"

$text += "## G) Diff full (truncated if too large)`r`n"
$text += "----- git diff (begin) -----`r`n"
$text += "$diffFull`r`n"
$text += "----- git diff (end) -----`r`n"

Write-Utf8NoBom $outFile $text
Write-Utf8NoBom $latestPath $text
try { Set-Clipboard -Value $text } catch {}

Write-Host ("Wrote: {0}" -f $outFile)
Write-Host ("Latest snapshot: {0}" -f $latestPath)