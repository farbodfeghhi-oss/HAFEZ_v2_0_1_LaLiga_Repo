<#
HAFEZ v2.0.1 — Quick Fix Script (ASCII-safe)
- Fix paths in src/pages/index.html for GitHub Pages
- Seed Week JSONs if missing (simple example data)
- Optional: git add/commit/push (if git is installed)

Usage:
  powershell -ExecutionPolicy Bypass -File .\HAFEZ_fix_paths_and_seed_ascii.ps1 -RepoPath "." -Week 5
#>

param(
  [string]$RepoPath = ".",
  [int]$Week = 5
)

function Write-Step([string]$msg){ Write-Host "==> $msg" }
function Write-Info([string]$msg){ Write-Host "    $msg" }
function Write-OK([string]$msg){ Write-Host "OK: $msg" }
function Write-Warn([string]$msg){ Write-Host "WARN: $msg" }
function Write-Err([string]$msg){ Write-Host "ERROR: $msg" }

$ErrorActionPreference = "Stop"
$RepoPath = (Resolve-Path $RepoPath).Path

# 1) Patch index.html paths
$index = Join-Path $RepoPath "src/pages/index.html"
if (!(Test-Path $index)) { Write-Err "index.html not found: $index"; exit 1 }
Write-Step "Patching paths in src/pages/index.html"
$backup = "$index.bak"
Copy-Item $index $backup -Force
$content = Get-Content $index -Raw
# ../../app.js  -> app.js
$content = $content -replace 'src="\.\.(?:/|\.)*/app\.js"', 'src="app.js"'
# ../../public/data/ -> public/data/
$content = $content -replace '(?:\.\.(?:/|\.)*/)+public/data/', 'public/data/'
Set-Content -Path $index -Value $content -Encoding UTF8
Write-OK "index.html patched (backup saved as index.html.bak)"

# 2) Ensure data directory
$dataDir = Join-Path $RepoPath "public/data"
if (!(Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir | Out-Null; Write-OK "Created public/data" }

# 3) Seed week files if missing
function Get-Confidence([double]$pH,[double]$pD,[double]$pA){
  $ln3 = [Math]::Log(3.0)
  $H = 0.0
  foreach($p in @($pH,$pD,$pA)){
    if($p -gt 0){ $H += -$p * [Math]::Log($p) }
  }
  $conf = 1.0 - ($H / $ln3)
  return [Math]::Round($conf, 3)
}

function New-Match([string]$home,[string]$away,[double]$pH,[double]$pD,[double]$pA){
  $conf = Get-Confidence $pH $pD $pA
  $pairs = @(@("H",$pH),@("D",$pD),@("A",$pA))
  $top = $pairs | Sort-Object -Property {[double]$_[1]} -Descending | Select-Object -First 1
  $topPick = if($top[0] -eq "H"){"Home Win"}elseif($top[0] -eq "D"){"Draw"}else{"Away Win"}
  return [ordered]@{
    home_team = $home
    away_team = $away
    date = "2025-09-20"
    stadium = ""
    city = ""
    predictions = @{
      main = @{
        home_win = [Math]::Round($pH,3)
        draw     = [Math]::Round($pD,3)
        away_win = [Math]::Round($pA,3)
        top_pick = $topPick
        confidence = $conf
        risk_score = [Math]::Round(1.0 - $conf,3)
      }
    }
  }
}

$base = ("HAFEZ_LaLiga_Week{0}" -f $Week)
$files = @{
  ALL = Join-Path $dataDir ("{0}_ALL_v2_0_1.json" -f $base)
  C   = Join-Path $dataDir ("{0}_Conservative.json" -f $base)
  B   = Join-Path $dataDir ("{0}_Balanced.json" -f $base)
  R   = Join-Path $dataDir ("{0}_Risky.json" -f $base)
  SL  = Join-Path $dataDir ("{0}_Shortlist.json" -f $base)
  CO  = Join-Path $dataDir ("{0}_Corners.json" -f $base)
}

$fixtures = @(
  @{h="Real Madrid"; a="Valencia";  p=@{H=0.68;D=0.20;A=0.12}},
  @{h="Barcelona";  a="Sevilla";   p=@{H=0.62;D=0.22;A=0.16}}
)

function Ensure-WeekJsons([hashtable]$files,[array]$fixtures,[int]$week){
  if (!(Test-Path $files.ALL)){
    Write-Step "Seeding ALL pack for week $week"
    $C=@();$B=@();$R=@()
    foreach($f in $fixtures){
      $B += (New-Match $f.h $f.a $f.p.H $f.p.D $f.p.A)
      $C += (New-Match $f.h $f.a ([Math]::Max(0.01,$f.p.H-0.05)) ([Math]::Min(0.98,$f.p.D+0.03)) ([Math]::Max(0.01,$f.p.A-0.02)))
      $R += (New-Match $f.h $f.a ([Math]::Min(0.98,$f.p.H+0.04)) ([Math]::Max(0.01,$f.p.D-0.03)) ([Math]::Min(0.98,$f.p.A+0.02)))
    }
    $obj=[ordered]@{
      version="2.0.1"; league="La Liga"; week=$week
      goals=@{ Conservative=$C; Balanced=$B; Risky=$R }
      corners=@{ matches=@( foreach($f in $fixtures){ @{home_team=$f.h; away_team=$f.a; corners=@{ total_expected=9.8 } } ) }
    }
    $obj | ConvertTo-Json -Depth 8 | Set-Content -Path $files.ALL -Encoding UTF8
    Write-OK "Created $($files.ALL)"
  } else { Write-Info "ALL exists: $($files.ALL)" }

  foreach($mode in @("C","B","R")){
    $path=$files[$mode]
    if (!(Test-Path $path)){
      $arr = (Get-Content $files.ALL -Raw | ConvertFrom-Json).goals.(@{C="Conservative";B="Balanced";R="Risky"}[$mode])
      $sub=[ordered]@{ version="2.0.1"; league="La Liga"; week=$week; mode=@{C="Conservative";B="Balanced";R="Risky"}[$mode]; matches=$arr }
      $sub | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding UTF8
      Write-OK "Created $path"
    } else { Write-Info "$mode exists: $path" }
  }

  if (!(Test-Path $files.SL)){
    $B = (Get-Content $files.B -Raw | ConvertFrom-Json).matches
    $sl=[ordered]@{
      version="2.0.1"; league="La Liga"; week=$week
      shortlist=@{
        high_confidence=@(@{ Match="$($B[0].home_team) vs $($B[0].away_team)"; TopPick=$B[0].predictions.main.top_pick; Confidence=$B[0].predictions.main.confidence })
        medium_confidence=@(@{ Match="$($B[1].home_team) vs $($B[1].away_team)"; TopPick=$B[1].predictions.main.top_pick; Confidence=$B[1].predictions.main.confidence })
        low_confidence=@()
      }
      upset_candidates=@()
    }
    $sl | ConvertTo-Json -Depth 8 | Set-Content -Path $files.SL -Encoding UTF8
    Write-OK "Created $($files.SL)"
  } else { Write-Info "Shortlist exists: $($files.SL)" }

  if (!(Test-Path $files.CO)){
    $corners=[ordered]@{ version="2.0.1"; league="La Liga"; week=$week; corners=(Get-Content $files.ALL -Raw | ConvertFrom-Json).corners }
    $corners | ConvertTo-Json -Depth 8 | Set-Content -Path $files.CO -Encoding UTF8
    Write-OK "Created $($files.CO)"
  } else { Write-Info "Corners exists: $($files.CO)" }
}

Ensure-WeekJsons -files $files -fixtures $fixtures -week $Week

# 4) Git commit & push (optional)
function Git-Available { & git --version *> $null; return ($LASTEXITCODE -eq 0) }
if (Git-Available) {
  Write-Step "git add / commit / push"
  Push-Location $RepoPath
  & git add -A
  & git commit -m ("Fix: paths for Pages + seed week {0}" -f $Week) 2>$null
  & git push origin main
  Pop-Location
  Write-OK "Pushed to origin/main"
} else {
  Write-Warn "git not found. Use GitHub Desktop to Commit and Push."
}

Write-OK "Done. Reload your site after 30-90 seconds."
