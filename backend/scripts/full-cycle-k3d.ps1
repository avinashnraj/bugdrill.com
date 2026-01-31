# Full K3d Cycle - PowerShell Script for Windows
# This script provides the same functionality as "make full-cycle-k3d" but works on Windows

param(
    [string]$ClusterName = "bugdrill-local",
    [string]$Namespace = "bugdrill",
    [string]$DockerUsername = "smithaavinash",
    [string]$DockerTag = "latest",
    [int]$ApiPort = 8080
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n🔷 $Message" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Step 1: Destroy existing cluster
Write-Step "Step 1: Destroying existing k3d cluster"
k3d cluster delete $ClusterName 2>$null
Write-Success "Cluster destroyed (or didn't exist)"

# Step 2: Create new cluster
Write-Step "Step 2: Creating fresh k3d cluster"
k3d cluster create $ClusterName `
    --agents 1 `
    --port "${ApiPort}:8080@loadbalancer" `
    --wait

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create k3d cluster"
    exit 1
}
Write-Success "Cluster created successfully"

# Step 3: Deploy PostgreSQL
Write-Step "Step 3: Deploying PostgreSQL"
kubectl create namespace $Namespace 2>$null
helm upgrade --install bugdrill-postgres oci://registry-1.docker.io/bitnamicharts/postgresql `
    --namespace $Namespace `
    --set auth.username=postgres `
    --set auth.password=postgres `
    --set auth.database=bugdrill `
    --set primary.persistence.size=1Gi `
    --wait --timeout=5m

Write-Success "PostgreSQL deployed"

# Step 4: Deploy Redis
Write-Step "Step 4: Deploying Redis"
helm upgrade --install bugdrill-redis oci://registry-1.docker.io/bitnamicharts/redis `
    --namespace $Namespace `
    --set auth.enabled=false `
    --set master.persistence.size=1Gi `
    --wait --timeout=5m

Write-Success "Redis deployed"

# Step 5: Deploy Executor
Write-Step "Step 5: Deploying Executor"
@"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bugdrill-executor
  namespace: $Namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bugdrill-executor
  template:
    metadata:
      labels:
        app: bugdrill-executor
    spec:
      containers:
      - name: bugdrill-executor
        image: ${DockerUsername}/bugdrill-executor:${DockerTag}
        imagePullPolicy: Always
        ports:
        - containerPort: 8081
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: bugdrill-executor
  namespace: $Namespace
spec:
  selector:
    app: bugdrill-executor
  ports:
  - port: 8081
    targetPort: 8081
  type: ClusterIP
"@ | kubectl apply -f -

Write-Success "Executor deployed"

# Step 6: Deploy API
Write-Step "Step 6: Deploying API"
@"
apiVersion: v1
kind: ConfigMap
metadata:
  name: bugdrill-api-config
  namespace: $Namespace
data:
  DB_HOST: "bugdrill-postgres-postgresql"
  DB_PORT: "5432"
  DB_USER: "postgres"
  DB_NAME: "bugdrill"
  REDIS_HOST: "bugdrill-redis-master"
  REDIS_PORT: "6379"
  JWT_SECRET: "local-dev-secret-key-change-in-production"
  EXECUTOR_SERVICE_URL: "http://bugdrill-executor:8081"
---
apiVersion: v1
kind: Secret
metadata:
  name: bugdrill-api-secret
  namespace: $Namespace
type: Opaque
stringData:
  DB_PASSWORD: "postgres"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bugdrill-api
  namespace: $Namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bugdrill-api
  template:
    metadata:
      labels:
        app: bugdrill-api
    spec:
      containers:
      - name: bugdrill-api
        image: ${DockerUsername}/bugdrill-api:${DockerTag}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: bugdrill-api-config
        - secretRef:
            name: bugdrill-api-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: bugdrill-api
  namespace: $Namespace
spec:
  selector:
    app: bugdrill-api
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
"@ | kubectl apply -f -

Write-Host "⏳ Waiting for API to be ready..."
kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $Namespace --timeout=300s
if ($LASTEXITCODE -ne 0) {
    Write-Error "API failed to start"
    kubectl logs -l app=bugdrill-api -n $Namespace --tail=50
    exit 1
}
Write-Success "API deployed successfully"

# Step 7: Wait a bit for everything to stabilize
Write-Step "Step 7: Waiting for services to stabilize"
Start-Sleep -Seconds 10

# Step 8: Show status
Write-Step "Step 8: Cluster Status"
Write-Host "`n📊 Nodes:" -ForegroundColor Yellow
kubectl get nodes

Write-Host "`n📦 Deployments:" -ForegroundColor Yellow
kubectl get deployments -n $Namespace

Write-Host "`n🏃 Pods:" -ForegroundColor Yellow
kubectl get pods -n $Namespace

Write-Host "`n🌐 Services:" -ForegroundColor Yellow
kubectl get services -n $Namespace

# Final summary
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Green
Write-Success "Full k3d cycle completed successfully!"
Write-Host "=" * 80 -ForegroundColor Green

Write-Host "`n📋 Quick Reference:" -ForegroundColor Yellow
Write-Host "  API URL: http://localhost:$ApiPort"
Write-Host "  Namespace: $Namespace"
Write-Host "  Cluster: $ClusterName"

Write-Host "`n🔧 Useful Commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $Namespace"
Write-Host "  kubectl logs -l app=bugdrill-api -n $Namespace -f"
Write-Host "  kubectl exec -it deployment/bugdrill-api -n $Namespace -- /bin/sh"
Write-Host "  k3d cluster delete $ClusterName"

Write-Host "`n🧪 Test the API:" -ForegroundColor Yellow
Write-Host "  curl http://localhost:$ApiPort/health"
Write-Host ""
