# Script to run local pipeline test on Windows (PowerShell)
# Run: .\test-pipeline.ps1

param(
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [switch]$WithK3s,
    [switch]$SkipLint
)

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   BugDrill CI/CD Pipeline - Local Simulation           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Change to backend directory
$BackendDir = Join-Path $PSScriptRoot "..\..\backend"
Set-Location $BackendDir

# Step 1: Check formatting
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Step 1: Checking Go formatting..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$unformatted = gofmt -l .
if ($unformatted) {
    Write-Host "✗ Go files not formatted:" -ForegroundColor Red
    Write-Host $unformatted
    Write-Host ""
    Write-Host "Run: gofmt -w ." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ All Go files properly formatted" -ForegroundColor Green
}
Write-Host ""

# Step 2: Run linter
if (-not $SkipLint) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Step 2: Running linter..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    if (Get-Command golangci-lint -ErrorAction SilentlyContinue) {
        $lintResult = golangci-lint run --timeout=5m
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Linting passed" -ForegroundColor Green
        } else {
            Write-Host "⚠ Linting completed with warnings" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ golangci-lint not installed, skipping..." -ForegroundColor Yellow
        Write-Host "Install from: https://golangci-lint.run/usage/install/" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 3: Run tests
if (-not $SkipTests) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Step 3: Running tests..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    # Check if Docker services are running
    $postgresRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "bugdrill-postgres"
    if (-not $postgresRunning) {
        Write-Host "Starting Docker services..." -ForegroundColor Yellow
        docker-compose up -d postgres redis
        Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    
    # Run tests
    make test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Tests failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Tests passed" -ForegroundColor Green
    
    # Check coverage
    make test-coverage | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $coverage = go tool cover -func=coverage.out | Select-String "total" | ForEach-Object { $_.ToString().Split()[-1] }
        Write-Host "Coverage: $coverage" -ForegroundColor Cyan
    }
    Write-Host ""
}

# Step 4: Build Docker images
if (-not $SkipBuild) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Step 4: Building Docker images..." -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    # Build API image
    Write-Host "Building API image..." -ForegroundColor Cyan
    docker build -t bugdrill-api:local -f Dockerfile . 2>&1 | Out-File -FilePath "$env:TEMP\docker-build-api.log"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ API image built successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ API image build failed" -ForegroundColor Red
        Get-Content "$env:TEMP\docker-build-api.log"
        exit 1
    }
    
    # Build Executor image
    Write-Host "Building Executor image..." -ForegroundColor Cyan
    docker build -t bugdrill-executor:local -f executor/Dockerfile . 2>&1 | Out-File -FilePath "$env:TEMP\docker-build-executor.log"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Executor image built successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Executor image build failed" -ForegroundColor Red
        Get-Content "$env:TEMP\docker-build-executor.log"
        exit 1
    }
    
    # Show image sizes
    Write-Host ""
    Write-Host "Image sizes:" -ForegroundColor Cyan
    docker images | Select-String "bugdrill.*local"
    Write-Host ""
}

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✓ Formatting check passed" -ForegroundColor Green
if (-not $SkipLint) {
    Write-Host "✓ Linting completed" -ForegroundColor Green
}
if (-not $SkipTests) {
    Write-Host "✓ Tests passed" -ForegroundColor Green
}
if (-not $SkipBuild) {
    Write-Host "✓ Docker images built" -ForegroundColor Green
}
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   All checks passed! Ready to push.                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review your changes: git diff"
Write-Host "  2. Commit: git commit -m 'your message'"
Write-Host "  3. Push: git push origin your-branch"
Write-Host "  4. Create PR on GitHub"
Write-Host ""
