$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
docker compose down --remove-orphans
if ($LASTEXITCODE -ne 0) { throw 'Cleanup failed' }
Write-Host 'Lab7 containers removed. Volumes retained; Lab8 is unchanged.'
