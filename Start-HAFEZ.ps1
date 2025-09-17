param(
  [string]$Season="2025-26", [int]$Matchday=5, [switch]$Server, [switch]$OpenUI
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force | Out-Null
Unblock-File .\Run-Me-Plus.ps1
# Build metrics over available RB weeks automatically and open UI
.\Run-Me-Plus.ps1 -Mode metrics -Season $Season -AutoRange -OpenUI:$OpenUI -DashboardPath "public\index.html" -OpenServer:$Server
