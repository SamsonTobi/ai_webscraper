#!/usr/bin/env powershell

Write-Host "🚀 AI WebScraper Dashboard" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "✅ Flutter detected" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Get dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Failed to get dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Run the dashboard
Write-Host "🌐 Starting the AI WebScraper Dashboard..." -ForegroundColor Cyan
Write-Host "📍 URL: http://localhost:8080" -ForegroundColor Green
Write-Host "🛑 Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔑 You'll need a Gemini API key to use the scraper!" -ForegroundColor Magenta
Write-Host "   Get one at: https://makersuite.google.com/app/apikey" -ForegroundColor Blue
Write-Host ""

try {
    flutter run -d chrome --web-port 8080
} catch {
    Write-Host ""
    Write-Host "❌ Error: Failed to start the dashboard" -ForegroundColor Red
    Write-Host "💡 Try running: flutter run -d chrome" -ForegroundColor Cyan
}

Write-Host ""
Read-Host "Press Enter to exit"
