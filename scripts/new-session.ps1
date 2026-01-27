param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Utf8NoBom([string]$path, [string]$text) {
  $dir = Split-Path -Parent $path
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

$repo = Get-Location
$docsDir = Join-Path $repo "docs"
$tpl = Join-Path $docsDir "now.template.md"
$now = Join-Path $docsDir "now.md"

if (!(Test-Path $tpl)) { throw "MISSING_TEMPLATE: docs/now.template.md" }

$t = Get-Content $tpl -Raw
Write-Utf8NoBom $now $t

Write-Host ("Reset: {0}" -f $now)