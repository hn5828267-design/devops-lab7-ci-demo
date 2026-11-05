$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$sourcePath = (Resolve-Path '.\sample-java-app').Path
docker run --rm --mount "type=bind,source=$sourcePath,target=/workspace" --mount "type=volume,source=lab7-maven-cache,target=/root/.m2" -w /workspace maven:3.9.9-eclipse-temurin-21 mvn -B -ntp clean verify
if ($LASTEXITCODE -ne 0) { throw 'Maven verification failed' }
