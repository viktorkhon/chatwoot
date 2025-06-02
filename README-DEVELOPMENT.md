# Chatwoot Fast Development Environment

This guide explains how to set up a **fast iteration Docker development environment** for Chatwoot that solves the problem of slow rebuild times when making small code changes.

## 🚀 Quick Start

### 1. Prerequisites
- Docker Desktop installed and running
- Git (for cloning the repository)
- At least 8GB RAM recommended

### 2. Initial Setup (One-time)

**Windows (PowerShell):**
```powershell
.\scripts\dev-setup.ps1 setup
```

**Linux/macOS (Bash):**
```bash
chmod +x scripts/dev-setup.sh
./scripts/dev-setup.sh setup
```

This will:
- Build the development Docker image (one-time build)
- Create your `.env` file
- Start all services (PostgreSQL, Redis, Vite, Rails, Sidekiq)
- Set up the database

### 3. Daily Development Workflow

```bash
# Start your development environment
./scripts/dev-setup.sh start

# Make your code changes (they'll be reflected immediately!)

# View logs if needed
./scripts/dev-setup.sh logs

# Stop when done
./scripts/dev-setup.sh stop
```

## ✨ Key Benefits

### 🔥 **Instant Code Changes**
- Your code is mounted as a volume, so changes are reflected immediately
- No rebuilding containers for code changes
- No more waiting 3-5 minutes for asset compilation

### 📦 **Persistent Dependencies** 
- Ruby gems and npm packages are cached in Docker volumes
- Only rebuild when `Gemfile` or `package.json` changes
- Dependencies persist between container restarts

### 🔧 **Isolated Services**
- PostgreSQL, Redis, and Sidekiq run independently
- Only restart what you need to restart
- Services keep running while you iterate on code

## 🛠️ Available Commands

### Management Scripts

**Windows PowerShell:**
```powershell
.\scripts\dev-setup.ps1 [command] [service]
```

**Linux/macOS Bash:**
```bash
./scripts/dev-setup.sh [command] [service]
```

### Commands Reference

| Command | Description |
|---------|-------------|
| `setup` | One-time initial setup |
| `start` | Start all development services |
| `stop` | Stop all development services |
| `restart [service]` | Restart a specific service (default: rails) |
| `status` | Show service status |
| `logs [service]` | Show logs for a service (default: rails) |
| `console` | Open Rails console |
| `migrate` | Run database migrations |
| `seed` | Seed database |
| `reset-db` | Reset database (destructive!) |
| `cleanup` | Stop services and clean up |

### Examples

```bash
# View Rails logs
./scripts/dev-setup.sh logs rails

# View Vite logs  
./scripts/dev-setup.sh logs vite

# Restart just the Rails server
./scripts/dev-setup.sh restart rails

# Open Rails console
./scripts/dev-setup.sh console

# Run migrations
./scripts/dev-setup.sh migrate
```

## 🌐 Service URLs

Once running, access your services at:

- **Rails App**: http://localhost:3000
- **Vite Dev Server**: http://localhost:3036  
- **MailHog (Email Testing)**: http://localhost:8025
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📁 How It Works

### Volume Mounts for Live Reloading
```yaml
volumes:
  - ./:/app:cached              # Your code (live reloading!)
  - node_modules:/app/node_modules  # Cached dependencies
  - bundle_cache:/usr/local/bundle  # Cached gems
```

### Smart Development Dockerfile
The `docker/Dockerfile.dev` is optimized for development:
- Only copies dependency files (Gemfile, package.json) initially
- Uses cached layers for dependencies
- Mounts your actual code as a volume for live changes

### Intelligent Entrypoint
The `docker/entrypoints/dev.sh` script:
- Checks for new dependencies and installs them if needed
- Only precompiles assets when necessary
- Skips unnecessary steps for faster startup

## 🔧 Troubleshooting

### Container Won't Start
```bash
# Check service status
./scripts/dev-setup.sh status

# View logs for specific service
./scripts/dev-setup.sh logs postgres
./scripts/dev-setup.sh logs redis
```

### Code Changes Not Reflected
- Ensure you're using the development setup: `docker-compose.dev.yaml`
- Check that volumes are properly mounted
- Restart the Rails service: `./scripts/dev-setup.sh restart rails`

### Database Issues
```bash
# Reset database (will destroy data!)
./scripts/dev-setup.sh reset-db

# Or just run migrations
./scripts/dev-setup.sh migrate
```

### Performance Issues
- Ensure Docker Desktop has sufficient resources (8GB+ RAM)
- On Windows, consider using WSL2 for better performance
- Check that no other services are using ports 3000, 3036, 5432, 6379

### Clean Slate
```bash
# Complete cleanup and restart
./scripts/dev-setup.sh cleanup
./scripts/dev-setup.sh setup
```

## 📝 Environment Configuration

### Default Development Settings
The system uses optimized development settings in `docker/env.development`:
- Fast asset compilation disabled in development
- Debug logging enabled
- All feature flags enabled for testing
- MailHog for email testing

### Custom Configuration
1. Copy `docker/env.development` to your `.env` file
2. Modify as needed for your specific setup
3. Restart services: `./scripts/dev-setup.sh restart`

## 🆚 Comparison: Before vs After

### Before (Slow Development)
```bash
# Make a small code change
vim app/controllers/api/v1/accounts/contacts_controller.rb

# Rebuild entire container (3-5 minutes)
docker-compose build
docker-compose up

# Wait... wait... wait...
```

### After (Fast Development)
```bash
# Make a small code change
vim app/controllers/api/v1/accounts/contacts_controller.rb

# Change is immediately reflected!
# No rebuild needed! 🎉
```

## 🚢 Moving to Production

This setup is for **development only**. For production deployment:

1. Use your existing production Dockerfile
2. Use the Railway/production docker-compose files
3. Follow your established production deployment process

The development and production environments are completely separate.

## 💡 Tips for Maximum Productivity

1. **Keep Services Running**: Don't stop the entire stack, just restart what you need
2. **Use Logs**: `./scripts/dev-setup.sh logs` to debug issues quickly  
3. **Multiple Terminals**: Keep one terminal for logs, another for commands
4. **Rails Console**: Use `./scripts/dev-setup.sh console` for quick testing
5. **Database Seeding**: Use `./scripts/dev-setup.sh seed` to populate test data

## 🤝 Contributing

If you improve this development setup:
1. Test your changes thoroughly
2. Update this README
3. Submit a pull request

---

**Happy coding! 🎉** 

No more waiting for Docker rebuilds - now you can iterate as fast as you think! 