# PowerShell script to destroy k3d cluster

$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "bugdrill"
$REGISTRY_NAME = "k3d-registry.localhost"

Write-Host "🗑️  Destroying k3d cluster..." -ForegroundColor Yellow

# Delete k3d cluster
k3d cluster delete $CLUSTER_NAME

Write-Host "✓ Cluster deleted" -ForegroundColor Green

# Optionally delete registry
Write-Host "`nDo you want to delete the local Docker registry? (y/N)" -ForegroundColor Cyan
$response = Read-Host

if ($response -eq "y" -or $response -eq "Y") {
    docker stop $REGISTRY_NAME
    docker rm $REGISTRY_NAME
    Write-Host "✓ Registry deleted" -ForegroundColor Green
} else {
    Write-Host "Registry kept for future use" -ForegroundColor Gray
}

Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
