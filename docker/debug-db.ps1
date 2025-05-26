# Database Connection Debug Script
# This script helps debug database connectivity issues

Write-Host "DATABASE DEBUG: Checking database connectivity..." -ForegroundColor Yellow

# Check if .env.local exists
if (Test-Path ".env.local") {
    Write-Host "SUCCESS: .env.local file exists" -ForegroundColor Green
    
    # Read database configuration
    $envContent = Get-Content ".env.local"
    $dbHost = ($envContent | Select-String "POSTGRES_HOST=").ToString().Split("=")[1]
    $dbPort = ($envContent | Select-String "POSTGRES_PORT=").ToString().Split("=")[1]
    $dbUser = ($envContent | Select-String "POSTGRES_USERNAME=").ToString().Split("=")[1]
    $dbName = ($envContent | Select-String "POSTGRES_DATABASE=").ToString().Split("=")[1]
    
    Write-Host "Database Configuration:" -ForegroundColor Cyan
    Write-Host "  Host: $dbHost" -ForegroundColor White
    Write-Host "  Port: $dbPort" -ForegroundColor White
    Write-Host "  User: $dbUser" -ForegroundColor White
    Write-Host "  Database: $dbName" -ForegroundColor White
    
    # Test database connection from Rails container
    Write-Host "`nTesting database connection from Rails container..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT version()').first"
    
} else {
    Write-Host "ERROR: .env.local file not found!" -ForegroundColor Red
    if (Test-Path "env.development.template") {
        Write-Host "INFO: Found env.development.template - run .\dev-start.ps1 to create .env.local from template" -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: env.development.template also missing!" -ForegroundColor Red
    }
}

Write-Host "`nTo manually test database connection:" -ForegroundColor Yellow
Write-Host "docker-compose exec rails bundle exec rails db:migrate:status" -ForegroundColor White 