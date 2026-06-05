# QuantDinger Startup Script
# Usage: Right-click -> Run with PowerShell, or execute in PowerShell: .\start-quantdinger.ps1
# To stop all services: .\start-quantdinger.ps1 -Stop

param(
    [switch]$Stop
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendPath = Join-Path $ProjectRoot "backend_api_python"
$VenvPython = Join-Path $BackendPath ".venv\Scripts\python.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QuantDinger Startup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Stop mode
if ($Stop) {
    Write-Host "`n[Stopping all services...]" -ForegroundColor Yellow
    
    Write-Host "  Stopping frontend container..." -NoNewline
    docker stop quantdinger-frontend 2>$null
    docker rm quantdinger-frontend 2>$null
    Write-Host " [Done]" -ForegroundColor Green
    
    Write-Host "  Stopping PostgreSQL..." -NoNewline
    docker stop quantdinger-db 2>$null
    Write-Host " [Done]" -ForegroundColor Green
    
    Write-Host "  Stopping Redis..." -NoNewline
    docker stop quantdinger-redis 2>$null
    Write-Host " [Done]" -ForegroundColor Green
    
    Write-Host "  Stopping Python backend..." -NoNewline
    Get-Process python* -ErrorAction SilentlyContinue | 
        Where-Object { $_.Path -like "*quantdinger*" } | 
        Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host " [Done]" -ForegroundColor Green
    
    Write-Host "`nAll services stopped." -ForegroundColor Yellow
    exit 0
}

# ========== Start services ==========

# 1. Check Docker
Write-Host "`n[1/5] Checking Docker..." -NoNewline
try {
    docker info 2>&1 | Out-Null
    Write-Host " [Running]" -ForegroundColor Green
} catch {
    Write-Host " [Not Running]" -ForegroundColor Red
    Write-Host "Please start Docker Desktop first" -ForegroundColor Red
    exit 1
}

# 2. Start database containers
Write-Host "`n[2/5] Starting database containers..."
Push-Location $ProjectRoot

# PostgreSQL
$dbStatus = docker ps --filter "name=quantdinger-db" --format "{{.Status}}"
if ($dbStatus) {
    Write-Host "  PostgreSQL: Running ($dbStatus)" -ForegroundColor Green
} else {
    Write-Host "  Starting PostgreSQL..." -NoNewline
    docker compose up -d postgres 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    Write-Host " [Done]" -ForegroundColor Green
}

# Redis
$redisStatus = docker ps --filter "name=quantdinger-redis" --format "{{.Status}}"
if ($redisStatus) {
    Write-Host "  Redis: Running ($redisStatus)" -ForegroundColor Green
} else {
    Write-Host "  Starting Redis..." -NoNewline
    docker compose up -d redis 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Write-Host " [Done]" -ForegroundColor Green
}

Pop-Location

# 3. Check and start Python backend
Write-Host "`n[3/5] Checking Python backend..."
$backendProcess = Get-Process python* -ErrorAction SilentlyContinue | 
    Where-Object { $_.Path -eq $VenvPython }

if ($backendProcess) {
    Write-Host "  Python backend running (PID: $($backendProcess.Id))" -ForegroundColor Green
} else {
    if (-not (Test-Path $VenvPython)) {
        Write-Host "  Virtual environment not found, please run setup first" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Starting Python backend..." -NoNewline
    Push-Location $BackendPath
    Start-Process -FilePath $VenvPython -ArgumentList "run.py" -WindowStyle Hidden
    Pop-Location
    Start-Sleep -Seconds 5
    Write-Host " [Done]" -ForegroundColor Green
}

# 4. Start frontend container
Write-Host "`n[4/5] Starting frontend container..."
$frontendStatus = docker ps --filter "name=quantdinger-frontend" --format "{{.Status}}"
if ($frontendStatus) {
    Write-Host "  Frontend container running ($frontendStatus)" -ForegroundColor Green
} else {
    docker rm quantdinger-frontend 2>$null | Out-Null
    
    Write-Host "  Starting frontend container..." -NoNewline
    docker run -d --name quantdinger-frontend `
        -p 8888:80 `
        -e BACKEND_URL=http://host.docker.internal:5000 `
        --add-host=host.docker.internal:host-gateway `
        ghcr.io/brokermr810/quantdinger-frontend:latest 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Write-Host " [Done]" -ForegroundColor Green
}

# 5. Health check
Write-Host "`n[5/5] Health check..."
Start-Sleep -Seconds 2

# Check backend API
try {
    $apiHealth = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -TimeoutSec 5
    Write-Host "  Backend API: Healthy" -ForegroundColor Green
} catch {
    Write-Host "  Backend API: Not responding" -ForegroundColor Red
}

# Check frontend
try {
    $frontendResp = Invoke-WebRequest -Uri "http://localhost:8888" -TimeoutSec 5 -UseBasicParsing
    Write-Host "  Frontend: OK (HTTP $($frontendResp.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "  Frontend: Not responding" -ForegroundColor Red
}

# Done
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Startup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Frontend:  " -NoNewline; Write-Host "http://localhost:8888" -ForegroundColor Cyan
Write-Host "  Backend:   " -NoNewline; Write-Host "http://localhost:5000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Login: quantdinger / 123456" -ForegroundColor Yellow
Write-Host ""
Write-Host "Stop services: .\start-quantdinger.ps1 -Stop" -ForegroundColor Gray
Write-Host ""
