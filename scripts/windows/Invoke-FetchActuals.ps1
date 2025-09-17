param(
  [string]$Season = "2025-26",
  [int]$Matchday = 1,
  [string]$DataDir = "public/data"
)

$ErrorActionPreference = "Stop"
$venv = ".\.venv\Scripts\Activate.ps1"
if (!(Test-Path $venv)) { Write-Error "Venv not found. Run .\scripts\windows\Setup-Venv.ps1 first." }
. $venv

python scripts\fetch_actuals_fbref_understat.py --season $Season --matchday $Matchday --data-dir $DataDir --name-map "mappings/name_maps_la_liga.json"

Write-Host ("Actuals enriched for MD{0} ({1})" -f $Matchday, $Season) -ForegroundColor Green
