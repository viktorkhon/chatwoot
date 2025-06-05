# Tunnel Alternatives Manager for Chatwoot Development
# Provides easy switching between ngrok alternatives with better limits

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pinggy", "cloudflare", "tailscale", "localtunnel", "localhost.run", "list", "compare")]
    [string]$Provider,
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 3000,
    
    [Parameter(Mandatory=$false)]
    [string]$Subdomain,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

function Show-Help {
    Write-Host "=== Chatwoot Tunnel Alternatives Manager ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\tunnel-alternatives.ps1 -Provider <provider> [-Port <port>] [-Subdomain <subdomain>]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Providers:" -ForegroundColor Green
    Write-Host "  pinggy       - Unlimited bandwidth, no downloads required (RECOMMENDED)" -ForegroundColor White
    Write-Host "  cloudflare   - Free, enterprise-grade, DDoS protection" -ForegroundColor White
    Write-Host "  tailscale    - Secure VPN-based tunneling" -ForegroundColor White
    Write-Host "  localtunnel  - Simple npm-based tunneling" -ForegroundColor White
    Write-Host "  localhost.run- Simplest SSH-based tunneling" -ForegroundColor White
    Write-Host "  list         - Show all available alternatives" -ForegroundColor White
    Write-Host "  compare      - Show comparison table" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  .\tunnel-alternatives.ps1 -Provider pinggy" -ForegroundColor Gray
    Write-Host "  .\tunnel-alternatives.ps1 -Provider cloudflare -Port 3000" -ForegroundColor Gray
    Write-Host "  .\tunnel-alternatives.ps1 -Provider pinggy -Subdomain myapp" -ForegroundColor Gray
    Write-Host ""
}

function Show-Comparison {
    Write-Host "=== Tunnel Alternatives Comparison ===" -ForegroundColor Cyan
    Write-Host ""
    
    $table = @"
╔═══════════════╦══════════════════╦═══════════════╦═══════════╦═══════════════╦═════════════╗
║ Service       ║ Free Bandwidth   ║ Custom Domain ║ Timeout   ║ Authentication║ Price       ║
╠═══════════════╬══════════════════╬═══════════════╬═══════════╬═══════════════╬═════════════╣
║ ngrok         ║ Limited requests ║ No            ║ 8 hours   ║ Yes           ║ $10/month   ║
║ Pinggy ⭐     ║ UNLIMITED        ║ Pro only      ║ 60 min    ║ Yes           ║ $2.50/month ║
║ Cloudflare    ║ Unlimited        ║ Yes           ║ No limit  ║ Yes           ║ FREE        ║
║ Tailscale     ║ Unlimited        ║ No            ║ No limit  ║ Yes           ║ Free (3u)   ║
║ LocalTunnel   ║ Unlimited        ║ Limited       ║ No limit  ║ No            ║ FREE        ║
║ localhost.run ║ Unlimited        ║ No            ║ No limit  ║ No            ║ FREE        ║
╚═══════════════╩══════════════════╩═══════════════╩═══════════╩═══════════════╩═════════════╝
"@
    
    Write-Host $table -ForegroundColor White
    Write-Host ""
    Write-Host "⭐ RECOMMENDED: Pinggy - Best balance of features and limits" -ForegroundColor Yellow
    Write-Host "🏢 PRODUCTION: Cloudflare - Enterprise-grade, completely free" -ForegroundColor Green
    Write-Host "👥 TEAMS: Tailscale - Secure, great for collaboration" -ForegroundColor Blue
    Write-Host ""
}

function Show-Providers {
    Write-Host "=== Available Tunnel Providers ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. PINGGY (⭐ RECOMMENDED)" -ForegroundColor Yellow
    Write-Host "   • Unlimited bandwidth, no HTTP request limits" -ForegroundColor Green
    Write-Host "   • No download required - single SSH command" -ForegroundColor Green
    Write-Host "   • Built-in web debugger and request inspector" -ForegroundColor Green
    Write-Host "   • Custom domains available (Pro: $2.50/month)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "2. CLOUDFLARE TUNNEL" -ForegroundColor Yellow
    Write-Host "   • Completely free with unlimited bandwidth" -ForegroundColor Green
    Write-Host "   • Enterprise-grade DDoS protection" -ForegroundColor Green
    Write-Host "   • Zero Trust security features" -ForegroundColor Green
    Write-Host "   • Custom domains included free" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "3. TAILSCALE FUNNEL" -ForegroundColor Yellow
    Write-Host "   • Free for personal use (up to 3 users)" -ForegroundColor Green
    Write-Host "   • VPN-grade security and encryption" -ForegroundColor Green
    Write-Host "   • Great for team development" -ForegroundColor Green
    Write-Host "   • No bandwidth limits" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "4. LOCALTUNNEL" -ForegroundColor Yellow
    Write-Host "   • NPM package, can be used as JS library" -ForegroundColor Green
    Write-Host "   • Simple setup with Node.js" -ForegroundColor Green
    Write-Host "   • Completely free" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "5. LOCALHOST.RUN" -ForegroundColor Yellow
    Write-Host "   • Simplest possible setup - single SSH command" -ForegroundColor Green
    Write-Host "   • No installation required" -ForegroundColor Green
    Write-Host "   • Completely free" -ForegroundColor Green
    Write-Host ""
}

function Start-PinggyTunnel {
    Write-Host "🚀 Starting Pinggy tunnel..." -ForegroundColor Green
    Write-Host "   ✅ Unlimited bandwidth" -ForegroundColor Green
    Write-Host "   ✅ No HTTP request limits" -ForegroundColor Green
    Write-Host "   ✅ Built-in web debugger" -ForegroundColor Green
    Write-Host ""
    
    if ($Subdomain) {
        Write-Host "⚠️  Custom subdomains require Pinggy Pro ($2.50/month)" -ForegroundColor Yellow
        $command = "ssh -p 443 -R0:localhost:$Port -t $Subdomain@a.pinggy.io"
    } else {
        $command = "ssh -p 443 -R0:localhost:$Port a.pinggy.io"
    }
    
    Write-Host "Command: $command" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Tips:" -ForegroundColor Yellow
    Write-Host "   • Press Enter if prompted for password" -ForegroundColor Gray
    Write-Host "   • Web debugger will be available at http://localhost:4300" -ForegroundColor Gray
    Write-Host "   • Copy the public URL and update FRONTEND_URL in .env" -ForegroundColor Gray
    Write-Host ""
    
    Invoke-Expression $command
}

function Start-CloudflareTunnel {
    Write-Host "☁️  Starting Cloudflare tunnel..." -ForegroundColor Green
    Write-Host "   ✅ Completely free" -ForegroundColor Green
    Write-Host "   ✅ DDoS protection" -ForegroundColor Green
    Write-Host "   ✅ Custom domains" -ForegroundColor Green
    Write-Host ""
    
    # Check if cloudflared is installed
    try {
        $null = Get-Command cloudflared -ErrorAction Stop
        Write-Host "✅ cloudflared found" -ForegroundColor Green
    } catch {
        Write-Host "❌ cloudflared not found. Installing..." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install cloudflared:" -ForegroundColor Yellow
        Write-Host "   Option 1: winget install --id Cloudflare.cloudflared" -ForegroundColor Cyan
        Write-Host "   Option 2: Download from https://github.com/cloudflare/cloudflared/releases" -ForegroundColor Cyan
        Write-Host ""
        return
    }
    
    Write-Host "Running: cloudflared tunnel --url http://localhost:$Port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 For persistent tunnels:" -ForegroundColor Yellow
    Write-Host "   1. cloudflared tunnel login" -ForegroundColor Gray
    Write-Host "   2. cloudflared tunnel create chatwoot-dev" -ForegroundColor Gray
    Write-Host "   3. cloudflared tunnel run chatwoot-dev" -ForegroundColor Gray
    Write-Host ""
    
    Start-Process -FilePath "cloudflared" -ArgumentList "tunnel", "--url", "http://localhost:$Port" -NoNewWindow -Wait
}

function Start-TailscaleTunnel {
    Write-Host "🔒 Starting Tailscale Funnel..." -ForegroundColor Green
    Write-Host "   ✅ VPN-grade security" -ForegroundColor Green
    Write-Host "   ✅ Great for teams" -ForegroundColor Green
    Write-Host "   ✅ No bandwidth limits" -ForegroundColor Green
    Write-Host ""
    
    # Check if Tailscale is installed
    try {
        $null = Get-Command tailscale -ErrorAction Stop
        Write-Host "✅ Tailscale found" -ForegroundColor Green
    } catch {
        Write-Host "❌ Tailscale not found. Please install from https://tailscale.com/download" -ForegroundColor Red
        return
    }
    
    Write-Host "Running: tailscale funnel $Port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 First time setup:" -ForegroundColor Yellow
    Write-Host "   1. Sign up at https://tailscale.com" -ForegroundColor Gray
    Write-Host "   2. tailscale up" -ForegroundColor Gray
    Write-Host "   3. Enable Funnel in admin console" -ForegroundColor Gray
    Write-Host ""
    
    Start-Process -FilePath "tailscale" -ArgumentList "funnel", $Port -NoNewWindow -Wait
}

function Start-LocalTunnel {
    Write-Host "📦 Starting LocalTunnel..." -ForegroundColor Green
    Write-Host "   ✅ NPM-based" -ForegroundColor Green
    Write-Host "   ✅ Completely free" -ForegroundColor Green
    Write-Host "   ✅ Simple setup" -ForegroundColor Green
    Write-Host ""
    
    # Check if Node.js is installed
    try {
        $null = Get-Command npm -ErrorAction Stop
        Write-Host "✅ Node.js/npm found" -ForegroundColor Green
    } catch {
        Write-Host "❌ Node.js not found. Please install from https://nodejs.org" -ForegroundColor Red
        return
    }
    
    Write-Host "Installing/running localtunnel..." -ForegroundColor Cyan
    
    if ($Subdomain) {
        $command = "npx localtunnel --port $Port --subdomain $Subdomain"
    } else {
        $command = "npx localtunnel --port $Port"
    }
    
    Write-Host "Command: $command" -ForegroundColor Cyan
    Write-Host ""
    
    Invoke-Expression $command
}

function Start-LocalhostRun {
    Write-Host "🏃 Starting localhost.run..." -ForegroundColor Green
    Write-Host "   ✅ Simplest setup" -ForegroundColor Green
    Write-Host "   ✅ No installation" -ForegroundColor Green
    Write-Host "   ✅ SSH-based" -ForegroundColor Green
    Write-Host ""
    
    $command = "ssh -R 80:localhost:$Port localhost.run"
    
    Write-Host "Command: $command" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Tips:" -ForegroundColor Yellow
    Write-Host "   • Press Enter if prompted for password" -ForegroundColor Gray
    Write-Host "   • URL will be displayed in terminal" -ForegroundColor Gray
    Write-Host ""
    
    Invoke-Expression $command
}

function Update-EnvFile {
    param([string]$Url)
    
    if (Test-Path ".env") {
        Write-Host "📝 Updating .env file..." -ForegroundColor Green
        
        $content = Get-Content ".env"
        $updatedContent = @()
        $foundFrontendUrl = $false
        
        foreach ($line in $content) {
            if ($line -match "^FRONTEND_URL=") {
                $updatedContent += "FRONTEND_URL=$Url"
                $foundFrontendUrl = $true
                Write-Host "   Updated FRONTEND_URL=$Url" -ForegroundColor Green
            } else {
                $updatedContent += $line
            }
        }
        
        if (-not $foundFrontendUrl) {
            $updatedContent += "FRONTEND_URL=$Url"
            Write-Host "   Added FRONTEND_URL=$Url" -ForegroundColor Green
        }
        
        $updatedContent | Set-Content ".env"
        Write-Host "✅ Environment updated successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  .env file not found. Please manually set FRONTEND_URL=$Url" -ForegroundColor Yellow
    }
}

# Main execution
if ($Help) {
    Show-Help
    return
}

switch ($Provider) {
    "list" {
        Show-Providers
    }
    "compare" {
        Show-Comparison
    }
    "pinggy" {
        Write-Host "=== Switching from ngrok to Pinggy ===" -ForegroundColor Cyan
        Write-Host "✅ Eliminates HTTP request limits" -ForegroundColor Green
        Write-Host "✅ Unlimited bandwidth" -ForegroundColor Green
        Write-Host "✅ No interstitial warning pages" -ForegroundColor Green
        Write-Host ""
        Start-PinggyTunnel
    }
    "cloudflare" {
        Write-Host "=== Switching from ngrok to Cloudflare Tunnel ===" -ForegroundColor Cyan
        Write-Host "✅ Completely free with no limits" -ForegroundColor Green
        Write-Host "✅ Enterprise-grade features" -ForegroundColor Green
        Write-Host "✅ DDoS protection included" -ForegroundColor Green
        Write-Host ""
        Start-CloudflareTunnel
    }
    "tailscale" {
        Write-Host "=== Switching from ngrok to Tailscale Funnel ===" -ForegroundColor Cyan
        Write-Host "✅ VPN-grade security" -ForegroundColor Green
        Write-Host "✅ Perfect for team development" -ForegroundColor Green
        Write-Host "✅ No bandwidth limits" -ForegroundColor Green
        Write-Host ""
        Start-TailscaleTunnel
    }
    "localtunnel" {
        Write-Host "=== Switching from ngrok to LocalTunnel ===" -ForegroundColor Cyan
        Write-Host "✅ NPM-based, can be used as library" -ForegroundColor Green
        Write-Host "✅ Completely free" -ForegroundColor Green
        Write-Host "✅ Good for Node.js projects" -ForegroundColor Green
        Write-Host ""
        Start-LocalTunnel
    }
    "localhost.run" {
        Write-Host "=== Switching from ngrok to localhost.run ===" -ForegroundColor Cyan
        Write-Host "✅ Simplest possible setup" -ForegroundColor Green
        Write-Host "✅ No installation required" -ForegroundColor Green
        Write-Host "✅ Completely free" -ForegroundColor Green
        Write-Host ""
        Start-LocalhostRun
    }
}

Write-Host ""
Write-Host "💡 Remember to:" -ForegroundColor Yellow
Write-Host "   1. Copy the tunnel URL from the output above" -ForegroundColor Gray
Write-Host "   2. Update FRONTEND_URL in your .env file" -ForegroundColor Gray
Write-Host "   3. Restart your Docker containers if needed" -ForegroundColor Gray
Write-Host ""
Write-Host "🔄 To restart containers: docker-compose -f docker-compose.dev.yaml restart" -ForegroundColor Cyan 