$ErrorActionPreference = "Stop"
Write-Error "Do not run db push directly. Use: npm run local:proof (local) or ALLOW_REMOTE=1 + npm run remote:deploy (remote)."
exit 1