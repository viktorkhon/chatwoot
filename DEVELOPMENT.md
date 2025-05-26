# Chatwoot Local Development Guide

This guide will help you set up and run Chatwoot locally for fast development. The setup uses Docker Compose to orchestrate all the necessary services.

## Prerequisites

- **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Git** - For cloning and version control
- **PowerShell** - For running the development scripts (Windows)

## Quick Start

### 1. Start the Development Environment

```powershell
# Build base image and start all services
.\dev-start.ps1 

# After the first successful startup, prepare the database:
.\dev-helpers.ps1 prepare-db
```

This script will:
- ✅ Check Docker availability
- 🧹 Clean up any existing containers
- 🔨 Build and start all services
- 📊 Show service status
- 🌐 Provide access URLs

### 2. Access Your Application

Once started, you can access:
- **Chatwoot Dashboard**: http://localhost:3000
- **Vite Dev Server**: http://localhost:3036
- **MailHog (Email Testing)**: http://localhost:8025
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## Development Services

Your development environment includes:

| Service | Purpose | Port | URL |
|---------|---------|------|-----|
| Rails | Main application server | 3000 | http://localhost:3000 |
| Vite | Frontend asset development server | 3036 | http://localhost:3036 |
| PostgreSQL | Database | 5432 | localhost:5432 |
| Redis | Cache & job queue | 6379 | localhost:6379 |
| Sidekiq | Background job processor | - | - |
| MailHog | Email testing interface | 8025 | http://localhost:8025 |

## Development Helper Commands

Use the `dev-helpers.ps1` script for common development tasks:

```powershell
# View available commands
.\dev-helpers.ps1

# Common commands
.\dev-helpers.ps1 logs          # View live logs from all services
.\dev-helpers.ps1 console       # Access Rails console
.\dev-helpers.ps1 migrate       # Run database migrations
.\dev-helpers.ps1 restart-rails # Restart Rails service
.\dev-helpers.ps1 status        # Show service status
```

### Available Helper Commands

| Command | Description |
|---------|-------------|
| `logs` | View live logs from all services |
| `logs-rails` | View Rails application logs only |
| `logs-vite` | View Vite development server logs |
| `logs-sidekiq` | View Sidekiq background job logs |
| `console` | Access Rails console |
| `migrate` | Run database migrations |
| `seed` | Run database seeds |
| `reset-db` | Reset database (migrate + seed) |
| `restart` | Restart all services |
| `restart-rails` | Restart only Rails service |
| `stop` | Stop all services |
| `status` | Show service status |
| `shell` | Access Rails container shell |
| `test` | Run test suite |
| `clean` | Clean up containers and volumes |
| `mailhog` | Open MailHog web interface |
| `debug-db` | Debug database connectivity |
| `update-env` | Update .env.local from env.development.template |
| `prepare-db` | Prepare database (create, migrate, seed - for first time setup) |
| `use-local-db` | Switch to local Docker database services |
| `use-railway` | Switch to Railway external database services |

## Environment Configuration

The development environment uses these key configurations:

### Environment Files
- **Template**: `env.development.template` - The source template with Railway database configuration
- **Local Config**: `.env.local` - Your customized development settings (auto-created from template)
- **Customization**: Edit `.env.local` to change database passwords, email settings, etc.
- **Note**: Never edit `env.development.template` directly - it's the shared template for all developers

### Database Configuration (Railway External)
- **Host**: shinkansen.proxy.rlwy.net
- **Port**: 17560
- **Database**: railway
- **Username**: postgres
- **Password**: dkSdvSLYiDNQxjTsVQuTprARLaecAPmb
- **URL**: postgresql://postgres:dkSdvSLYiDNQxjTsVQuTprARLaecAPmb@shinkansen.proxy.rlwy.net:17560/railway

### Redis Configuration (Railway External)
- **URL**: redis://default:O5WdTAL7C.4PP~7Ik2tP~QMSAKEZeElU@mainline.proxy.rlwy.net:15984

### Email Configuration (MailHog)
- **SMTP Host**: mailhog
- **SMTP Port**: 1025
- **Web UI**: http://localhost:8025

### Customizing Environment Variables

To customize your development environment:

1. **Copy the template**: The startup script automatically copies `env.development.template` to `.env.local`
2. **Edit `.env.local`**: Change any values you need (database passwords, email settings, etc.)
3. **Restart services**: Run `.\dev-helpers.ps1 restart` to apply changes

**Important**: Always edit `.env.local`, never `env.development.template`. The template file should remain unchanged so other developers get the same starting configuration.

Example customizations in `.env.local`:
```bash
# Switch to local Docker database (comment out Railway settings)
# POSTGRES_HOST=postgres
# POSTGRES_PORT=5432
# DATABASE_URL=postgresql://postgres:your_password@postgres:5432/railway

# Switch to local Docker Redis (comment out Railway settings)  
# REDIS_URL=redis://:your_password@redis:6379

# Custom email sender
MAILER_SENDER_EMAIL=dev@mycompany.com
```

## Development Workflow

### 1. Making Code Changes

All your code changes are automatically synced to the containers via volume mounts:
- Edit files in your local directory
- Changes are immediately reflected in the running containers
- Vite provides hot module replacement for frontend assets
- Rails auto-reloads for most backend changes

### 2. Database Operations

```powershell
# Prepare database on first setup (or if you want to reset everything)
.\dev-helpers.ps1 prepare-db

# Run migrations when you pull new code
.\dev-helpers.ps1 migrate

# Access Rails console for debugging
.\dev-helpers.ps1 console

# Reset database if needed
.\dev-helpers.ps1 reset-db
```

### 3. Viewing Logs

```powershell
# View all service logs
.\dev-helpers.ps1 logs

# View only Rails logs
.\dev-helpers.ps1 logs-rails

# View only Vite logs  
.\dev-helpers.ps1 logs-vite
```

### 4. Testing Emails

All emails sent by the application are caught by MailHog:
- Open http://localhost:8025 to view emails
- No emails are actually sent during development
- Perfect for testing email functionality

### 5. Running Tests

```powershell
# Run the test suite
.\dev-helpers.ps1 test

# Access container shell for manual testing
.\dev-helpers.ps1 shell
```

## Troubleshooting

### Services Won't Start

1. **Check Docker**: Ensure Docker Desktop is running
2. **Check Ports**: Make sure ports 3000, 3036, 5432, 6379, 8025 aren't in use
3. **Clean Environment**: Run `.\dev-helpers.ps1 clean` to reset everything

### Database Issues

```powershell
# Reset the database
.\dev-helpers.ps1 reset-db

# Access database directly
docker-compose exec postgres psql -U postgres -d railway
```

### Performance Issues

- **Memory**: Increase Docker Desktop memory allocation (Settings → Resources → Memory)
- **CPU**: Increase Docker Desktop CPU allocation 
- **Storage**: Run `.\dev-helpers.ps1 clean` periodically to free up space

### Logs and Debugging

```powershell
# Check service status
.\dev-helpers.ps1 status

# View specific service logs
docker-compose logs [service-name]

# Access Rails console for debugging
.\dev-helpers.ps1 console
```

## File Structure

Key development files:
- `docker-compose.yaml` - Base Docker Compose configuration
- `docker-compose.override.yml` - Development-specific overrides
- `docker/Dockerfile.base` - Dockerfile for the base image with all dependencies
- `docker/Dockerfile.development` - Dockerfile for Rails/Sidekiq development images
- `docker/dockerfiles/vite.Dockerfile` - Dockerfile for the Vite dev server
- `.env.local` - Local environment variables
- `dev-start.ps1` - Development startup script
- `dev-helpers.ps1` - Development helper commands

## Production vs Development

This setup is optimized for development with:
- **Hot reloading** for frontend assets
- **Auto-restart** for code changes  
- **Local email testing** with MailHog
- **Debug logging** enabled
- **Source maps** for easier debugging
- **Volume mounts** for instant code sync

## Getting Help

If you encounter issues:
1. Check the logs: `.\dev-helpers.ps1 logs`
2. Verify service status: `.\dev-helpers.ps1 status`
3. Try restarting: `.\dev-helpers.ps1 restart`
4. Clean environment: `.\dev-helpers.ps1 clean`

## What's Next?

1. **Create your first account** at http://localhost:3000
2. **Set up an inbox** to start receiving messages
3. **Install the widget** on a test site
4. **Explore the codebase** and start making changes!

Happy developing! 🚀 

## Git Workflow on Windows

### Husky Pre-commit Hooks

The project uses Husky for Git hooks that run linting and validation before commits and pushes. These have been configured to work properly on Windows:

- **Pre-commit**: Runs ESLint on JavaScript/Vue files and RuboCop on Ruby files (Unix/Linux only)
- **Pre-push**: Validates that you're not pushing directly to protected branches (master/develop)

### Git Commands

```powershell
# Standard Git workflow (hooks run automatically)
git add .
git commit -m "Your commit message"
git push

# Alternative: Use the Windows-specific push script
.\git-push-windows.ps1

# Skip hooks entirely if needed (for emergencies only)
.\git-push-windows.ps1 -SkipHooks

# Force push with lease (safer than --force)
.\git-push-windows.ps1 -Force
```

### Troubleshooting Git Issues

If you encounter any Git hook issues:

1. **Use the Windows script**: `.\git-push-windows.ps1`
2. **Skip hooks temporarily**: `$env:HUSKY = "0"; git push`
3. **Reset environment**: `Remove-Item Env:HUSKY -ErrorAction SilentlyContinue`

## Development Workflow 