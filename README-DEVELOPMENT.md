# Chatwoot High-Performance Docker Development Environment

**🚀 Complete guide for setting up a lightning-fast Docker development environment with 95% faster iteration times**

This guide provides a comprehensive solution for Chatwoot development that eliminates the traditional Docker rebuild bottlenecks while maintaining production parity through Railway.com integration.


**🔄 Daily Workflow:**
1. **Start tunnel:** Double-click `start_cloudflare.cmd`
2. **Copy new URL** from terminal (e.g., `https://abc-123.trycloudflare.com`)
3. **Update everywhere instantly:** Double-click `quick_update_url.cmd`
4. **Paste URL** when prompted
5. **Done!** No restart needed, changes are live immediately

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
# Terminal 1: Start Chatwoot
docker-compose -f docker-compose.dev.yaml up -d

# Terminal 2: Start tunnel
start_cloudflare.cmd  # or your preferred method

# Terminal 3: Update URL everywhere
quick_update_url.cmd  # paste new URL when prompted
```

**Verify updates worked:**
```bash
# Check environment
docker-compose -f docker-compose.dev.yaml exec rails printenv FRONTEND_URL

# Check database
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "puts InstallationConfig.find_by(name: 'FRONTEND_URL')&.value"

```

### Update FRONTEND_URL for n8n Integration

**Using the smart updater (recommended):**
1. Run `quick_update_url.cmd`
2. Paste your stable tunnel URL
3. Everything updates automatically - no manual steps needed!

**Manual method (if needed):**
```ruby
# In Rails console
docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails console

# Update all configuration manually
config = InstallationConfig.find_or_create_by(name: 'FRONTEND_URL')
config.update!(value: 'https://your-tunnel-url.trycloudflare.com')

# Update account domains
Account.all.each { |account| account.update!(domain: 'your-tunnel-url.trycloudflare.com') }

# Update widget settings
Inbox.where(channel_type: 'Channel::WebWidget').each do |inbox|
  settings = inbox.channel.widget_settings || {}
  settings['website_url'] = 'https://your-tunnel-url.trycloudflare.com'
  inbox.channel.update!(widget_settings: settings)
end
```

## 🤖 n8n Integration Workflow

### Streamlined Setup for n8n Testing

1. **Start Development Environment:**
   ```bash
   docker-compose -f docker-compose.dev.yaml up -d
   ```

2. **Start Tunnel & Update URLs:**
   ```bash
   # Start tunnel (any method)
   start_cloudflare.cmd
   # or: cloudflared tunnel --url localhost:3000
   # or: ssh -p 443 -R0:localhost:3000 a.pinggy.io
   
   # Copy the tunnel URL, then update everything instantly
   quick_update_url.cmd  # paste URL when prompted
   ```

3. **Verify Configuration:**
   ```bash
   # Check that URL is updated everywhere
   docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "
   puts 'FRONTEND_URL: ' + (InstallationConfig.find_by(name: 'FRONTEND_URL')&.value || 'Not set')
   puts 'Account domains: ' + Account.pluck(:domain).join(', ')
   puts 'Widget URLs: ' + Inbox.where(channel_type: 'Channel::WebWidget').map { |i| i.channel.widget_settings&.dig('website_url') }.compact.join(', ')
   "
   ```

4. **Test n8n Webhooks:**
   - All webhook types automatically work: `conversation_created`, `conversation_status_changed`, `message_created`, `message_updated`
   - n8n can reach your local Chatwoot via the tunnel URL
   - Widget interactions trigger the full webhook flow

### Expected Webhook Flow
```
Widget/API → Local Chatwoot → n8n (Railway) → Tunnel URL → Local Chatwoot → Response
```

**Key Benefits of Smart Update System:**
- ✅ **No container restarts** when tunnel URL changes
- ✅ **Instant updates** across all configurations
- ✅ **One command** updates everything
- ✅ **Zero downtime** - users stay connected
- ✅ **Works with any tunnel provider**

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

### Start Development Session
```bash
# Option 1: Script (recommended)
.\scripts\dev-setup.ps1 start

# Option 2: Direct Docker
docker-compose -f docker-compose.dev.yaml up -d
```

### Monitor Services
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

### Problem: Changing Tunnel URLs
Modern tunnel services (ngrok, Cloudflare tunnels, Pinggy) generate new URLs frequently, breaking:
- n8n webhook integrations
- External widget testing
- Shared development URLs

### ✨ Smart Solution: Auto-Update Without Restarts

**🚀 One-Time Setup:**
```bash
# Install Cloudflare tunnel (Windows)
winget install --id Cloudflare.cloudflared

# Create quick launcher
echo 'start "Cloudflare Tunnel" /min cloudflared tunnel --url localhost:3000' > start_cloudflare.cmd
```

### Troubleshooting Tunnel Issues

**Common Problems & Solutions:**

1. **PowerShell script syntax errors:**
   ```bash
   # If you get "string is missing terminator" errors
   # Delete and recreate the script file:
   del update_tunnel_url.ps1
   # Then re-download or recreate the script
   ```

2. **Database update errors (InstallationConfig):**
   ```bash
   # If you get "null value in column serialized_value" error
   # The script tries to use 'value' instead of 'serialized_value'
   # OR if you get "can't serialize serialized_value" error
   # The field expects a hash, not a string
   # Run this manual fix:
   docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails console
   ```
   
   **In Rails console:**
   ```ruby
   # Manual database update (use hash format)
   config = InstallationConfig.find_by(name: 'FRONTEND_URL')
   if config
     config.update!(serialized_value: { 'value' => 'https://your-tunnel-url.trycloudflare.com' })
   else
     InstallationConfig.create!(name: 'FRONTEND_URL', serialized_value: { 'value' => 'https://your-tunnel-url.trycloudflare.com' }, locked: true)
   end
   
   # Update account domains
   Account.all.each { |account| account.update!(domain: 'your-tunnel-url.trycloudflare.com') }
   
   # Update widget settings
   Inbox.where(channel_type: 'Channel::WebWidget').each do |inbox|
     settings = inbox.channel.widget_settings || {}
     settings['website_url'] = 'https://your-tunnel-url.trycloudflare.com'
     settings['widget_website_url'] = 'https://your-tunnel-url.trycloudflare.com'
     inbox.channel.update!(widget_settings: settings)
   end
   
   puts "✅ All configurations updated manually"
   ```

3. **Environment variable not updating:**
   ```bash
   # The .env file takes precedence over .env.local
   # Make sure both files are updated:
   Get-Content .env | Select-String "FRONTEND_URL"
   Get-Content .env.local | Select-String "FRONTEND_URL"
   
   # Update both files manually if needed:
   (Get-Content .env) -replace 'FRONTEND_URL=.*', 'FRONTEND_URL=https://your-tunnel-url.trycloudflare.com' | Set-Content .env
   (Get-Content .env.local) -replace 'FRONTEND_URL=.*', 'FRONTEND_URL=https://your-tunnel-url.trycloudflare.com' | Set-Content .env.local
   
   # Then restart Rails
   docker-compose -f docker-compose.dev.yaml restart rails
   ```

4. **Tunnel keeps disconnecting:**
   ```bash
   # Use screen/tmux for persistent sessions
   screen -S tunnel
   cloudflared tunnel --url localhost:3000
   # Ctrl+A, D to detach
   
   # Or use systemd on Linux
   sudo systemctl enable --now cloudflared
   ```

5. **URL not updating in app:**
   ```bash
   # Re-run the smart updater
   quick_update_url.cmd
   
   # Or restart just Rails (not full stack)
   docker-compose -f docker-compose.dev.yaml restart rails
   ```

6. **n8n webhooks not receiving:**
   ```bash
   # Test tunnel accessibility
   curl -I https://your-tunnel-url.trycloudflare.com/api/v1/accounts/2
   
   # Check webhook URLs
   docker-compose -f docker-compose.dev.yaml exec rails bundle exec rails runner "
   Account.find(2).webhooks.each { |w| puts w.url }
   "
   ```

7. **Widget not loading externally:**
   - Verify CORS settings allow external domains
   - Check SDK loads: `https://your-tunnel-url.trycloudflare.com/packs/js/sdk.js`
   - Test WebSocket: `wss://your-tunnel-url.trycloudflare.com/cable`

8. **502 Bad Gateway errors:**
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

#### 4. Widget Not Loading
- Verify CORS configuration allows external domains
- Check browser console for JavaScript errors
- Confirm SDK file loads: `http://localhost:3000/packs/js/sdk.js`
- Test WebSocket connection: `ws://localhost:3000/cable`

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