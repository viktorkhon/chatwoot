# Chatwoot Development Environment Setup Script for Windows PowerShell
# This script helps you manage your Docker development environment for fast iteration

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    [Parameter(Position=1)]
    [string]$Service = "rails"
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if Docker is running
function Test-Docker {
    try {
        $null = docker info 2>$null
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error "Docker is not running. Please start Docker and try again."
        return $false
    }
}

# Function to check if docker-compose is available
function Test-DockerCompose {
    $script:DockerCompose = $null
    
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        $script:DockerCompose = "docker-compose"
    }
    elseif (docker compose version 2>$null) {
        $script:DockerCompose = "docker compose"
    }
    else {
        Write-Error "docker-compose is not available. Please install Docker Compose."
        return $false
    }
    
    Write-Success "Docker Compose is available"
    return $true
}

# Function to create .env file if it doesn't exist
function Initialize-Environment {
    if (-not (Test-Path .env)) {
        Write-Status "Creating .env file from .env.example..."
        Copy-Item .env.example .env
        Write-Warning "Please review and update the .env file with your configuration"
    }
    else {
        Write-Success ".env file already exists"
    }
}

# Function to build the development image
function Build-Image {
    Write-Status "Building development Docker image..."
    & $script:DockerCompose -f docker-compose.dev.yaml build
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Development image built successfully"
    }
    else {
        Write-Error "Failed to build development image"
        exit 1
    }
}

# Function to start services
function Start-Services {
    Write-Status "Starting development services..."
    & $script:DockerCompose -f docker-compose.dev.yaml up -d postgres redis mailhog
    Write-Success "Infrastructure services started"
    
    Write-Status "Starting Vite development server..."
    & $script:DockerCompose -f docker-compose.dev.yaml up -d vite
    
    Write-Status "Starting Rails application..."
    & $script:DockerCompose -f docker-compose.dev.yaml up -d rails sidekiq
    
    Write-Success "All services started successfully!"
}

# Function to show service status
function Show-Status {
    Write-Status "Service Status:"
    & $script:DockerCompose -f docker-compose.dev.yaml ps
}

# Function to show logs
function Show-Logs {
    param([string]$ServiceName = "rails")
    Write-Status "Showing logs for $ServiceName..."
    & $script:DockerCompose -f docker-compose.dev.yaml logs -f $ServiceName
}

# Function to restart a service
function Restart-Service {
    param([string]$ServiceName = "rails")
    Write-Status "Restarting $ServiceName..."
    & $script:DockerCompose -f docker-compose.dev.yaml restart $ServiceName
    Write-Success "$ServiceName restarted"
}

# Function to stop services
function Stop-Services {
    Write-Status "Stopping development services..."
    & $script:DockerCompose -f docker-compose.dev.yaml down
    Write-Success "Services stopped"
}

# Function to clean up
function Remove-Environment {
    Write-Status "Cleaning up development environment..."
    & $script:DockerCompose -f docker-compose.dev.yaml down -v --remove-orphans
    docker image prune -f
    Write-Success "Cleanup completed"
}

# Function to run Rails console
function Start-RailsConsole {
    Write-Status "Opening Rails console..."
    & $script:DockerCompose -f docker-compose.dev.yaml exec rails bundle exec rails console
}

# Function to run migrations
function Invoke-Migrations {
    Write-Status "Running database migrations..."
    & $script:DockerCompose -f docker-compose.dev.yaml exec rails bundle exec rails db:migrate
    Write-Success "Migrations completed"
}

# Function to seed database
function Initialize-Database {
    Write-Status "Seeding database..."
    & $script:DockerCompose -f docker-compose.dev.yaml exec rails bundle exec rails db:seed
    Write-Success "Database seeded"
}

# Function to reset database
function Reset-Database {
    Write-Warning "This will destroy all data in your development database!"
    $confirmation = Read-Host "Are you sure? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Write-Status "Resetting database..."
        & $script:DockerCompose -f docker-compose.dev.yaml exec rails bundle exec rails db:drop db:create db:migrate db:seed
        Write-Success "Database reset completed"
    }
    else {
        Write-Status "Database reset cancelled"
    }
}

# Function to show help
function Show-Help {
    Write-Host "Chatwoot Development Environment Manager for Windows" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\dev-setup.ps1 [COMMAND] [SERVICE]" -ForegroundColor White
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  setup          - Initial setup (build image, create .env, start services)"
    Write-Host "  start          - Start all development services"
    Write-Host "  stop           - Stop all development services"
    Write-Host "  restart [svc]  - Restart a service (default: rails)"
    Write-Host "  status         - Show service status"
    Write-Host "  logs [svc]     - Show logs for a service (default: rails)"
    Write-Host "  console        - Open Rails console"
    Write-Host "  migrate        - Run database migrations"
    Write-Host "  seed           - Seed database"
    Write-Host "  reset-db       - Reset database (destructive!)"
    Write-Host "  cleanup        - Stop services and clean up"
    Write-Host "  help           - Show this help message"
    Write-Host ""
    Write-Host "Quick Development Workflow:" -ForegroundColor Yellow
    Write-Host "  1. .\scripts\dev-setup.ps1 setup    # First time only"
    Write-Host "  2. .\scripts\dev-setup.ps1 start    # Start development"
    Write-Host "  3. Make your code changes           # Live reloading!"
    Write-Host "  4. .\scripts\dev-setup.ps1 logs     # View logs if needed"
    Write-Host ""
    Write-Host "Services will be available at:" -ForegroundColor Yellow
    Write-Host "  - Rails App: http://localhost:3000"
    Write-Host "  - Vite Dev:  http://localhost:3036"
    Write-Host "  - MailHog:   http://localhost:8025"
    Write-Host "  - PostgreSQL: localhost:5432"
    Write-Host "  - Redis:     localhost:6379"
}

# Main command handling
switch ($Command.ToLower()) {
    "setup" {
        Write-Status "Setting up Chatwoot development environment..."
        if (-not (Test-Docker)) { exit 1 }
        if (-not (Test-DockerCompose)) { exit 1 }
        Initialize-Environment
        Build-Image
        Start-Services
        Show-Status
        Write-Success "Setup completed! Your development environment is ready."
        Write-Status "Access your app at: http://localhost:3000"
    }
    "start" {
        if (-not (Test-Docker)) { exit 1 }
        if (-not (Test-DockerCompose)) { exit 1 }
        Start-Services
    }
    "stop" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Stop-Services
    }
    "restart" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Restart-Service $Service
    }
    "status" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Show-Status
    }
    "logs" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Show-Logs $Service
    }
    "console" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Start-RailsConsole
    }
    "migrate" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Invoke-Migrations
    }
    "seed" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Initialize-Database
    }
    "reset-db" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Reset-Database
    }
    "cleanup" {
        if (-not (Test-DockerCompose)) { exit 1 }
        Remove-Environment
    }
    default {
        Show-Help
    }
} 