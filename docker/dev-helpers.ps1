# Chatwoot Development Helper Commands
# This script provides useful development commands for working with Chatwoot

param(
    [Parameter(Position=0)]
    [string]$Command
)

function Show-Help {
    Write-Host "CHATWOOT: Development Helper Commands" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\dev-helpers.ps1 <command>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host "  logs          - View live logs from all services" -ForegroundColor Cyan
    Write-Host "  logs-rails    - View Rails application logs" -ForegroundColor Cyan
    Write-Host "  logs-vite     - View Vite development server logs" -ForegroundColor Cyan
    Write-Host "  logs-sidekiq  - View Sidekiq background job logs" -ForegroundColor Cyan
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
    Write-Host "  debug-db      - Debug database connectivity" -ForegroundColor Cyan
    Write-Host "  update-env    - Update .env.local from env.development.template" -ForegroundColor Cyan
    Write-Host "  prepare-db    - Prepare database (create, migrate, seed - for first time setup)" -ForegroundColor Cyan
    Write-Host "  use-local-db  - Switch to local Docker database services" -ForegroundColor Cyan
    Write-Host "  use-railway   - Switch to Railway external database services" -ForegroundColor Cyan
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

function Show-Sidekiq-Logs {
    docker-compose logs -f sidekiq
}

function Open-Console {
    docker-compose exec rails bundle exec rails console
}

function Run-Migrations {
    Write-Host "MIGRATE: Running database migrations..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:migrate
}

function Run-Seeds {
    Write-Host "SEED: Running database seeds..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:seed
}

function Reset-Database {
    Write-Host "RESET: Resetting database..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rails db:reset
}

function Restart-Services {
    Write-Host "RESTART: Restarting all services..." -ForegroundColor Yellow
    docker-compose restart
}

function Restart-Rails {
    Write-Host "RESTART: Restarting Rails service..." -ForegroundColor Yellow
    docker-compose restart rails
}

function Stop-Services {
    Write-Host "STOP: Stopping all services..." -ForegroundColor Yellow
    docker-compose down
}

function Show-Status {
    Write-Host "STATUS: Service Status:" -ForegroundColor Yellow
    docker-compose ps
}

function Open-Shell {
    docker-compose exec rails /bin/bash
}

function Run-Tests {
    Write-Host "TEST: Running test suite..." -ForegroundColor Yellow
    docker-compose exec rails bundle exec rspec
}

function Clean-Environment {
    Write-Host "CLEAN: Cleaning up development environment..." -ForegroundColor Yellow
    docker-compose down -v
    docker system prune -f
    Write-Host "SUCCESS: Cleanup complete!" -ForegroundColor Green
}

function Open-MailHog {
    Write-Host "MAILHOG: Opening MailHog web interface..." -ForegroundColor Yellow
    Start-Process "http://localhost:8025"
}

function Debug-Database {
    Write-Host "DEBUG-DB: Running database connectivity debug..." -ForegroundColor Yellow
    .\debug-db.ps1
}

function Update-Environment {
    Write-Host "UPDATE-ENV: Updating .env.local from env.development.template..." -ForegroundColor Yellow
    if (Test-Path "env.development.template") {
        if (Test-Path ".env.local") {
            Write-Host "WARNING: This will overwrite your current .env.local file!" -ForegroundColor Red
            $response = Read-Host "Continue? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Host "CANCELLED: Environment update cancelled" -ForegroundColor Yellow
                return
            }
        }
        Copy-Item "env.development.template" ".env.local" -Force
        Write-Host "SUCCESS: .env.local updated from env.development.template" -ForegroundColor Green
        Write-Host "INFO: Restart services to apply changes: .\dev-helpers.ps1 restart" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: env.development.template not found!" -ForegroundColor Red
    }
}

function Use-Local-Database {
    Write-Host "LOCAL-DB: Switching to local Docker database services..." -ForegroundColor Yellow
    Write-Host "STOP: Stopping current services..." -ForegroundColor Blue
    docker-compose down
    Write-Host "START: Starting with local database services..." -ForegroundColor Blue
    docker-compose --profile local-db up --build -d
    Write-Host "SUCCESS: Now using local PostgreSQL and Redis containers" -ForegroundColor Green
    Write-Host "INFO: Update your .env.local to use local database URLs if needed" -ForegroundColor Cyan
}

function Use-Railway-Database {
    Write-Host "RAILWAY: Switching to Railway external database services..." -ForegroundColor Yellow
    Write-Host "STOP: Stopping current services..." -ForegroundColor Blue
    docker-compose down
    Write-Host "START: Starting without local database services..." -ForegroundColor Blue
    docker-compose up --build -d
    Write-Host "SUCCESS: Now using Railway PostgreSQL and Redis services" -ForegroundColor Green
    Write-Host "INFO: Ensure your .env.local has Railway database URLs configured" -ForegroundColor Cyan
}

function Prepare-Database {
    Write-Host "PREPARE-DB: Preparing database (create, migrate, seed)..." -ForegroundColor Yellow
    Write-Host "INFO: This might take a few minutes on the first run." -ForegroundColor Cyan
    # As per Chatwoot docs: docker compose run --rm rails bundle exec rails db:chatwoot_prepare
    # The equivalent for our setup (assuming services are up or can be started by exec)
    # Ensure rails service is built/running for exec to work.
    # It might be better to use `run --rm` to ensure a fresh container for this task.
    docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
    Write-Host "SUCCESS: Database prepared!" -ForegroundColor Green
}

# Command execution
switch ($Command.ToLower()) {
    "logs" { Show-Logs }
    "logs-rails" { Show-Rails-Logs }
    "logs-vite" { Show-Vite-Logs }
    "logs-sidekiq" { Show-Sidekiq-Logs }
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
    "debug-db" { Debug-Database }
    "update-env" { Update-Environment }
    "use-local-db" { Use-Local-Database }
    "use-railway" { Use-Railway-Database }
    "prepare-db" { Prepare-Database }
    default { Show-Help }
} 