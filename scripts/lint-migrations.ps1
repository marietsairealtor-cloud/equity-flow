param(
  [switch]$Fix
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$dir = Join-Path (Get-Location) "supabase/migrations"
if (!(Test-Path $dir)) { Write-Host "OK: no supabase/migrations folder"; exit 0 }

$files = Get-ChildItem -Path $dir -Filter "*.sql" | Sort-Object Name
if ($files.Count -eq 0) { Write-Host "OK: no migrations"; exit 0 }

$allowedStartRegex = '^(?is)(--|/\*|create\b|alter\b|drop\b|do\b|begin\b|set\b|insert\b|update\b|delete\b|with\b|grant\b|revoke\b|select\b|notify\b)'
$fence = [string]::new([char]96, 3) # "```" without embedding it

function Detect-Encoding([byte[]]$b) {
  if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { return "utf16le" }
  if ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { return "utf16be" }
  if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { return "utf8bom" }
  $nul = ($b | Where-Object { $_ -eq 0 } | Measure-Object).Count
  if ($b.Length -gt 0 -and ($nul / $b.Length) -gt 0.05) { return "has_nuls" }
  return "utf8"
}

function Decode-Bytes([byte[]]$b, [string]$kind) {
  switch ($kind) {
    "utf16le" { return [System.Text.Encoding]::Unicode.GetString($b) }
    "utf16be" { return [System.Text.Encoding]::BigEndianUnicode.GetString($b) }
    default   { return [System.Text.Encoding]::UTF8.GetString($b) }
  }
}

$bad = New-Object System.Collections.Generic.List[string]

foreach ($f in $files) {
  $path = $f.FullName
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $kind  = Detect-Encoding $bytes
  $text  = Decode-Bytes $bytes $kind

  # strip BOM char + NULL chars
  $text = $text.Replace(([string][char]0xFEFF), "").Replace(([string][char]0x0000), "")
  $trim = $text.TrimStart()
  # NO_DOLLAR_DOLLAR: PowerShell expands $ and corrupts SQL migrations. Use named tags: as $fn$ ... $fn$;
  # NO_DOLLAR_DOLLAR: PowerShell expands $ and corrupts SQL migrations. Use named tags: as $fn$ ... $fn$;
$problems = New-Object System.Collections.Generic.List[string]

  # Guardrails
  if ($text -match "(?is)pg_notify\s*\(\s*'pgrst'\s*,") { $problems.Add("PGRST_NOTIFY_FORBIDDEN") }
  if ($text -match '\$\$') { $problems.Add("DOLLAR_DOLLAR_FORBIDDEN") }
  if ($kind -in @("utf16le","utf16be","has_nuls")) { $problems.Add("ENCODING_$kind") }
  if ($kind -eq "utf8bom") { $problems.Add("UTF8_BOM") }
  if ($trim.StartsWith($fence)) { $problems.Add("MARKDOWN_FENCE") }
  if ($trim.Length -gt 0 -and ($trim[0] -eq '"' -or $trim[0] -eq ([char]0x201C) -or $trim[0] -eq ([char]0x201D))) { $problems.Add("LEADING_QUOTE") }
  if ($trim.Length -gt 0 -and ($trim -notmatch $allowedStartRegex)) { $problems.Add("LEADING_JUNK") }

  if ($problems.Count -gt 0) {
    if ($Fix) {
      Copy-Item $path "$path.bak_guardrail" -Force

      $t = $trim

      # Remove opening markdown fence line if present
      if ($t.StartsWith($fence)) {
        $nl = $t.IndexOf("`n")
        if ($nl -ge 0) { $t = $t.Substring($nl + 1) } else { $t = "" }
        $t = $t.TrimStart()
      }

      # Strip leading quotes repeatedly
      while ($t.Length -gt 0 -and ($t[0] -eq '"' -or $t[0] -eq ([char]0x201C) -or $t[0] -eq ([char]0x201D))) {
        $t = $t.Substring(1).TrimStart()
      }

      # Re-validate start token after safe fixes
      if ($t.Length -gt 0 -and ($t -notmatch $allowedStartRegex)) {
        $bad.Add("$($f.Name) :: UNFIXABLE_START_TOKEN :: $($problems -join ',')")
        continue
      }

      # Normalize newlines + write UTF-8 no BOM
      $t = $t -replace "`r`n", "`n"
      $t = $t -replace "`r", "`n"
      $t = $t -replace "`n", "`r`n"
      [System.IO.File]::WriteAllText($path, $t, (New-Object System.Text.UTF8Encoding($false)))
      Write-Host "FIXED: $($f.Name) ($($problems -join ','))"
    } else {
      $bad.Add("$($f.Name) :: $($problems -join ',')")
    }
  }
}

if ($bad.Count -gt 0) {
  Write-Host ""
  Write-Host "MIGRATION GUARDRAIL FAILED:"
  $bad | ForEach-Object { Write-Host " - $_" }
  Write-Host ""
  Write-Host "To auto-fix safe issues:"
  Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lint-migrations.ps1 -Fix"
  exit 1
}

Write-Host "OK: migrations clean"
exit 0