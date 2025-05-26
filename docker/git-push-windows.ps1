# Git Push Script for Windows
# This script helps bypass Husky hook issues on Windows

param(
    [Parameter(Position=0)]
    [string]$Branch = "HEAD",
    [switch]$Force,
    [switch]$SkipHooks
)

Write-Host "GIT: Preparing to push to GitHub..." -ForegroundColor Yellow

# Check if we should skip hooks
if ($SkipHooks) {
    Write-Host "INFO: Skipping Git hooks..." -ForegroundColor Cyan
    $env:HUSKY = "0"
}

# Ensure we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not in a Git repository" -ForegroundColor Red
    exit 1
}

# Get current branch
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "INFO: Current branch: $currentBranch" -ForegroundColor Cyan

# Check if branch is master or develop
if ($currentBranch -eq "master" -or $currentBranch -eq "develop") {
    Write-Host "WARNING: You're trying to push to protected branch: $currentBranch" -ForegroundColor Yellow
    $confirm = Read-Host "Are you sure you want to continue? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "CANCELLED: Push cancelled by user" -ForegroundColor Red
        exit 1
    }
}

# Run lint-staged manually before push (Windows compatible)
Write-Host "LINT: Running lint-staged..." -ForegroundColor Yellow
try {
    npx --no-install lint-staged
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Linting found issues but continuing..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not run lint-staged, continuing..." -ForegroundColor Yellow
}

# Perform the actual push
try {
    Write-Host "PUSH: Pushing to GitHub..." -ForegroundColor Green
    
    if ($Force) {
        git push --force-with-lease origin $Branch
    } else {
        git push origin $Branch
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Successfully pushed to GitHub!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Push failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} catch {
    Write-Host "ERROR: Push failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Reset HUSKY environment variable
    if ($SkipHooks) {
        Remove-Item Env:HUSKY -ErrorAction SilentlyContinue
    }
}

Write-Host "COMPLETE: Git push operation completed!" -ForegroundColor Green 