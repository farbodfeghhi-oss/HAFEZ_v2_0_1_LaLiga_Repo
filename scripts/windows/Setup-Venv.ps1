param()

$ErrorActionPreference = "Stop"

$py = "python"
try { & $py --version | Out-Null } catch {
  Write-Host "Python not found. Install: winget install -e --id Python.Python.3.11" -ForegroundColor Yellow
  exit 1
}

if (!(Test-Path ".\.venv")) { & $py -m venv .venv }

. .\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
pip install requests beautifulsoup4 pandas matplotlib numpy

Write-Host "Virtual environment ready." -ForegroundColor Green
