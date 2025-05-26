# Quick Fix for Redis Authentication Issue
# This script updates your environment and restarts services

Write-Host "REDIS FIX: Fixing Redis authentication issue..." -ForegroundColor Yellow

# Step 1: Update .env.local from template (includes REDIS_PASSWORD fix)
Write-Host "STEP 1: Updating .env.local from template..." -ForegroundColor Blue
if (Test-Path "env.development.template") {
    Copy-Item "env.development.template" ".env.local" -Force
    Write-Host "SUCCESS: Updated .env.local with fixed Redis configuration" -ForegroundColor Green
} else {
    Write-Host "ERROR: env.development.template not found!" -ForegroundColor Red
    exit 1
}

# Step 2: Stop all services
Write-Host "STEP 2: Stopping all services..." -ForegroundColor Blue
docker-compose down

# Step 3: Start services without local database (Railway mode)
Write-Host "STEP 3: Starting services in Railway mode (external database)..." -ForegroundColor Blue
docker-compose up --build -d

# Step 4: Check service status
Write-Host "STEP 4: Checking service status..." -ForegroundColor Blue
Start-Sleep -Seconds 5

$services = @("rails", "sidekiq", "mailhog")
foreach ($service in $services) {
    $status = docker-compose ps $service --format "table {{.Status}}" | Select-String -Pattern "Up"
    if ($status) {
        Write-Host "SUCCESS: $service is running" -ForegroundColor Green
    } else {
        Write-Host "ERROR: $service failed to start" -ForegroundColor Red
        Write-Host "Logs for ${service}:" -ForegroundColor Yellow
        docker-compose logs $service --tail 10
    }
}

Write-Host "`nFIX COMPLETE: Redis authentication should now be working!" -ForegroundColor Green
Write-Host "Using Railway external Redis: mainline.proxy.rlwy.net:15984" -ForegroundColor Cyan
Write-Host "Local Redis container is disabled (using profiles)" -ForegroundColor Cyan

Write-Host "`nIf you still see issues, check logs with:" -ForegroundColor Yellow
Write-Host "  docker-compose logs sidekiq" -ForegroundColor White 