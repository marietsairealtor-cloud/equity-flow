param(
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$Content
)
$dir = Split-Path -Parent $Path
if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
[System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
