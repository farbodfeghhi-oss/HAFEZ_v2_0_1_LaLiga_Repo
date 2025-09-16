@echo off
where node >nul 2>&1
if %errorlevel% neq 0 (
  echo Node.js nicht gefunden. Bitte zuerst LTS von https://nodejs.org/ installieren.
  pause
  exit /b 1
)
npx http-server ./ -p 8080
echo.
echo Oeffne im Browser: http://localhost:8080/src/pages/index.html
pause
