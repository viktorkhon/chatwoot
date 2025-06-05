param(
    [Parameter(Mandatory=$true)]
    [string]$NewUrl
)

Write-Host "Updating FRONTEND_URL to: $NewUrl" -ForegroundColor Cyan

# Step 1: Update both .env and .env.local files
Write-Host "Updating environment files..." -ForegroundColor Yellow

# Update .env.local
if (Test-Path ".env.local") {
    $content = Get-Content ".env.local"
    $updatedContent = @()
    $found = $false
    
    foreach ($line in $content) {
        if ($line -match "^FRONTEND_URL=") {
            $updatedContent += "FRONTEND_URL=$NewUrl"
            $found = $true
        } else {
            $updatedContent += $line
        }
    }
    
    if (-not $found) {
        $updatedContent += "FRONTEND_URL=$NewUrl"
    }
    
    $updatedContent | Set-Content ".env.local" -Encoding UTF8
    Write-Host "✅ .env.local updated" -ForegroundColor Green
} else {
    Write-Host "❌ .env.local not found" -ForegroundColor Red
}

# Update .env file
if (Test-Path ".env") {
    $content = Get-Content ".env"
    $updatedContent = @()
    $found = $false
    
    foreach ($line in $content) {
        if ($line -match "^FRONTEND_URL=") {
            $updatedContent += "FRONTEND_URL=$NewUrl"
            $found = $true
        } else {
            $updatedContent += $line
        }
    }
    
    if (-not $found) {
        $updatedContent += "FRONTEND_URL=$NewUrl"
    }
    
    $updatedContent | Set-Content ".env" -Encoding UTF8
    Write-Host "✅ .env updated" -ForegroundColor Green
} else {
    Write-Host "❌ .env not found" -ForegroundColor Red
}

# Step 2: Update database configuration
Write-Host "Updating database configuration..." -ForegroundColor Yellow

$railsScript = @"
config = InstallationConfig.find_by(name: 'FRONTEND_URL')
if config
  config.update!(serialized_value: { 'value' => '$NewUrl' })
  puts '✅ Updated existing InstallationConfig'
else
  InstallationConfig.create!(name: 'FRONTEND_URL', serialized_value: { 'value' => '$NewUrl' }, locked: true)
  puts '✅ Created new InstallationConfig'
end

Account.all.each do |account|
  domain = '$NewUrl'.gsub(/https?:\/\//, '')
  account.update!(domain: domain)
end
puts "✅ Updated #{Account.count} account domains"

count = 0
Inbox.where(channel_type: 'Channel::WebWidget').each do |inbox|
  widget_settings = inbox.channel.widget_settings || {}
  widget_settings['website_url'] = '$NewUrl'
  widget_settings['widget_website_url'] = '$NewUrl'
  inbox.channel.update!(widget_settings: widget_settings)
  count += 1
end
puts "✅ Updated #{count} widget inboxes"

puts "Database updated successfully"
"@

$railsScript | Out-File -FilePath "temp_update_url.rb" -Encoding UTF8

docker-compose -f docker-compose.dev.yaml exec -T rails bundle exec rails runner temp_update_url.rb

Remove-Item "temp_update_url.rb" -Force

# Step 3: Restart Rails to pick up environment changes
Write-Host "Restarting Rails container..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yaml restart rails

Write-Host ""
Write-Host "🎉 FRONTEND_URL UPDATE COMPLETE!" -ForegroundColor Green
Write-Host "New URL: $NewUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Updated .env and .env.local files" -ForegroundColor Green
Write-Host "✅ Updated database configuration" -ForegroundColor Green
Write-Host "✅ Updated account domains and widget settings" -ForegroundColor Green
Write-Host "✅ Restarted Rails container" -ForegroundColor Green
Write-Host ""
Write-Host "💡 All configurations updated and Rails restarted!" -ForegroundColor Yellow
