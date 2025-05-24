# Chatwoot Development Helper Commands
# This script provides useful development commands for working with Chatwoot

param(
    [Parameter(Position=0)]
    [string]$Command
)

function Show-Help {
    Write-Host "🛠️  Chatwoot Development Helper Commands" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\dev-helpers.ps1 <command>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host "  logs          - View live logs from all services" -ForegroundColor Cyan
    Write-Host "  logs-rails    - View Rails application logs" -ForegroundColor Cyan
    Write-Host "  logs-vite     - View Vite development server logs" -ForegroundColor Cyan
    Write-Host "  console       - Access Rails console" -ForegroundColor Cyan
    Write-Host "  migrate       - Run database migrations" -ForegroundColor Cyan
    Write-Host "  seed          - Run database seeds" -ForegroundColor Cyan
    Write-Host "  reset-db      - Reset database (migrate + seed)" -ForegroundColor Cyan
    Write-Host "  restart       - Restart all services" -ForegroundColor Cyan
    Write-Host "  restart-rails - Restart only Rails service" -ForegroundColor Cyan
    Write-Host "  stop          - Stop all services" -ForegroundColor Cyan
    Write-Host "  status        - Show service status" -ForegroundColor Cyan
    Write-Host "  shell         - Access Rails container shell" -ForegroundColor Cyan
    Write-Host "  test          - Run test suite" -ForegroundColor Cyan
    Write-Host "  clean         - Clean up containers and volumes" -ForegroundColor Cyan
    Write-Host "  mailhog       - Open MailHog web interface" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Logs {
    docker-compose logs -f
}

function Show-Rails-Logs {
    docker-compose logs -f rails
}

function Show-Vite-Logs {
    docker-compose logs -f vite
}

function Open-Console {
    docker-compose exec rails bundle exec rails console
}

function Run-Migrations {
    Write-Host "🔄 Running database migrations..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:migrate
}

function Run-Seeds {
    Write-Host "🌱 Running database seeds..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:seed
}

function Reset-Database {
    Write-Host "🔄 Resetting database..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:reset
}

function Restart-Services {
    Write-Host "🔄 Restarting all services..." -ForegroundColor Yellow
    docker-compose restart
}

function Restart-Rails {
    Write-Host "🔄 Restarting Rails service..." -ForegroundColor Yellow
    docker-compose restart rails
}

function Stop-Services {
    Write-Host "⏹️  Stopping all services..." -ForegroundColor Yellow
    docker-compose down
}

function Show-Status {
    Write-Host "📊 Service Status:" -ForegroundColor Yellow
    docker-compose ps
}

function Open-Shell {
    docker-compose exec rails /bin/bash
}

function Run-Tests {
    Write-Host "🧪 Running test suite..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rspec
}

function Clean-Environment {
    Write-Host "🧹 Cleaning up development environment..." -ForegroundColor Yellow
    docker-compose down -v
    docker system prune -f
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

function Open-MailHog {
    Write-Host "📧 Opening MailHog web interface..." -ForegroundColor Yellow
    Start-Process "http://localhost:8025"
}

# Command execution
switch ($Command.ToLower()) {
    "logs" { Show-Logs }
    "logs-rails" { Show-Rails-Logs }
    "logs-vite" { Show-Vite-Logs }
    "console" { Open-Console }
    "migrate" { Run-Migrations }
    "seed" { Run-Seeds }
    "reset-db" { Reset-Database }
    "restart" { Restart-Services }
    "restart-rails" { Restart-Rails }
    "stop" { Stop-Services }
    "status" { Show-Status }
    "shell" { Open-Shell }
    "test" { Run-Tests }
    "clean" { Clean-Environment }
    "mailhog" { Open-MailHog }
    default { Show-Help }
} 