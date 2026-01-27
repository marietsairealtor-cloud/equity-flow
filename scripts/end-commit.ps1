param()

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function Fail([string]$msg){ Write-Error $msg; exit 1 }

function Run([string]$cmd){
  $tmp = Join-Path $env:TEMP ("endc_{0}" -f ([guid]::NewGuid().ToString("N")))
  $outFile = "$tmp.out"; $errFile = "$tmp.err"
  try{
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList @("/d","/s","/c",$cmd) -NoNewWindow -Wait -PassThru `
      -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $stdout = if(Test-Path $outFile){ Get-Content $outFile -Raw } else { "" }
    $stderr = if(Test-Path $errFile){ Get-Content $errFile -Raw } else { "" }
    return [pscustomobject]@{ ExitCode=$p.ExitCode; Output=(($stdout+$stderr).TrimEnd()); Cmd=$cmd }
  } finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $outFile,$errFile
  }
}

function NowGoal(){
  $p = Join-Path (Join-Path (Get-Location) "docs") "now.md"
  if(!(Test-Path $p)){ return "" }
  $t = Get-Content $p -Raw
  $m = [regex]::Match($t,'^\s*Goal:\s*(.+)\s*$','IgnoreCase,Multiline')
  if($m.Success){ return $m.Groups[1].Value.Trim() }
  return ""
}

Write-Host "=== end:commit: npm run lint:migrations ==="
$l = Run "npm run lint:migrations"
Write-Host $l.Output
if($l.ExitCode -ne 0){ Fail "LINT_MIGRATIONS_FAILED" }

Write-Host "`n=== end:commit: npm run build ==="
$b = Run "npm run build"
Write-Host $b.Output
if($b.ExitCode -ne 0){ Fail "BUILD_FAILED" }

Write-Host "`n=== end:commit: commit + push ==="
$goal = NowGoal
$ts = Get-Date -Format "yyyy-MM-dd HH:mm"
$msg = if($goal){ "checkpoint: $goal ($ts)" } else { "checkpoint ($ts)" }

$r = Run "git add -A"
if($r.ExitCode -ne 0){ Fail "GIT_ADD_FAILED`r`n$($r.Output)" }

$c = Run ("git commit -m " + '"' + ($msg -replace '"','') + '"')
Write-Host $c.Output
if($c.ExitCode -ne 0 -and $c.Output -notmatch "nothing to commit"){ Fail "GIT_COMMIT_FAILED`r`n$($c.Output)" }

$p = Run "git push"
Write-Host $p.Output
if($p.ExitCode -ne 0){ Fail "GIT_PUSH_FAILED`r`n$($p.Output)" }

Write-Host "`nOK: end:commit passed."