
param([int]$Port=8080,[string]$Directory="public\metrics")
Write-Host "Starting local server on http://localhost:$Port/  (Ctrl+C to stop)"
python -m http.server $Port --directory $Directory
