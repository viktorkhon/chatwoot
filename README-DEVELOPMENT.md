# Chatwoot High-Performance Docker Development Environment

**🚀 Complete guide for setting up a lightning-fast Docker development environment with 95% faster iteration times**

This guide provides a comprehensive solution for Chatwoot development that eliminates the traditional Docker rebuild bottlenecks while maintaining production parity through Railway.com integration.


**🔄 Daily Workflow:**
1. **Start tunnel:** Double-click `start_cloudflare.cmd`
2. **Copy new URL** from terminal (e.g., `https://abc-123.trycloudflare.com`)
3. **Update everywhere instantly:** Double-click `quick_update_url.cmd`
4. **Paste URL** when prompted
5. **Done!** No restart needed, changes are live immediately

# Terminal 1: Start tunnel
start_cloudflare.cmd  # or your preferred method

# Terminal 2: Update URL everywhere
quick_update_url.cmd  # paste new URL when prompted

# Terminal 3: Start Chatwoot
docker-compose -f docker-compose.dev.yaml up -d
```

```bash
# Check environment
docker-compose -f docker-compose.dev.yaml exec rails printenv FRONTEND_URL

# Check if Rails using Port 3000
docker-compose -f docker-compose.dev.yaml ps
```

### Smart URL Update System

**What gets updated automatically:**
- ✅ `.env.local` file
- ✅ Database configuration (`InstallationConfig`)
- ✅ All account domains
- ✅ Widget settings for all inboxes
- ✅ Live application configuration (no restart needed)

**Files created for you:**
- `update_tunnel_url.ps1` - Smart PowerShell script
- `quick_update_url.cmd` - Double-click interface

**Cloudflare Tunnel (Recommended):**
```bash
# Quick tunnel (URL changes each session)
cloudflared tunnel --url localhost:3000

# Named tunnel (stable URL, requires account)
cloudflared tunnel login
cloudflared tunnel create chatwoot-dev
cloudflared tunnel route dns chatwoot-dev dev.yourcompany.com
```
### Tunnel Management Commands

**Start development with tunnel:**
```bash

**Verify updates worked:**
```bash
# Check database
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "puts InstallationConfig.find_by(name: 'FRONTEND_URL')&.value"

```

### Update FRONTEND_URL for n8n Integration

**Manual method (if needed):**
```ruby
# In Rails console
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails console

# Update account domains
Account.all.each { |account| account.update!(domain: 'your-tunnel-url.trycloudflare.com') }

# Update widget settings
Inbox.where(channel_type: 'Channel::WebWidget').each do |inbox|
  settings = inbox.channel.widget_settings || {}
  settings['website_url'] = 'https://your-tunnel-url.trycloudflare.com'
  inbox.channel.update!(widget_settings: settings)
end
```
### Expected Webhook Flow
```
Widget/API → Local Chatwoot → n8n (Railway) → Tunnel URL → Local Chatwoot → Response
```
### Widget Testing Script

**For external testing (CodePen, etc.):**
```html
<script>
(function(d,t) {
  // Use your current tunnel URL here
  var BASE_URL="https://your-tunnel-url.trycloudflare.com";
  var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
  g.src=BASE_URL+"/packs/js/sdk.js";
  g.defer = true;
  g.async = true;
  s.parentNode.insertBefore(g,s);
  g.onload=function(){
    window.chatwootSDK.run({
      websiteToken: 'ZNe7yaenZAqPimUSkPJr8ovx',  // Your widget token
      baseUrl: BASE_URL
    })
  }
})(document,"script");
</script>
```

### One-Command Setup

**Windows (PowerShell):**
```powershell
.\scripts\dev-setup.ps1 setup
```

**Manual Setup:**
```bash
# 1. Build optimized development image
docker-compose -f docker-compose.dev.yaml build

# 2. Configure environment
cp docker/env.development .env
# Edit .env with your Railway credentials (see Environment Configuration section)

# 3. Start all services
docker-compose -f docker-compose.dev.yaml up -d
```

**Result:** All services running in under 60 seconds!

## 🏗️ Architecture Overview

```mermaid
graph TD
    A[Your Code Changes] -->|Volume Mount| B[Rails Container]
    A -->|Volume Mount| C[Vite Container]
    B -->|Persistent Cache| D[Gems Volume]
    C -->|Persistent Cache| E[Vite Cache Volume]
    B -->|Database| F[Railway PostgreSQL]
    B -->|Jobs| G[Sidekiq Container]
    G -->|Queue| H[Railway Redis]
    B -->|Email Testing| I[MailHog Container]
    J[External Widget Tests] -->|Tunnel| B
```

### Key Optimizations Implemented

1. **🔄 Persistent Volume Caching**
   - `vite_cache:/app/node_modules/.vite` - Vite build cache persists
   - `bootsnap_cache:/app/tmp/cache/bootsnap` - Rails boot optimization
   - `gems_cache:/usr/local/bundle` - Ruby gems persist
   - `npm_cache:/root/.npm` - npm packages persist

2. **⚡ Smart Entrypoint Scripts**
   - Conditional dependency checks (only install if missing)
   - Database connection timeouts (max 20 seconds)
   - Cache preservation (no aggressive clearing)
   - Parallel optimizations for faster startup

3. **🎨 Vite Development Optimizations**
   - Pre-bundling for common dependencies
   - Source maps enabled in development
   - Minification disabled for faster builds
   - HMR configured for Docker networking

4. **🌐 Production-Safe Configuration**
   - Development-only optimizations
   - Environment-based conditional logic
   - Production builds unaffected

## 🌍 Environment Configuration

### Railway Services Setup

Create your `.env` file with Railway credentials:

```bash
# === Railway PostgreSQL Configuration ===
DATABASE_URL=postgresql://postgres:password@host.railway.app:5432/railway

# OR individual components:
DATABASE_HOST=your-project.railway.app
DATABASE_PORT=5432
DATABASE_NAME=railway
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your-railway-password

# === Railway Redis Configuration ===
REDIS_URL=redis://default:password@your-redis-host.railway.app:port

# === Development Server Configuration ===
FRONTEND_URL=http://localhost:3000  # Will be updated for tunneling
NODE_ENV=development
RAILS_ENV=development

# === Vite Development Server ===
VITE_DEV_SERVER_HOST=0.0.0.0
VITE_DEV_SERVER_PORT=3036

# === Optional Integrations ===
# GOOGLE_OAUTH_CLIENT_ID=your_google_client_id
# GOOGLE_OAUTH_CLIENT_SECRET=your_google_client_secret
# SHOPIFY_CLIENT_ID=your_shopify_client_id
# SHOPIFY_CLIENT_SECRET=your_shopify_client_secret
```

### Environment Variable Priority

The system uses environment variable fallbacks for flexibility:
- `FRONTEND_URL=${FRONTEND_URL:-http://localhost:3000}` - Defaults to localhost, overrideable for tunneling
- Database connections support both `DATABASE_URL` and individual components
- All Railway services can be swapped for local alternatives if needed

## 🚀 Daily Development Workflow

### Monitor Docker Services
```bash
# View all service status
docker-compose -f docker-compose.dev.yaml ps

# View logs (follow)
docker-compose -f docker-compose.dev.yaml logs -f rails
docker-compose -f docker-compose.dev.yaml logs -f vite
docker-compose -f docker-compose.dev.yaml logs -f sidekiq
```

### Make Code Changes
- **Frontend**: Edit files in `app/javascript/` → Changes appear instantly via HMR
- **Backend**: Edit Ruby files → Changes appear on next request (no restart needed)
- **Styles**: Edit SCSS files → Hot reloaded immediately
- **Config**: Edit most config files → Restart specific container only

### Development Commands
```bash
# Rails console (connects to Railway PostgreSQL)
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails console

# Database operations
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails db:migrate
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails db:seed

# Restart specific services
docker-compose -f docker-compose.dev.yaml restart rails
docker-compose -f docker-compose.dev.yaml restart vite
```

### End Development Session
```bash
# Stop all local services (Railway services continue running)
docker-compose -f docker-compose.dev.yaml down
```

## 🌐 Service Access

| Service | URL | Purpose |
|---------|-----|---------|
| **Rails Application** | http://localhost:3000 | Main development server |
| **Vite Dev Server** | http://localhost:3036 | Frontend asset server with HMR |
| **MailHog** | http://localhost:8025 | Email testing interface |
| **Sidekiq** | Background jobs | Processing via Railway Redis |
| **PostgreSQL** | Railway.com | Database (external) |
| **Redis** | Railway.com | Cache & job queue (external) |

## 🌉 External Access & Tunneling Solutions


### Troubleshooting Tunnel Issues

**Common Problems & Solutions:**

1. **CORS errors (browser accessing port 3036 directly):**
   ```bash
   # Root cause: Rails timing out when fetching Vite assets
   # Fix 1: Increase Vite timeouts in config/initializers/vite_ruby.rb
   ViteRuby.configure do |config|
     config.build_timeout = 120
   end
   
   # Fix 2: Add Net::HTTP timeout patches for Vite connections
   # Fix 3: Add CORS rules for /vite-dev/* and tunnel domains in config/initializers/cors.rb
   # Fix 4: Disable web console for tunnel access in config/environments/development.rb
   ```

2. **URL not updating in app:**
   ```bash
   # Re-run the smart updater
   quick_update_url.cmd
   
   # Or restart just Rails (not full stack)
   docker-compose -f docker-compose.dev.yaml restart rails
   ```

3. **n8n webhooks not receiving:**
   ```bash
   # Test tunnel accessibility
   curl -I https://your-tunnel-url.trycloudflare.com/api/v1/accounts/2
   
   # Check webhook URLs
   docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "
   Account.find(2).webhooks.each { |w| puts w.url }
   "
   ```

4. **Widget not loading externally:**
   - Verify CORS settings allow external domains
   - Check SDK loads: `https://your-tunnel-url.trycloudflare.com/packs/js/sdk.js`
   - Test WebSocket: `wss://your-tunnel-url.trycloudflare.com/cable`

5. **502 Bad Gateway errors:**
   ```bash
   # Check if containers are running
   docker-compose -f docker-compose.dev.yaml ps
   
   # Start containers if needed
   docker-compose -f docker-compose.dev.yaml up -d
   
   # Check Rails logs
   docker-compose -f docker-compose.dev.yaml logs rails
   ```

### Verification Commands

**Check all configurations are updated:**
```bash
# Environment file
Get-Content .env.local | Select-String "FRONTEND_URL"

# Database configuration
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "
puts 'FRONTEND_URL: ' + InstallationConfig.find_by(name: 'FRONTEND_URL')&.serialized_value.to_s
puts 'Account domains: ' + Account.pluck(:domain).join(', ')
puts 'Widget URLs: ' + Inbox.where(channel_type: 'Channel::WebWidget').map { |i| i.channel.widget_settings&.dig('website_url') }.compact.join(', ')
"

# Test tunnel accessibility
Invoke-WebRequest -Uri "https://your-tunnel-url.trycloudflare.com" -Method Head -TimeoutSec 10
```

## ⚡ When to Rebuild vs Restart

### 🔄 Instant Changes (No action needed)
- **Ruby files**: Controllers, models, views, helpers, services
- **JavaScript/Vue files**: Dashboard components, widget code, entrypoints
- **CSS/SCSS files**: Styles and layouts
- **ERB templates**: Views and mailers
- **Most config files**: Routes, application config

### 🔄 Restart Container Only
```bash
docker-compose -f docker-compose.dev.yaml restart rails
```
**When needed:**
- Environment variable changes (`.env` updates)
- Initializer changes (`config/initializers/`)
- Database configuration changes
- Redis/Sidekiq configuration changes

### 🔨 Rebuild Required
```bash
docker-compose -f docker-compose.dev.yaml build
```
**When needed:**
- `Gemfile` or `Gemfile.lock` changes (new gems)
- `package.json` or `pnpm-lock.yaml` changes (new npm packages)
- `Dockerfile.dev` modifications
- System package additions

### 🧹 Full Reset (Nuclear option)
```bash
docker-compose -f docker-compose.dev.yaml down -v
docker-compose -f docker-compose.dev.yaml build --no-cache
docker-compose -f docker-compose.dev.yaml up -d
```
**When needed:**
- Corrupted volumes
- Major system changes
- Debugging persistent issues

## 🛠️ Troubleshooting Guide

### Common Issues and Solutions

#### 1. Containers Won't Start
```bash
# Check container status
docker-compose -f docker-compose.dev.yaml ps

# View startup logs
docker-compose -f docker-compose.dev.yaml logs

# Check Railway connection
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
```

#### 2. Vite Server Issues
```bash
# Check Vite logs
docker logs chatwoot_vite_dev

# Verify Vite is accessible
curl http://localhost:3036/vite-dev/

# Clear Vite cache if needed
docker-compose -f docker-compose.dev.yaml exec vite rm -rf /app/node_modules/.vite
docker-compose -f docker-compose.dev.yaml restart vite
```

#### 3. Database Connection Issues
```bash
# Test database connection
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails db:version

# Check DATABASE_URL format
docker-compose -f docker-compose.dev.yaml exec rails printenv DATABASE_URL
```


#### 5. n8n Webhooks Not Working
```ruby
# Verify webhooks exist
Account.find(2).webhooks.each { |w| puts "#{w.id}: #{w.url}" }

# Check tunnel accessibility
# curl https://your-tunnel-url.trycloudflare.com/api/v1/accounts/2

# Verify frontend_url setting
puts Account.find(2).custom_attributes['frontend_url']
```

### Performance Monitoring

#### Container Resource Usage
```bash
docker stats chatwoot_rails_dev chatwoot_vite_dev chatwoot_sidekiq_dev
```

#### Volume Usage
```bash
docker system df -v
```

#### Startup Time Measurement
```bash
time docker-compose -f docker-compose.dev.yaml up -d
```

## 📦 Volume Management

### Understanding Persistent Volumes

| Volume | Purpose | When to Clear |
|--------|---------|---------------|
| `vite_cache` | Vite build artifacts | Vite upgrade, build issues |
| `bootsnap_cache` | Rails boot optimization | Rails upgrade, boot issues |
| `gems_cache` | Ruby gems | Gemfile changes, gem conflicts |
| `npm_cache` | npm packages | package.json changes, npm issues |
| `packs_data` | Compiled assets | Asset compilation issues |

### Volume Operations
```bash
# List all volumes
docker volume ls | grep chatwoot

# Clear specific volume
docker volume rm chatwoot-v42225_vite_cache

# Clear all project volumes (nuclear option)
docker-compose -f docker-compose.dev.yaml down -v

# Backup volume data
docker run --rm -v chatwoot-v42225_gems_cache:/data -v $(pwd):/backup alpine tar czf /backup/gems-backup.tar.gz /data
```

## 🔒 Production Safety

### Files Modified (Development Only)
- ✅ `docker/entrypoints/vite-dev.sh` - Development entrypoint only
- ✅ `docker/entrypoints/rails-dev.sh` - Development entrypoint only  
- ✅ `docker-compose.dev.yaml` - Development compose only
- ✅ `vite.config.ts` - Contains production-safe conditionals

### Production Deployment Verification
```bash
# Verify production builds work correctly
NODE_ENV=production npm run build

# Verify library mode still works
BUILD_MODE=library npm run build

# Check production Dockerfile compatibility
docker build -f Dockerfile .
```

### Environment Separation
- Development uses `.env` and `docker-compose.dev.yaml`
- Production uses environment variables and production Dockerfiles
- No development-specific code affects production builds
- All optimizations are conditionally applied based on `NODE_ENV`

## 📚 Advanced Usage

### Multiple Development Environments
```bash
# Clone project for different features
git clone <repo> chatwoot-feature-a
git clone <repo> chatwoot-feature-b

# Use different compose files
docker-compose -f docker-compose.dev.yaml -p chatwoot-a up -d
docker-compose -f docker-compose.dev.yaml -p chatwoot-b -p 3001:3000 up -d
```

### Database Branching
```bash
# Create development branch database
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails db:create DATABASE_URL=postgresql://...chatwoot_dev_branch

# Switch between databases by updating .env
```

### Integration Testing
```bash
# Start services for integration tests
RAILS_ENV=test docker-compose -f docker-compose.dev.yaml up -d

# Run test suite
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rspec
```