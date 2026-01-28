param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("stop","start","status","reset")]
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
  # stderr-safe: never treat docker "Skipped..." or "Stopped services..." as fatal
  $old = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    Write-Host ("----- {0} (begin) -----" -f $Label)
    $out = & $Args[0] $Args[1..($Args.Length-1)] 2>&1
    $code = $LASTEXITCODE
    if ($out) { $out | ForEach-Object { "$_" } | Out-Host }
    Write-Host ("----- {0} (end) exit={1} -----" -f $Label, $code)
    return @{ Code = $code; Out = ($out | Out-String) }
  } finally {
    $ErrorActionPreference = $old
  }
}

function Cleanup-ProjectContainers([string]$proj) {
  # Deterministic by name pattern (project-suffixed containers)
  $pattern = "^/supabase_.*_$([Regex]::Escape($proj))$"
  $names = & docker ps -a --format "{{.Names}}" 2>$null
  if (!$names) { return }

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
  # Example: container "e730...". You have to remove...
  $m = [Regex]::Match($text, 'container\s+"([0-9a-f]{12,64})"', 'IgnoreCase')
  if ($m.Success) { return $m.Groups[1].Value }
  return $null
}

$root = RepoRoot
Set-Location $root
$proj = Split-Path $root -Leaf  # e.g. equity-flow

if ($Action -eq "stop") {
  Run @("npx","supabase","stop","--no-backup") "supabase stop --no-backup" | Out-Null
  exit 0
}

if ($Action -eq "start") {
  # Always stop first to avoid "already running" + stale containers
  Run @("npx","supabase","stop","--no-backup") "supabase stop --no-backup" | Out-Null

  # Cleanup known leftover containers (including supabase_vector_<proj>)
  Cleanup-ProjectContainers $proj

  $r = Run @("npx","supabase","start") "supabase start"
  if ($r.Code -ne 0) {
    # If conflict persists, remove specific conflicting container id then retry once
    $cid = Parse-ConflictContainerId $r.Out
    if ($cid) {
      Write-Host ("Conflict container detected; removing id={0}" -f $cid)
      Run @("docker","rm","-f",$cid) "docker rm -f (conflict id)" | Out-Null
      $r = Run @("npx","supabase","start") "supabase start (retry)"
    }
  }
  if ($r.Code -ne 0) { exit $r.Code }
  exit 0
}

if ($Action -eq "status") {
  # Raw status; callers decide parsing. "Stopped services" is non-fatal.
  $r = Run @("npx","supabase","status") "supabase status (raw)"
  exit $r.Code
}

if ($Action -eq "reset") {
  Run @("npx","supabase","db","reset") "supabase db reset" | Out-Null
  exit $LASTEXITCODE
}