param()

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function Fail([string]$msg){ Write-Error $msg; exit 1 }

function Run([string]$cmd){
  $tmp = Join-Path $env:TEMP ("end_{0}" -f ([guid]::NewGuid().ToString("N")))
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

Write-Host "=== end: git status -sb (must be clean) ==="
$st = Run "git status -sb"
Write-Host $st.Output
if($st.ExitCode -ne 0){ Fail "GIT_FAILED: git status -sb`r`n$($st.Output)" }

$lines = ($st.Output -split "`r?`n") | Where-Object { $_.Trim() -ne "" }
$lineCount = @($lines | ForEach-Object { param()

$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest

function Fail([string]$msg){ Write-Error $msg; exit 1 }

function Run([string]$cmd){
  $tmp = Join-Path $env:TEMP ("end_{0}" -f ([guid]::NewGuid().ToString("N")))
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

Write-Host "=== end: git status -sb (must be clean) ==="
$st = Run "git status -sb"
Write-Host $st.Output
if($st.ExitCode -ne 0){ Fail "GIT_FAILED: git status -sb`r`n$($st.Output)" }

$lines = ($st.Output -split "`r?`n") | Where-Object { $_.Trim() -ne "" }
if($lines.Count -gt 1){ Fail "REPO_NOT_CLEAN: commit/push or discard changes before switching chats." }

Write-Host "`n=== end: npm run lint:migrations ==="
$l = Run "npm run lint:migrations"
Write-Host $l.Output
if($l.ExitCode -ne 0){ Fail "LINT_MIGRATIONS_FAILED" }

Write-Host "`n=== end: npm run build ==="
$b = Run "npm run build"
Write-Host $b.Output
if($b.ExitCode -ne 0){ Fail "BUILD_FAILED" }

Write-Host "`nOK: end passed." }).Count
if ($lineCount -gt 1) { Fail "REPO_NOT_CLEAN: commit/push or discard changes before switching chats." }
Write-Host "`n=== end: npm run lint:migrations ==="
$l = Run "npm run lint:migrations"
Write-Host $l.Output
if($l.ExitCode -ne 0){ Fail "LINT_MIGRATIONS_FAILED" }

Write-Host "`n=== end: npm run build ==="
$b = Run "npm run build"
Write-Host $b.Output
if($b.ExitCode -ne 0){ Fail "BUILD_FAILED" }

Write-Host "`nOK: end passed."
