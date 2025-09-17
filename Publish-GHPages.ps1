param(
  [string]$Branch="gh-pages",
  [switch]$BuildSite,
  [string]$Season="2025-26"
)
$ErrorActionPreference="Stop"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null

# optional build site
if ($BuildSite) {
  python scripts\build_site.py
}

# ensure git ready
git --version | Out-Null

# create orphan gh-pages if missing
$exists = git branch --all | Select-String "$Branch"
if (-not $exists) {
  git checkout --orphan $Branch
  Remove-Item -Recurse -Force * -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Name .nojekyll | Out-Null
  git add .nojekyll
  git commit -m "init gh-pages" | Out-Null
  git push -u origin $Branch
  git checkout -
}

# switch to gh-pages (detached worktree via tmp)
if (Test-Path site) {
  $tmp = Join-Path $env:TEMP ("hafez_site_" + [guid]::NewGuid().ToString("N"))
  git worktree add $tmp $Branch
  Copy-Item -Path ".\site\*" -Destination $tmp -Recurse -Force
  Push-Location $tmp
  git add .
  git commit -m ("deploy: site for " + $Season) -ErrorAction SilentlyContinue | Out-Null
  git push
  Pop-Location
  git worktree remove $tmp --force
  Write-Host "Published to branch $Branch" -ForegroundColor Green
} else {
  Write-Host "site folder not found. Run with -BuildSite to assemble." -ForegroundColor Yellow
}
