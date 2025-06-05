param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status", "url", "setup")]
    [string]$Action
)

$tunnelName = "chatwoot-tunnel"
$port = 3000

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green }
        "Error" { Write-Host "[$timestamp] ❌ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠️  $Message" -ForegroundColor Yellow }
        default { Write-Host "[$timestamp] 🔧 $Message" -ForegroundColor Cyan }
    }
}

function Test-PM2Installed {
    try {
        $null = Get-Command pm2 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-PM2 {
    Write-Status "Installing PM2 globally..." "Info"
    try {
        npm install -g pm2
        Write-Status "PM2 installed successfully" "Success"
        return $true
    }
    catch {
        Write-Status "Failed to install PM2: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Create-EcosystemConfig {
    $configContent = @"
module.exports = {
  apps: [{
    name: '$tunnelName',
    script: 'npx',
    args: 'cloudflared tunnel --url localhost:$port',
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    restart_delay: 5000,
    max_restarts: 10,
    env: {
      NODE_ENV: 'development'
    },
    log_file: './logs/tunnel.log',
    out_file: './logs/tunnel-out.log',
    error_file: './logs/tunnel-error.log',
    time: true,
    merge_logs: true
  }]
};
"@

    if (!(Test-Path "logs")) {
        New-Item -ItemType Directory -Path "logs" -Force | Out-Null
        Write-Status "Created logs directory" "Success"
    }

    Set-Content -Path "ecosystem.config.js" -Value $configContent
    Write-Status "Created ecosystem.config.js" "Success"
}

function Start-Tunnel {
    Write-Status "Starting persistent tunnel on port $port..." "Info"
    
    try {
        # Check if tunnel is already running
        $status = pm2 list --silent | ConvertFrom-Json
        $existingApp = $status | Where-Object { $_.name -eq $tunnelName }
        
        if ($existingApp -and $existingApp.pm2_env.status -eq "online") {
            Write-Status "Tunnel is already running" "Warning"
            Get-TunnelURL
            return
        }

        # Start the tunnel
        pm2 start ecosystem.config.js --silent
        
        # Wait for tunnel to initialize
        Write-Status "Waiting for tunnel to initialize..." "Info"
        Start-Sleep -Seconds 8
        
        # Check if it started successfully
        $status = pm2 list --silent | ConvertFrom-Json
        $app = $status | Where-Object { $_.name -eq $tunnelName }
        
        if ($app -and $app.pm2_env.status -eq "online") {
            Write-Status "Tunnel started successfully!" "Success"
            Get-TunnelURL
            Write-Status "Tunnel is persistent and will survive terminal closure" "Success"
        } else {
            Write-Status "Failed to start tunnel. Check logs with: pm2 logs $tunnelName" "Error"
        }
    }
    catch {
        Write-Status "Error starting tunnel: $($_.Exception.Message)" "Error"
    }
}

function Stop-Tunnel {
    Write-Status "Stopping tunnel..." "Info"
    
    try {
        pm2 stop $tunnelName --silent 2>$null
        pm2 delete $tunnelName --silent 2>$null
        Write-Status "Tunnel stopped and removed" "Success"
    }
    catch {
        Write-Status "Error stopping tunnel: $($_.Exception.Message)" "Error"
    }
}

function Get-TunnelStatus {
    try {
        $status = pm2 list --silent | ConvertFrom-Json
        $app = $status | Where-Object { $_.name -eq $tunnelName }
        
        if ($app) {
            Write-Status "Tunnel Status: $($app.pm2_env.status)" "Info"
            Write-Status "PID: $($app.pid)" "Info"
            Write-Status "Uptime: $($app.pm2_env.pm_uptime)" "Info"
            Write-Status "Restarts: $($app.pm2_env.restart_time)" "Info"
            
            if ($app.pm2_env.status -eq "online") {
                Get-TunnelURL
            }
        } else {
            Write-Status "Tunnel is not running" "Warning"
        }
    }
    catch {
        Write-Status "Error getting status: $($_.Exception.Message)" "Error"
    }
}

function Get-TunnelURL {
    Write-Status "Extracting tunnel URL from logs..." "Info"
    
    try {
        # Wait a moment for logs to be written
        Start-Sleep -Seconds 2
        
        $logs = pm2 logs $tunnelName --lines 50 --nostream --silent 2>$null
        
        if ($logs) {
            $urlPattern = "https://[\w-]+\.trycloudflare\.com"
            $matches = $logs | Select-String -Pattern $urlPattern -AllMatches
            
            if ($matches) {
                $latestUrl = $matches | Select-Object -Last 1
                $url = $latestUrl.Matches[0].Value
                Write-Status "🌐 Tunnel URL: $url" "Success"
                Write-Status "💾 Save this URL for n8n integration" "Info"
                
                # Save URL to file for easy access
                Set-Content -Path "tunnel-url.txt" -Value $url
                Write-Status "URL saved to tunnel-url.txt" "Info"
                
                return $url
            } else {
                Write-Status "URL not found in logs yet. Try again in a few seconds." "Warning"
            }
        } else {
            Write-Status "No logs available yet. Tunnel may still be starting." "Warning"
        }
    }
    catch {
        Write-Status "Error extracting URL: $($_.Exception.Message)" "Error"
    }
}

function Setup-Tunnel {
    Write-Status "Setting up persistent tunnel environment..." "Info"
    
    # Check if PM2 is installed
    if (!(Test-PM2Installed)) {
        Write-Status "PM2 not found. Installing..." "Warning"
        if (!(Install-PM2)) {
            Write-Status "Setup failed. Please install Node.js and try again." "Error"
            return
        }
    } else {
        Write-Status "PM2 is already installed" "Success"
    }
    
    # Create ecosystem config
    Create-EcosystemConfig
    
    Write-Status "Setup complete! Use the following commands:" "Success"
    Write-Host ""
    Write-Host "  Start tunnel:  .\scripts\tunnel.ps1 start" -ForegroundColor Green
    Write-Host "  Get URL:       .\scripts\tunnel.ps1 url" -ForegroundColor Green
    Write-Host "  Check status:  .\scripts\tunnel.ps1 status" -ForegroundColor Green
    Write-Host "  Stop tunnel:   .\scripts\tunnel.ps1 stop" -ForegroundColor Green
    Write-Host ""
}

# Main script execution
switch ($Action) {
    "setup" {
        Setup-Tunnel
    }
    "start" {
        if (!(Test-PM2Installed)) {
            Write-Status "PM2 not installed. Run: .\scripts\tunnel.ps1 setup" "Error"
            return
        }
        
        if (!(Test-Path "ecosystem.config.js")) {
            Write-Status "Configuration not found. Run: .\scripts\tunnel.ps1 setup" "Error"
            return
        }
        
        Start-Tunnel
    }
    "stop" {
        Stop-Tunnel
    }
    "status" {
        Get-TunnelStatus
    }
    "url" {
        # Try to get URL from saved file first
        if (Test-Path "tunnel-url.txt") {
            $savedUrl = Get-Content "tunnel-url.txt" -Raw
            if ($savedUrl) {
                Write-Status "🌐 Saved Tunnel URL: $($savedUrl.Trim())" "Success"
                
                # Verify tunnel is still running
                try {
                    $status = pm2 list --silent | ConvertFrom-Json
                    $app = $status | Where-Object { $_.name -eq $tunnelName }
                    
                    if ($app -and $app.pm2_env.status -eq "online") {
                        Write-Status "✅ Tunnel is running" "Success"
                    } else {
                        Write-Status "⚠️  Tunnel may not be running. Check status." "Warning"
                    }
                } catch {
                    Write-Status "⚠️  Cannot verify tunnel status" "Warning"
                }
                return
            }
        }
        
        # If no saved URL, get from logs
        Get-TunnelURL
    }
} 