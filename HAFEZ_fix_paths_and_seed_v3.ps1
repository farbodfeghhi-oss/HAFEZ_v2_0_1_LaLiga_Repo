<#
HAFEZ v2.0.1 — Quick Fix Script (v3, ASCII-safe, no $home collision)
- Patch paths in src/pages/index.html for GitHub Pages
- Seed Week JSONs if missing (valid minimal examples)
- Optional: git add/commit/push (if git is installed)

Usage:
  powershell -ExecutionPolicy Bypass -File .\HAFEZ_fix_paths_and_seed_v3.ps1 -RepoPath "." -Week 5
#>

param(
  [string]$RepoPath = ".",
  [int]$Week = 5
)

$ErrorActionPreference = "Stop"

function Log([string]$m){ Write-Host "==> $m" }
function Ok([string]$m){ Write-Host "OK: $m" }
function Warn([string]$m){ Write-Host "WARN: $m" }
function Err([string]$m){ Write-Host "ERROR: $m" }

# Normalize repo path
$RepoPath = (Resolve-Path $RepoPath).Path

# 1) Patch index.html paths
$index = Join-Path $RepoPath "src/pages/index.html"
if (!(Test-Path $index)) { Err "index.html not found: $index"; exit 1 }
Log "Patching paths inside src/pages/index.html"
Copy-Item $index "$index.bak" -Force
$content = Get-Content $index -Raw

# Replace ../../app.js or ../app.js to app.js
$content = $content -replace 'src="(\.\./)+app\.js"', 'src="app.js"'
# Replace ../../public/data/ or ../public/data/ to public/data/
$content = $content -replace '(\.\./)+public/data/', 'public/data/'

Set-Content -Path $index -Value $content -Encoding UTF8
Ok "index.html patched (backup: index.html.bak)"

# 2) Ensure public/data exists
$dataDir = Join-Path $RepoPath "public/data"
if (!(Test-Path $dataDir)) {
  New-Item -ItemType Directory -Path $dataDir | Out-Null
  Ok "Created public/data"
}

# Helpers
function Confidence([double]$pH,[double]$pD,[double]$pA){
  $ln3 = [Math]::Log(3.0)
  $H = 0.0
  foreach($p in @($pH,$pD,$pA)){
    if($p -gt 0){ $H += -$p * [Math]::Log($p) }
  }
  $c = 1.0 - ($H / $ln3)
  return [Math]::Round($c, 3)
}

function New-Match([string]$homeTeam,[string]$awayTeam,[double]$pH,[double]$pD,[double]$pA){
  $c = Confidence $pH $pD $pA
  $pairs = @(@("H",$pH),@("D",$pD),@("A",$pA))
  $top = $pairs | Sort-Object -Property {[double]$_[1]} -Descending | Select-Object -First 1
  $tp = if($top[0] -eq "H"){"Home Win"} elseif($top[0] -eq "D"){"Draw"} else {"Away Win"}
  $m = [ordered]@{
    home_team = $homeTeam
    away_team = $awayTeam
    date = "2025-09-20"
    stadium = ""
    city = ""
    predictions = @{
      main = @{
        home_win = [Math]::Round($pH,3)
        draw     = [Math]::Round($pD,3)
        away_win = [Math]::Round($pA,3)
        top_pick = $tp
        confidence = $c
        risk_score = [Math]::Round(1.0 - $c,3)
      }
    }
  }
  return $m
}

# Simple fixtures (replace with real ones later if needed)
$fixtures = @(
  @{h="Real Madrid"; a="Valencia";  p=@{H=0.68;D=0.20;A=0.12}},
  @{h="Barcelona";  a="Sevilla";   p=@{H=0.62;D=0.22;A=0.16}}
)

# Build B, C, R arrays
$B = @(); $C = @(); $R = @()
foreach($f in $fixtures){
  $B += (New-Match $f.h $f.a $f.p.H $f.p.D $f.p.A)
  $C += (New-Match $f.h $f.a ([Math]::Max(0.01,$f.p.H-0.05)) ([Math]::Min(0.98,$f.p.D+0.03)) ([Math]::Max(0.01,$f.p.A-0.02)))
  $R += (New-Match $f.h $f.a ([Math]::Min(0.98,$f.p.H+0.04)) ([Math]::Max(0.01,$f.p.D-0.03)) ([Math]::Min(0.98,$f.p.A+0.02)))
}

# Build corners list separately (avoid nested inline foreach)
$cornMatches = @()
foreach($f in $fixtures){
  $cornMatches += @{
    home_team = $f.h
    away_team = $f.a
    corners   = @{ total_expected = 9.8 }
  }
}

# Target file names
$base = ("HAFEZ_LaLiga_Week{0}" -f $Week)
$ALL = Join-Path $dataDir ("{0}_ALL_v2_0_1.json" -f $base)
$Cj  = Join-Path $dataDir ("{0}_Conservative.json" -f $base)
$Bj  = Join-Path $dataDir ("{0}_Balanced.json" -f $base)
$Rj  = Join-Path $dataDir ("{0}_Risky.json" -f $base)
$SL  = Join-Path $dataDir ("{0}_Shortlist.json" -f $base)
$CO  = Join-Path $dataDir ("{0}_Corners.json" -f $base)

# Write ALL if missing
if (!(Test-Path $ALL)){
  Log "Creating ALL pack for week $Week"
  $obj = [ordered]@{
    version = "2.0.1"
    league  = "La Liga"
    week    = $Week
    goals   = @{
      Conservative = $C
      Balanced     = $B
      Risky        = $R
    }
    corners = @{
      matches = $cornMatches
    }
  }
  $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $ALL -Encoding UTF8
  Ok "Created $ALL"
}

# Write mode files if missing
if (!(Test-Path $Cj)){
  $sub = [ordered]@{ version="2.0.1"; league="La Liga"; week=$Week; mode="Conservative"; matches=$C }
  $sub | ConvertTo-Json -Depth 10 | Set-Content -Path $Cj -Encoding UTF8
  Ok "Created $Cj"
}
if (!(Test-Path $Bj)){
  $sub = [ordered]@{ version="2.0.1"; league="La Liga"; week=$Week; mode="Balanced"; matches=$B }
  $sub | ConvertTo-Json -Depth 10 | Set-Content -Path $Bj -Encoding UTF8
  Ok "Created $Bj"
}
if (!(Test-Path $Rj)){
  $sub = [ordered]@{ version="2.0.1"; league="La Liga"; week=$Week; mode="Risky"; matches=$R }
  $sub | ConvertTo-Json -Depth 10 | Set-Content -Path $Rj -Encoding UTF8
  Ok "Created $Rj"
}

# Shortlist
if (!(Test-Path $SL)){
  $sl = [ordered]@{
    version = "2.0.1"
    league  = "La Liga"
    week    = $Week
    shortlist = @{
      high_confidence   = @(@{ Match = "$($B[0].home_team) vs $($B[0].away_team)"; TopPick = $B[0].predictions.main.top_pick; Confidence = $B[0].predictions.main.confidence })
      medium_confidence = @(@{ Match = "$($B[1].home_team) vs $($B[1].away_team)"; TopPick = $B[1].predictions.main.top_pick; Confidence = $B[1].predictions.main.confidence })
      low_confidence    = @()
    }
    upset_candidates = @()
  }
  $sl | ConvertTo-Json -Depth 10 | Set-Content -Path $SL -Encoding UTF8
  Ok "Created $SL"
}

# Corners-only
if (!(Test-Path $CO)){
  $allObj = Get-Content $ALL -Raw | ConvertFrom-Json
  $corn = [ordered]@{ version="2.0.1"; league="La Liga"; week=$Week; corners=$allObj.corners }
  $corn | ConvertTo-Json -Depth 10 | Set-Content -Path $CO -Encoding UTF8
  Ok "Created $CO"
}

# 4) Git add/commit/push if available
$gitOk = $true
try { & git --version *> $null } catch { $gitOk = $false }
if ($gitOk){
  Log "git add/commit/push"
  Push-Location $RepoPath
  & git add -A
  & git commit -m ("Fix paths + seed week {0}" -f $Week) 2>$null
  & git push origin main
  Pop-Location
  Ok "Pushed to origin/main"
} else {
  Warn "git not found. Use GitHub Desktop to Commit and Push."
}

Ok "Done. Reload your GitHub Pages site after 30-90 seconds."
