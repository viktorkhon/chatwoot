# Chatwoot Development Environment Startup Script
# This script sets up and starts the development environment using Docker Compose

# Check if Docker is running
Write-Host "Docker: Checking Docker..." -ForegroundColor Blue
$dockerRunning = $false
try {
    docker version | Out-Null
    $dockerRunning = $true
    Write-Host "SUCCESS: Docker is running" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check and setup environment files
Write-Host "ENV: Setting up environment files..." -ForegroundColor Blue
if (-not (Test-Path ".env.local")) {
    if (Test-Path "env.development.template") {
        Copy-Item "env.development.template" ".env.local"
        Write-Host "SUCCESS: Created .env.local from env.development.template" -ForegroundColor Green
        Write-Host "INFO: You can customize database and email settings in .env.local" -ForegroundColor Yellow
        Write-Host "NOTE: To update .env.local with template changes, run: .\dev-helpers.ps1 update-env" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: env.development.template not found!" -ForegroundColor Red
        Write-Host "This file is required to create your local environment configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "SUCCESS: .env.local already exists (using existing variables)" -ForegroundColor Green
    Write-Host "INFO: To update from template changes, run: .\dev-helpers.ps1 update-env" -ForegroundColor Yellow
}

# Clean up any existing containers
Write-Host "CLEANUP: Cleaning up existing containers..." -ForegroundColor Blue
docker-compose down --remove-orphans

# Build and start services (FAST development mode)
Write-Host "BUILD: Building and starting services (ULTRA-FAST mode)..." -ForegroundColor Blue
Write-Host "INFO: No asset precompilation - instant startup!" -ForegroundColor Green
# Start services without local database (using Railway external services)
docker-compose up --build -d base rails sidekiq vite mailhog # Explicitly list services to ensure correct startup order and include base

# Wait a moment for services to initialize
Start-Sleep -Seconds 5

# Check service status
Write-Host "STATUS: Checking service status..." -ForegroundColor Blue
$services = @("rails", "vite", "sidekiq", "mailhog")

foreach ($service in $services) {
    $status = docker-compose ps $service --format "table {{.Status}}" | Select-String -Pattern "Up"
    if ($status) {
        Write-Host "SUCCESS: $service is running" -ForegroundColor Green
    } else {
        Write-Host "ERROR: $service failed to start" -ForegroundColor Red
        docker-compose logs $service --tail 10
    }
}

# Display connection information
Write-Host "`nREADY: Ultra-Fast Development Environment Ready!" -ForegroundColor Green
Write-Host "Rails Application: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Vite Dev Server (HMR): http://localhost:3036" -ForegroundColor Cyan
Write-Host "MailHog (Email Testing): http://localhost:8025" -ForegroundColor Cyan
Write-Host "PostgreSQL: Railway Database (External)" -ForegroundColor Cyan  
Write-Host "Redis: Railway Redis (External)" -ForegroundColor Cyan

Write-Host "`nPERFORMANCE: Lightning Fast Development:" -ForegroundColor Yellow
Write-Host "   ⚡ No asset building during startup - instant Rails boot!" -ForegroundColor Green
Write-Host "   🔥 Hot Module Replacement via Vite dev server" -ForegroundColor Green
Write-Host "   📦 All code changes reflected instantly via volume mounts" -ForegroundColor Green
Write-Host "   🚀 Typical startup time: ~10-15 seconds" -ForegroundColor Green

Write-Host "`nCOMMANDS: Useful Commands:" -ForegroundColor Yellow
Write-Host "   • View logs: docker-compose logs [service_name]" -ForegroundColor White
Write-Host "   • Stop all: docker-compose down" -ForegroundColor White
Write-Host "   • Rails console: docker-compose exec rails bundle exec rails c" -ForegroundColor White
Write-Host "   • Database shell: Use Railway dashboard or external client" -ForegroundColor White
Write-Host "   • Run dev helpers: .\dev-helpers.ps1" -ForegroundColor White
Write-Host "   • Prepare DB (first time): .\dev-helpers.ps1 prepare-db" -ForegroundColor Cyan

Write-Host "`nHappy Coding! 🚀" -ForegroundColor Green 