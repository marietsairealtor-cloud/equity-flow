$ErrorActionPreference = "Stop"
docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Error "Docker prerequisite failed. Start Docker Desktop, then rerun."
  exit 1
}