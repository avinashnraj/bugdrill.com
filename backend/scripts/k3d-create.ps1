# PowerShell script to create k3d cluster

$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "bugdrill"
$REGISTRY_NAME = "k3d-registry.localhost"
$REGISTRY_PORT = 5000

Write-Host "🚀 Creating k3d cluster for bugdrill..." -ForegroundColor Cyan

# Check if cluster already exists
$existingCluster = k3d cluster list | Select-String -Pattern $CLUSTER_NAME
if ($existingCluster) {
    Write-Host "⚠️  Cluster '$CLUSTER_NAME' already exists. Delete it first with 'k3d cluster delete $CLUSTER_NAME'" -ForegroundColor Yellow
    exit 1
}

# Create local Docker registry if it doesn't exist
Write-Host "`nCreating local Docker registry..." -ForegroundColor Yellow
$existingRegistry = docker ps -a --filter "name=$REGISTRY_NAME" --format "{{.Names}}"
if (-not $existingRegistry) {
    docker run -d --restart always `
        -p "${REGISTRY_PORT}:5000" `
        --name $REGISTRY_NAME `
        registry:2
    Write-Host "✓ Registry created at localhost:$REGISTRY_PORT" -ForegroundColor Green
} else {
    Write-Host "✓ Registry already exists" -ForegroundColor Green
}

# Create k3d cluster
Write-Host "`nCreating k3d cluster..." -ForegroundColor Yellow
k3d cluster create $CLUSTER_NAME `
    --api-port 6550 `
    --servers 1 `
    --agents 2 `
    --port "8080:80@loadbalancer" `
    --port "8443:443@loadbalancer" `
    --registry-use "${REGISTRY_NAME}:${REGISTRY_PORT}" `
    --k3s-arg "--disable=traefik@server:0"

Write-Host "✓ Cluster created successfully" -ForegroundColor Green

# Wait for cluster to be ready
Write-Host "`nWaiting for cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready node --all --timeout=120s

# Create namespaces
Write-Host "`nCreating namespaces..." -ForegroundColor Yellow
kubectl create namespace bugdrill
kubectl create namespace bugdrill-test

Write-Host "✓ Namespaces created" -ForegroundColor Green

# Display cluster info
Write-Host "`n📊 Cluster Information:" -ForegroundColor Cyan
kubectl cluster-info
Write-Host ""
kubectl get nodes

Write-Host "`n✅ k3d cluster setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Build and push API image: make docker-build-k3d" -ForegroundColor White
Write-Host "  2. Deploy with Helm: make helm-install" -ForegroundColor White
Write-Host "  3. Run tests: make test-functional-k3d" -ForegroundColor White
