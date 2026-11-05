$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$configText = docker compose config --format json
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Compose config' }
$config = ($configText -join "`n") | ConvertFrom-Json
$failed = $false
foreach ($service in @('jenkins', 'nexus', 'sonarqube')) {
    $port = $config.services.$service.ports[0].published
    $path = switch ($service) { 'jenkins' { '/login' } 'nexus' { '/' } 'sonarqube' { '/api/system/status' } }
    $url = "http://localhost:${port}${path}"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 15
        if ($service -eq 'sonarqube' -and ($response.Content | ConvertFrom-Json).status -ne 'UP') {
            throw 'SonarQube is not UP yet'
        }
        Write-Host "READY: $service - $url"
    } catch { $failed = $true; Write-Host "NOT READY: $service - $url - $($_.Exception.Message)" }
}
if ($failed) { exit 1 }
