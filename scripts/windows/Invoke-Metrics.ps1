param(
  [string]$Season = "2025-26",
  [int]$StartMD = 1,
  [int]$EndMD = 4,
  [string]$DataDir = "public/data",
  [string]$OutDir = "public/metrics"
)

$ErrorActionPreference = "Stop"
$venv = ".\.venv\Scripts\Activate.ps1"
if (!(Test-Path $venv)) { Write-Error "Venv not found. Run .\scripts\windows\Setup-Venv.ps1 first." }
. $venv

python scripts\make_metrics.py --season $Season --start-md $StartMD --end-md $EndMD --data-dir $DataDir --out-dir $OutDir

Write-Host ("Metrics built for MD{0}-{1} ({2})" -f $StartMD, $EndMD, $Season) -ForegroundColor Green
