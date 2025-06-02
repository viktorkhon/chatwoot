#!/bin/bash

# Chatwoot Development Environment Setup Script
# This script helps you manage your Docker development environment for fast iteration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        if ! docker compose version &> /dev/null; then
            print_error "docker-compose is not available. Please install Docker Compose."
            exit 1
        else
            DOCKER_COMPOSE="docker compose"
        fi
    else
        DOCKER_COMPOSE="docker-compose"
    fi
    print_success "Docker Compose is available"
}

# Function to create .env file if it doesn't exist
setup_env() {
    if [ ! -f .env ]; then
        print_status "Creating .env file from .env.example..."
        cp .env.example .env
        print_warning "Please review and update the .env file with your configuration"
    else
        print_success ".env file already exists"
    fi
}

# Function to build the development image
build_image() {
    print_status "Building development Docker image..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml build
    print_success "Development image built successfully"
}

# Function to start services
start_services() {
    print_status "Starting development services..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml up -d postgres redis mailhog
    print_success "Infrastructure services started"
    
    print_status "Starting Vite development server..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml up -d vite
    
    print_status "Starting Rails application..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml up -d rails sidekiq
    
    print_success "All services started successfully!"
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    $DOCKER_COMPOSE -f docker-compose.dev.yaml ps
}

# Function to show logs
show_logs() {
    local service=${1:-rails}
    print_status "Showing logs for $service..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml logs -f $service
}

# Function to restart a service
restart_service() {
    local service=${1:-rails}
    print_status "Restarting $service..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml restart $service
    print_success "$service restarted"
}

# Function to stop services
stop_services() {
    print_status "Stopping development services..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml down
    print_success "Services stopped"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up development environment..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml down -v --remove-orphans
    docker image prune -f
    print_success "Cleanup completed"
}

# Function to run Rails console
rails_console() {
    print_status "Opening Rails console..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml exec rails bundle exec rails console
}

# Function to run migrations
run_migrations() {
    print_status "Running database migrations..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml exec rails bundle exec rails db:migrate
    print_success "Migrations completed"
}

# Function to seed database
seed_database() {
    print_status "Seeding database..."
    $DOCKER_COMPOSE -f docker-compose.dev.yaml exec rails bundle exec rails db:seed
    print_success "Database seeded"
}

# Function to reset database
reset_database() {
    print_warning "This will destroy all data in your development database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Resetting database..."
        $DOCKER_COMPOSE -f docker-compose.dev.yaml exec rails bundle exec rails db:drop db:create db:migrate db:seed
        print_success "Database reset completed"
    else
        print_status "Database reset cancelled"
    fi
}

# Function to show help
show_help() {
    echo "Chatwoot Development Environment Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup          - Initial setup (build image, create .env, start services)"
    echo "  start          - Start all development services"
    echo "  stop           - Stop all development services"
    echo "  restart [svc]  - Restart a service (default: rails)"
    echo "  status         - Show service status"
    echo "  logs [svc]     - Show logs for a service (default: rails)"
    echo "  console        - Open Rails console"
    echo "  migrate        - Run database migrations"
    echo "  seed           - Seed database"
    echo "  reset-db       - Reset database (destructive!)"
    echo "  cleanup        - Stop services and clean up"
    echo "  help           - Show this help message"
    echo ""
    echo "Quick Development Workflow:"
    echo "  1. ./scripts/dev-setup.sh setup    # First time only"
    echo "  2. ./scripts/dev-setup.sh start    # Start development"
    echo "  3. Make your code changes           # Live reloading!"
    echo "  4. ./scripts/dev-setup.sh logs     # View logs if needed"
    echo ""
    echo "Services will be available at:"
    echo "  - Rails App: http://localhost:3000"
    echo "  - Vite Dev:  http://localhost:3036"
    echo "  - MailHog:   http://localhost:8025"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis:     localhost:6379"
}

# Main command handling
case "${1:-help}" in
    setup)
        print_status "Setting up Chatwoot development environment..."
        check_docker
        check_docker_compose
        setup_env
        build_image
        start_services
        show_status
        print_success "Setup completed! Your development environment is ready."
        print_status "Access your app at: http://localhost:3000"
        ;;
    start)
        check_docker
        check_docker_compose
        start_services
        ;;
    stop)
        check_docker_compose
        stop_services
        ;;
    restart)
        check_docker_compose
        restart_service $2
        ;;
    status)
        check_docker_compose
        show_status
        ;;
    logs)
        check_docker_compose
        show_logs $2
        ;;
    console)
        check_docker_compose
        rails_console
        ;;
    migrate)
        check_docker_compose
        run_migrations
        ;;
    seed)
        check_docker_compose
        seed_database
        ;;
    reset-db)
        check_docker_compose
        reset_database
        ;;
    cleanup)
        check_docker_compose
        cleanup
        ;;
    help|*)
        show_help
        ;;
esac 