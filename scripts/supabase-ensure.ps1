param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("stop","start","status","status-env","reset")]
  [string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function RepoRoot {
  $d = (Get-Location).Path
  while ($true) {
    if (Test-Path (Join-Path $d ".git")) { return $d }
    $p = Split-Path $d -Parent
    if ($p -eq $d) { throw "Repo root not found" }
    $d = $p
  }
}

function Run([string[]]$Args, [string]$Label) {
  if ($null -eq $Args -or $Args.Length -lt 1) { throw "Run(): missing command args for '$Label'" }

  $old = $ErrorActionPreference
  $ErrorActionPreference = "Continue"  # don't die on stderr noise
  try {
    Write-Host ("----- {0} (begin) -----" -f $Label)

    $cmd  = $Args[0]
    $rest = @()
    if ($Args.Length -gt 1) { $rest = $Args[1..($Args.Length-1)] }

    $out  = & $cmd @rest 2>&1
    $code = $LASTEXITCODE

    if ($out) { $out | ForEach-Object { "$_" } | Out-Host }
    Write-Host ("----- {0} (end) exit={1} -----" -f $Label, $code)

    return @{ Code = $code; Out = ($out | Out-String) }
  } finally {
    $ErrorActionPreference = $old
  }
}

function Cleanup-ProjectContainers([string]$proj) {
  $names = & docker ps -a --format "{{.Names}}" 2>$null
  if (!$names) { return }

  $pattern = "^supabase_.*_$([Regex]::Escape($proj))$"
  $targets = @($names | Where-Object { $_ -match $pattern } | Sort-Object -Unique)

  if ($targets.Count -gt 0) {
    Write-Host "Removing leftover containers for project '$proj':"
    $targets | ForEach-Object { Write-Host ("  {0}" -f $_) }
    foreach ($n in $targets) {
      & docker rm -f $n 2>&1 | Out-Host
    }
  }
}

function Parse-ConflictContainerId([string]$text) {
  $m = [Regex]::Match($text, 'container\s+"([0-9a-f]{12,64})"', 'IgnoreCase')
  if ($m.Success) { return $m.Groups[1].Value }
  return $null
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Has-Utf8Bom([string]$Path) {
  if (!(Test-Path $Path)) { return $false }
  $b = [System.IO.File]::ReadAllBytes($Path)
  return ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
}

function Redact-Keys([string]$s) {
  if ($null -eq $s) { return "" }
  $s = [Regex]::Replace($s, '(sb_publishable_)[A-Za-z0-9_\-]+', '${1}REDACTED')
  $s = [Regex]::Replace($s, '(sb_secret_)[A-Za-z0-9_\-]+', '${1}REDACTED')
  return $s
}

function Extract-StatusValues([string]$raw) {
  $projectUrl = ([regex]::Match($raw, '(http://127\.0\.0\.1:54321)\b')).Groups[1].Value
  $dbUrl      = ([regex]::Match($raw, '(postgresql://[^\s]+)')).Groups[1].Value
  $anonKey    = ([regex]::Match($raw, '(sb_publishable_[A-Za-z0-9_\-]+)')).Groups[1].Value
  $secretKey  = ([regex]::Match($raw, '(sb_secret_[A-Za-z0-9_\-]+)')).Groups[1].Value
  return @{
    projectUrl = $projectUrl
    dbUrl      = $dbUrl
    anonKey    = $anonKey
    secretKey  = $secretKey
  }
}

$root = RepoRoot
Set-Location $root
$proj = Split-Path $root -Leaf

if ($Action -eq "stop") {
  Run @("npx","supabase","stop","--no-backup") "supabase stop --no-backup" | Out-Null
  exit 0
}

if ($Action -eq "start") {
  Run @("npx","supabase","stop","--no-backup") "supabase stop --no-backup" | Out-Null
  Cleanup-ProjectContainers $proj

  $r = Run @("npx","supabase","start") "supabase start"
  if ($r.Code -ne 0) {
    $cid = Parse-ConflictContainerId $r.Out
    if ($cid) {
      Run @("docker","rm","-f",$cid) "docker rm -f (conflict id)" | Out-Null
      Cleanup-ProjectContainers $proj
      $r = Run @("npx","supabase","start") "supabase start (retry)"
    }
  }
  exit $r.Code
}

if ($Action -eq "status") {
  $r = Run @("npx","supabase","status") "supabase status (raw)"
  exit $r.Code
}

if ($Action -eq "status-env") {
  $r = Run @("npx","supabase","status") "supabase status (raw)"
  if ($r.Code -ne 0) { exit $r.Code }

  $vals = Extract-StatusValues $r.Out
  if ([string]::IsNullOrWhiteSpace($vals.projectUrl) -or
      [string]::IsNullOrWhiteSpace($vals.dbUrl) -or
      [string]::IsNullOrWhiteSpace($vals.anonKey) -or
      [string]::IsNullOrWhiteSpace($vals.secretKey)) {
    Write-Host (Redact-Keys $r.Out)
    throw "status-env: could not extract Project URL / DB URL / keys from supabase status output."
  }

  $envPath = Join-Path $root ".env.local"
  $env = @"
# Auto-generated from: npx supabase status
# UTF-8 no BOM
NEXT_PUBLIC_SUPABASE_URL=$($vals.projectUrl)
NEXT_PUBLIC_SUPABASE_ANON_KEY=$($vals.anonKey)
SUPABASE_SERVICE_ROLE_KEY=$($vals.secretKey)
DATABASE_URL=$($vals.dbUrl)
"@
  Write-Utf8NoBom $envPath $env
  if (Has-Utf8Bom $envPath) { throw ".env.local has a UTF-8 BOM (not allowed)." }

  Write-Host (Redact-Keys $r.Out)
  exit 0
}

if ($Action -eq "reset") {
  $r = Run @("npx","supabase","db","reset") "supabase db reset"
  exit $r.Code
}