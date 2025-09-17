param(
  [ValidateSet("fetch","metrics","both")] [string]$Mode = "both",
  [string]$Season = "2025-26",
  [int]$Matchday = 1,
  [int[]]$MatchdayList = @(),
  [int]$StartMD = 1,
  [int]$EndMD = 4,
  [switch]$AutoRange,
  [switch]$OpenUI,
  [string]$DashboardPath = "public/index.html",
  [switch]$OpenServer,
  [int]$ServerPort = 8080,
  [string]$DataDir = "public/data",
  [string]$OutDir = "public/metrics",
  [switch]$GitPush,
  [string]$CommitMessage = "chore(hafez): update data/metrics via Run-Me"
)

$ErrorActionPreference = "Stop"
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null } catch {}

function Ensure-Venv {
  $py = "python"
  try { & $py --version | Out-Null } catch {
    Write-Host "Python not found. Install: winget install -e --id Python.Python.3.11" -ForegroundColor Yellow
    throw
  }
  if (!(Test-Path ".\.venv")) { & $py -m venv .venv }
  . .\.venv\Scripts\Activate.ps1
  python -m pip install --upgrade pip | Out-Null
  pip install --disable-pip-version-check requests beautifulsoup4 pandas matplotlib numpy | Out-Null
}

function Detect-EndMD { param([string]$Season,[string]$DataDir)
  $pattern = "HAFEZ_LaLiga_{0}_MD*_RB_ALL.json" -f $Season
  $files = Get-ChildItem -Path $DataDir -Filter $pattern -ErrorAction SilentlyContinue
  if (!$files) { return 0 }
  $mds=@(); foreach($f in $files){ if($f.Name -match "_MD(\d+)_RB_ALL\.json$"){ $mds+=[int]$Matches[1] } }
  if($mds.Count -eq 0){ return 0 } else { return ($mds | Measure-Object -Maximum).Maximum }
}

function Invoke-Fetch { param([string]$Season,[int[]]$MDs,[string]$DataDir)
  if($MDs.Count -eq 0){ $MDs=@($Matchday) }
  foreach($md in $MDs){
    Write-Host ("Fetching Actuals for MD{0} ({1}) ..." -f $md,$Season) -ForegroundColor Cyan
    python scripts\fetch_actuals_fbref_understat.py --season $Season --matchday $md --data-dir $DataDir --name-map "mappings/name_maps_la_liga.json"
    Write-Host ("OK: Actuals enriched for MD{0}" -f $md) -ForegroundColor Green
  }
}

function Invoke-Metrics { param([string]$Season,[int]$StartMD,[int]$EndMD,[string]$DataDir,[string]$OutDir,[switch]$AutoRange)
  if($AutoRange){
    $det = Detect-EndMD -Season $Season -DataDir $DataDir
    if($det -gt 0){ $StartMD=1; $EndMD=$det; Write-Host ("Auto range MD{0}-{1}" -f $StartMD,$EndMD) -ForegroundColor Yellow }
  }
  Write-Host ("Building metrics for MD{0}-{1} ({2}) ..." -f $StartMD,$EndMD,$Season) -ForegroundColor Cyan
  python scripts\make_metrics.py --season $Season --start-md $StartMD --end-md $EndMD --data-dir $DataDir --out-dir $OutDir
  Write-Host "OK: Metrics built." -ForegroundColor Green
}

function Try-OpenDashboard { param([string]$DashboardPath,[string]$OutDir,[switch]$OpenServer,[int]$Port)
  if (Test-Path $DashboardPath){ Start-Process $DashboardPath | Out-Null }
  else {
    foreach($c in @("public\index.html","index.html","docs\index.html","src\index.html")){
      if(Test-Path $c){ Start-Process $c | Out-Null; break }
    }
  }
  $metrics = Join-Path $OutDir "index.html"
  if (Test-Path $metrics) { Start-Process $metrics | Out-Null }
  if ($OpenServer){
    Start-Process powershell -ArgumentList "-NoExit","-Command","python -m http.server $Port" | Out-Null
    Start-Process ("http://localhost:{0}/" -f $Port) | Out-Null
  }
}

function Git-AutoPush { param([string]$CommitMessage)
  try { git --version | Out-Null } catch { Write-Host "Git not found; skipping push." -ForegroundColor Yellow; return }
  try {
    git add public/data/*.json
    if (Test-Path "public/metrics") { git add public/metrics/*.* }
    if (Test-Path "public/index.html") { git add public/index.html }
    if (Test-Path "public/assets") { git add public/assets/*.* }
    git commit -m $CommitMessage
    git push
    Write-Host "Changes pushed to remote." -ForegroundColor Green
  } catch { Write-Host "Git commit/push skipped (no changes or remote not set)." -ForegroundColor Yellow }
}

Ensure-Venv

if ($Mode -eq "fetch"){
  if ($MatchdayList.Count -gt 0) { Invoke-Fetch -Season $Season -MDs $MatchdayList -DataDir $DataDir }
  else { Invoke-Fetch -Season $Season -MDs @($Matchday) -DataDir $DataDir }
}
elseif ($Mode -eq "metrics") {
  Invoke-Metrics -Season $Season -StartMD $StartMD -EndMD $EndMD -DataDir $DataDir -OutDir $OutDir -AutoRange:$AutoRange
}
else {
  if ($MatchdayList.Count -gt 0) { Invoke-Fetch -Season $Season -MDs $MatchdayList -DataDir $DataDir }
  else { Invoke-Fetch -Season $Season -MDs @($Matchday) -DataDir $DataDir }
  Invoke-Metrics -Season $Season -StartMD $StartMD -EndMD $EndMD -DataDir $DataDir -OutDir $OutDir -AutoRange:$AutoRange
}

if ($GitPush) { Git-AutoPush -CommitMessage $CommitMessage }
if ($OpenUI) { Try-OpenDashboard -DashboardPath $DashboardPath -OutDir $OutDir -OpenServer:$OpenServer -Port $ServerPort }

Write-Host ("Done. Mode={0} Season={1}" -f $Mode,$Season) -ForegroundColor Green
