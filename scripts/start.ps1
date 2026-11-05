$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Test-Path '.env')) { Copy-Item .env.example .env }
docker compose config --quiet
if ($LASTEXITCODE -ne 0) { throw 'Invalid Docker Compose config' }
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose startup failed' }
docker compose ps
Write-Host 'Wait for all three web interfaces to start. Run scripts/check.ps1 next.'
