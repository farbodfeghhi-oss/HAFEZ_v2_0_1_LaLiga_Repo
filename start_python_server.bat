@echo off
python --version >nul 2>&1
if %errorlevel% neq 0 (
  echo Python nicht gefunden. Bitte zuerst von https://www.python.org/downloads/ installieren.
  pause
  exit /b 1
)
python -m http.server 8080
echo.
echo Oeffne im Browser: http://localhost:8080/src/pages/index.html
pause
