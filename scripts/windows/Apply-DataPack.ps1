
param([Parameter(Mandatory=$true)][string]$ZipPath,[Parameter(Mandatory=$true)][string]$RepoPath)
$ErrorActionPreference = "Stop"
if (!(Test-Path $ZipPath)) { Write-Error "Zip not found: $ZipPath" }
if (!(Test-Path $RepoPath)) { Write-Error "Repo path not found: $RepoPath" }
$dest = Join-Path $RepoPath "public\data"
if (!(Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\HAFEZ_TEMP" -Force
Get-ChildItem "$env:TEMP\HAFEZ_TEMP" -Filter *.json | Copy-Item -Destination $dest -Force
try {
  Push-Location $RepoPath
  git add public/data/*.json
  git commit -m "chore(data): apply HAFEZ data pack"
  git push
  Pop-Location
  Write-Host "✅ Applied and pushed." -ForegroundColor Green
} catch {
  Write-Host "⚠️ Git not found or push failed. Files were copied to public/data." -ForegroundColor Yellow
}
