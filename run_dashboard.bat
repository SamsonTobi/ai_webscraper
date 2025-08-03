@echo off
echo Starting AI WebScraper Dashboard...
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Navigate to web app directory
cd /d "%~dp0web_app"

REM Get dependencies
echo Installing dependencies...
flutter pub get

if %errorlevel% neq 0 (
    echo Error: Failed to get dependencies
    pause
    exit /b 1
)

REM Run the app
echo.
echo Starting the dashboard on http://localhost:8080
echo Press Ctrl+C to stop the server
echo.
flutter run -d chrome --web-port 8080

pause
