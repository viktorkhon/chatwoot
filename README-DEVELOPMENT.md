# Chatwoot Fast Development Environment

This guide explains how to set up a **fast iteration Docker development environment** for Chatwoot that solves the problem of slow rebuild times when making small code changes.

**🚀 This setup uses Railway.com for PostgreSQL and Redis services, eliminating the need for local database containers while maintaining fast development iteration.**

## 🚀 Quick Start

### 1. Prerequisites
- Docker Desktop installed and running
- Git (for cloning the repository)
- At least 4GB RAM recommended (reduced since we're using Railway for databases)
- Railway.com account with PostgreSQL and Redis services set up

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
- Create your `.env` file from `docker/env.development`
- Start local services (Vite, Rails, Sidekiq, MailHog)
- Connect to your Railway PostgreSQL and Redis services

### 3. Configure Railway Services

Make sure your `.env` file has the correct Railway credentials:

```bash
# === Database Configuration (Railway PostgreSQL) ===
DATABASE_HOST=your-railway-postgres-host
DATABASE_PORT=your-railway-postgres-port
DATABASE_NAME=railway
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your-railway-postgres-password

# === Redis Configuration (Railway Redis) ===
REDIS_URL=redis://default:your-redis-password@your-redis-host:your-redis-port
```

### 4. Daily Development Workflow

```bash
# Start your development environment
./scripts/dev-setup.sh start

# Make your code changes (they'll be reflected immediately!)

# View logs if needed
./scripts/dev-setup.sh logs

# Stop when done (Railway services keep running)
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

### 🌩️ **Railway Integration**
- Uses your existing Railway PostgreSQL and Redis services
- Consistent data between development and production
- No local database overhead - saves system resources
- Share the same database with your team (optional)

### 🔧 **Minimal Local Services**
- Only runs Rails, Sidekiq, Vite, and MailHog locally
- PostgreSQL and Redis run on Railway.com
- Reduced memory usage and faster startup

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

# Open Rails console (connects to Railway PostgreSQL)
./scripts/dev-setup.sh console

# Run migrations on Railway PostgreSQL
./scripts/dev-setup.sh migrate
```

## 🌐 Service URLs

Once running, access your services at:

- **Rails App**: http://localhost:3000
- **Vite Dev Server**: http://localhost:3036  
- **MailHog (Email Testing)**: http://localhost:8025
- **PostgreSQL**: Railway.com (external)
- **Redis**: Railway.com (external)

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

### Railway Integration
- Connects to external PostgreSQL and Redis on Railway.com
- No local database containers needed
- Intelligent connection testing in entrypoint script

## 🔧 Troubleshooting

### Container Won't Start
```bash
# Check service status
./scripts/dev-setup.sh status

# View logs for specific service
./scripts/dev-setup.sh logs rails
```

### Database Connection Issues
```bash
# Test database connection
./scripts/dev-setup.sh logs rails

# Check your .env file has correct Railway credentials:
# - DATABASE_HOST
# - DATABASE_PORT  
# - DATABASE_PASSWORD
```

### Redis Connection Issues
```bash
# Check Redis URL format in .env:
# REDIS_URL=redis://default:password@host:port

# View connection logs
./scripts/dev-setup.sh logs rails
```

### Code Changes Not Reflected
- Ensure you're using the development setup: `docker-compose.dev.yaml`
- Check that volumes are properly mounted
- Restart the Rails service: `./scripts/dev-setup.sh restart rails`

### Performance Issues
- Ensure Docker Desktop has sufficient resources (4GB+ RAM)
- On Windows, consider using WSL2 for better performance
- Check that no other services are using ports 3000, 3036, 8025

### Clean Slate
```bash
# Complete cleanup and restart
./scripts/dev-setup.sh cleanup
./scripts/dev-setup.sh setup
```

## 📝 Environment Configuration

### Railway Configuration Required
Update your `.env` file with Railway service details:

```bash
# Get these from your Railway project dashboard
DATABASE_HOST=your-project.railway.app
DATABASE_PORT=5432
DATABASE_NAME=railway  
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your-password

# Redis URL from Railway
REDIS_URL=redis://default:password@host:port
```

### Local Development Optimizations
The system includes optimized development settings:
- Fast asset compilation disabled in development
- Debug logging enabled
- All feature flags enabled for testing
- MailHog for local email testing

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

The development and production environments can share the same Railway services or use separate instances.

## 🌩️ Railway Benefits

1. **Consistent Data**: Same database as your deployed application
2. **Team Collaboration**: Share database with team members
3. **Backup & Monitoring**: Railway handles database backups and monitoring
4. **No Local Resources**: Saves RAM and CPU on your development machine
5. **Production Parity**: Same database engine and version as production

## 💡 Tips for Maximum Productivity

1. **Keep Services Running**: Don't stop the entire stack, just restart what you need
2. **Use Logs**: `./scripts/dev-setup.sh logs` to debug issues quickly  
3. **Multiple Terminals**: Keep one terminal for logs, another for commands
4. **Rails Console**: Use `./scripts/dev-setup.sh console` for quick testing
5. **Database Seeding**: Use `./scripts/dev-setup.sh seed` to populate test data
6. **Railway Dashboard**: Monitor your database and Redis usage via Railway dashboard

## 🤝 Contributing

If you improve this development setup:
1. Test your changes thoroughly
2. Update this README
3. Submit a pull request

---

**Happy coding! 🎉** 

No more waiting for Docker rebuilds, and no local database overhead - now you can iterate as fast as you think while using production-grade Railway services! 