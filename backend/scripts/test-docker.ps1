# PowerShell script to run functional tests in Docker Compose

$ErrorActionPreference = "Stop"

Write-Host "🧪 Starting functional tests in Docker Compose..." -ForegroundColor Cyan

# Start dependencies
Write-Host "Starting PostgreSQL and Redis..." -ForegroundColor Yellow
docker-compose up -d postgres redis

# Start API service
Write-Host "Starting API service..." -ForegroundColor Yellow
docker-compose up -d dev

# Wait for API to be healthy
Write-Host "Waiting for API to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$healthy = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            Write-Host "✓ API is healthy!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "Attempt $attempt/$maxAttempts - API not ready yet..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $healthy) {
    Write-Host "❌ API failed to become healthy" -ForegroundColor Red
    docker-compose logs dev
    docker-compose down
    exit 1
}

# Run functional tests
Write-Host "`n🚀 Running functional tests..." -ForegroundColor Cyan
docker-compose run --rm functional-tests

$testExitCode = $LASTEXITCODE

# Cleanup
Write-Host "`n🧹 Cleaning up..." -ForegroundColor Yellow
docker-compose down -v

if ($testExitCode -eq 0) {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Tests failed with exit code $testExitCode" -ForegroundColor Red
}

exit $testExitCode
