$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$dir = Join-Path (Get-Location) "supabase/migrations"
if (!(Test-Path $dir)) { throw "Missing folder: $dir" }

$files = Get-ChildItem -Path $dir -Filter "*.sql" | Sort-Object Name
if ($files.Count -eq 0) { Write-Host "No migrations found"; exit 0 }

# First valid SQL token we accept as "real start"
$tokenRegex = '(?is)(--|/\*|\bcreate\b|\balter\b|\bdrop\b|\bdo\b|\bbegin\b|\bset\b|\binsert\b|\bupdate\b|\bdelete\b|\bwith\b|\bgrant\b|\brevoke\b|\bselect\b|\bnotify\b)'

function Detect-Encoding([byte[]]$b) {
  if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { return "utf16le" }
  if ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { return "utf16be" }
  if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { return "utf8bom" }
  # heuristic: lots of NUL bytes => UTF-16-ish
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

$changed = @()
$skipped = @()

foreach ($f in $files) {
  $path = $f.FullName
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $kind  = Detect-Encoding $bytes
  $text  = Decode-Bytes $bytes $kind

  # strip BOM char + NUL chars (string-level)
  $text = $text.Replace(([string][char]0xFEFF), "").Replace(([string][char]0x0000), "")

  # remove other control chars except tab/newline/carriage return
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $text.ToCharArray()) {
    $code = [int]$ch
    if ($code -eq 9 -or $code -eq 10 -or $code -eq 13 -or $code -ge 32) { [void]$sb.Append($ch) }
  }
  $clean = $sb.ToString()

  # Find first real SQL token anywhere in file (not just start)
  $m = [regex]::Match($clean, $tokenRegex)
  if (-not $m.Success) {
    $skipped += "$($f.Name) :: NO_SQL_TOKEN_FOUND"
    continue
  }

  $start = $m.Index
  $out = $clean.Substring($start).TrimStart()

  # If file begins with markdown fence, drop the opening fence line
  $fence = [string]::new([char]96, 3)
  if ($out.StartsWith($fence)) {
    $nl = $out.IndexOf("`n")
    if ($nl -ge 0) { $out = $out.Substring($nl + 1).TrimStart() }
  }

  # Normalize newlines to CRLF for Windows, but keep content stable
  $out = $out -replace "`r`n", "`n"
  $out = $out -replace "`r", "`n"
  $out = $out -replace "`n", "`r`n"

  # Write UTF-8 no BOM, keep backup
  Copy-Item $path "$path.bak_hard" -Force
  [System.IO.File]::WriteAllText($path, $out, (New-Object System.Text.UTF8Encoding($false)))

  $changed += "$($f.Name) :: repaired_from_$kind"
}

if ($changed.Count -gt 0) {
  Write-Host "HARD REPAIRED:"
  $changed | ForEach-Object { Write-Host " - $_" }
} else {
  Write-Host "No files changed."
}

if ($skipped.Count -gt 0) {
  Write-Host ""
  Write-Host "SKIPPED:"
  $skipped | ForEach-Object { Write-Host " - $_" }
}