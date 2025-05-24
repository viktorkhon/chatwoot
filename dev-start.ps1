# Chatwoot Development Environment Startup Script
# This script sets up and starts the development environment using Docker Compose

# Check if Docker is running
Write-Host "🐳 Checking Docker..." -ForegroundColor Blue
$dockerRunning = $false
try {
    docker version | Out-Null
    $dockerRunning = $true
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Clean up any existing containers
Write-Host "🧹 Cleaning up existing containers..." -ForegroundColor Blue
docker-compose down --remove-orphans

# Build and start services
Write-Host "🔨 Building and starting services..." -ForegroundColor Blue
docker-compose up --build -d

# Wait a moment for services to initialize
Start-Sleep -Seconds 10

# Check service status
Write-Host "📊 Checking service status..." -ForegroundColor Blue
$services = @("rails", "sidekiq", "postgres", "redis", "mailhog")

foreach ($service in $services) {
    $status = docker-compose ps $service --format "table {{.Status}}" | Select-String -Pattern "Up"
    if ($status) {
        Write-Host "✅ $service is running" -ForegroundColor Green
    } else {
        Write-Host "❌ $service failed to start" -ForegroundColor Red
        docker-compose logs $service --tail 10
    }
}

# Display connection information
Write-Host "`n🌐 Development Environment Ready!" -ForegroundColor Green
Write-Host "📱 Rails Application: http://localhost:3000" -ForegroundColor Cyan
Write-Host "📧 MailHog (Email Testing): http://localhost:8025" -ForegroundColor Cyan
Write-Host "🗄️  PostgreSQL: localhost:5432" -ForegroundColor Cyan  
Write-Host "🔴 Redis: localhost:6379" -ForegroundColor Cyan

Write-Host "`n⚡ To start Vite (Frontend Development):" -ForegroundColor Yellow
Write-Host "   1. Install Node.js dependencies: pnpm install" -ForegroundColor White
Write-Host "   2. Start Vite dev server: pnpm run dev" -ForegroundColor White
Write-Host "   3. Vite will be available at: http://localhost:3036" -ForegroundColor Cyan

Write-Host "`n📋 Useful Commands:" -ForegroundColor Yellow
Write-Host "   • View logs: docker-compose logs [service_name]" -ForegroundColor White
Write-Host "   • Stop all: docker-compose down" -ForegroundColor White
Write-Host "   • Rails console: docker-compose exec rails bundle exec rails c" -ForegroundColor White
Write-Host "   • Database shell: docker-compose exec postgres psql -U postgres -d railway" -ForegroundColor White
Write-Host "   • Run dev helpers: .\dev-helpers.ps1" -ForegroundColor White

Write-Host "`n🎉 Happy Coding!" -ForegroundColor Green 