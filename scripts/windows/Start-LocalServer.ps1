param([int]$Port=8080,[string]$Directory="public")
$ErrorActionPreference="Stop"
try{ Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null }catch{}
if(!(Test-Path $Directory)){ Write-Host "Directory not found: $Directory" -ForegroundColor Red; exit 1 }
Push-Location $Directory
python -m http.server $Port
Pop-Location
