# Docker Build Helper Script
# Usage: .\docker-build.ps1 [base_tag] [output_tag]
# Example: .\docker-build.ps1 v1.0.8 latest

param(
    [Parameter(Position=0)]
    [string]$BaseTag = "latest",
    
    [Parameter(Position=1)]
    [string]$OutputTag = "latest"
)

$ImageName = "chatwoot"

Write-Host "Docker Build Helper" -ForegroundColor Green
Write-Host "Base Image Tag: vkhon00/my-chatwoot-base:$BaseTag" -ForegroundColor Yellow
Write-Host "Output Image: $ImageName`:$OutputTag" -ForegroundColor Yellow
Write-Host ""

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Blue
docker build `
    --build-arg BASE_IMAGE_TAG=$BaseTag `
    -t $ImageName`:$OutputTag `
    -f docker/Dockerfile `
    .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "Image: $ImageName`:$OutputTag" -ForegroundColor Cyan
    
    # Show image size
    $imageInfo = docker images $ImageName`:$OutputTag --format "table {{.Size}}" | Select-Object -Skip 1
    Write-Host "Size: $imageInfo" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Usage Examples:" -ForegroundColor Yellow
Write-Host "  # Build with latest base image (default)" -ForegroundColor White
Write-Host "  .\docker-build.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Build with specific base image version" -ForegroundColor White
Write-Host "  .\docker-build.ps1 v1.0.8" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Build with specific base and output tags" -ForegroundColor White
Write-Host "  .\docker-build.ps1 v1.0.8 production" -ForegroundColor Gray 