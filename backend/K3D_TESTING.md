# K3D & Kubernetes Testing Environment

Complete setup for k3d (lightweight Kubernetes) + Helm + BDD functional testing.

## 📦 What's Included

### 1. k3d Cluster Setup
- **1 server + 2 agent nodes**
- **Local Docker registry** at `localhost:5000`
- **Ingress ready** on ports 8080/8443
- Namespaces: `bugdrill` (dev), `bugdrill-test` (tests)

### 2. Helm Charts
- **Complete Helm chart** for API deployment
- **Three environments**: dev, staging, prod
- **Integrated PostgreSQL & Redis** (subchart)
- **HPA, Ingress, ConfigMaps, Secrets**

### 3. Godog Functional Tests (BDD)
- **Gherkin/Cucumber syntax** for readable tests
- **4 scenarios** covering auth workflow
- **Runs in both** Docker Compose and k3d
- **Same test image** for consistency

## 🚀 Quick Start

### Prerequisites
```bash
# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl (if not already installed)
```

### Setup k3d Cluster

```bash
# Create cluster
make k3d-create

# Verify
kubectl get nodes
kubectl get namespaces
```

### Deploy Application

```bash
# Build and push image to k3d registry
make docker-build-k3d

# Deploy with Helm
make helm-install

# Check deployment
kubectl get pods -n bugdrill
kubectl get svc -n bugdrill
```

### Run Functional Tests

**Option 1: Docker Compose**
```bash
make test-functional-docker
```

**Option 2: k3d Cluster**
```bash
make test-functional-k3d
```

## 📋 Test Scenarios

Located in `tests/features/auth.feature`:

1. ✅ **Successful signup and login**
   - User signs up
   - Receives tokens
   - Logs in
   - Accesses profile

2. ✅ **Access protected endpoints**
   - Lists coding patterns
   - Verifies pattern count
   - Checks pattern names

3. ✅ **Unauthorized access**
   - Attempts access without token
   - Receives 401 error

4. ✅ **Token refresh workflow**
   - Uses refresh token
   - Gets new access token
   - Verifies tokens are different

## 🏗️ Project Structure

```
backend/
├── helm/
│   └── bugdrill-api/
│       ├── Chart.yaml
│       ├── values.yaml           # Default (production)
│       ├── values-dev.yaml       # Development overrides
│       ├── values-prod.yaml      # Production overrides
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           └── hpa.yaml
├── tests/
│   ├── features/
│   │   └── auth.feature          # Gherkin scenarios
│   ├── steps/
│   │   └── auth_steps.go         # Step implementations
│   └── cmd/
│       └── main.go               # Test runner
├── scripts/
│   ├── k3d-create.sh             # Create k3d cluster
│   ├── k3d-destroy.sh            # Destroy k3d cluster
│   ├── test-docker.sh            # Run tests in Docker
│   └── test-k3d.sh               # Run tests in k3d
├── Dockerfile                     # API service
└── Dockerfile.tests              # Functional tests
```

## 🔧 Helm Values

### Development (values-dev.yaml)
- 1 replica
- No persistence
- Disabled SSL
- Longer token expiration
- No autoscaling

### Production (values-prod.yaml)
- 3+ replicas
- Persistent storage
- SSL required
- Short token expiration
- HPA enabled (3-20 pods)
- Metrics enabled

## 📊 Test Workflow

### Docker Compose Flow
```
1. Start postgres, redis, dev containers
2. Wait for API health check
3. Run functional-tests container
4. Execute Godog scenarios
5. Cleanup containers
```

### k3d Flow
```
1. Deploy Helm chart to k3d cluster
2. Wait for deployment ready
3. Build and push test image to k3d registry
4. Create Kubernetes Job for tests
5. Execute tests in cluster
6. Collect logs and results
```

## 🎯 Makefile Commands

### k3d Management
```bash
make k3d-create           # Create k3d cluster
make k3d-destroy          # Destroy k3d cluster
make docker-build-k3d     # Build & push to k3d registry
```

### Helm Operations
```bash
make helm-install         # Deploy chart to k3d
make helm-uninstall       # Remove deployment
make helm-template        # Preview rendered manifests
```

### Testing
```bash
make test-functional-docker   # Test in Docker Compose
make test-functional-k3d      # Test in k3d
make test-all                 # Unit + functional tests
```

## 🐛 Debugging

### Check k3d cluster
```bash
k3d cluster list
kubectl cluster-info
kubectl get all -n bugdrill
```

### View Helm release
```bash
helm list -n bugdrill
helm status bugdrill -n bugdrill
helm get values bugdrill -n bugdrill
```

### Check pods
```bash
kubectl get pods -n bugdrill
kubectl logs -f deployment/bugdrill-api -n bugdrill
kubectl describe pod <pod-name> -n bugdrill
```

### Test connectivity
```bash
# Port-forward API service
kubectl port-forward svc/bugdrill-api 8080:8080 -n bugdrill

# Test from another pod
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
apk add curl
curl http://bugdrill-api.bugdrill.svc.cluster.local:8080/health
```

### View test logs
```bash
# Docker Compose
docker-compose logs functional-tests

# k3d
kubectl get jobs -n bugdrill-test
kubectl logs job/<job-name> -n bugdrill-test
```

## 📈 Scaling

### Manual scaling
```bash
kubectl scale deployment bugdrill-api --replicas=5 -n bugdrill
```

### Autoscaling (if HPA enabled)
```bash
kubectl get hpa -n bugdrill
kubectl describe hpa bugdrill-api -n bugdrill
```

## 🔒 Secrets Management

### Development
Secrets are generated in Helm templates:
```yaml
JWT_ACCESS_SECRET: {{ randAlphaNum 32 | b64enc }}
```

### Production
Use external secret management:
```yaml
# values-prod.yaml
postgresql:
  auth:
    existingSecret: postgresql-secret

# Create secret manually
kubectl create secret generic postgresql-secret \
  --from-literal=password=<secure-password> \
  -n bugdrill
```

## 🌐 Accessing Services

### In k3d cluster
```bash
# Get service IP
kubectl get svc bugdrill-api -n bugdrill

# Via ingress (add to /etc/hosts)
echo "127.0.0.1 api.bugdrill.local" | sudo tee -a /etc/hosts
curl http://api.bugdrill.local:8080/health
```

## 🧹 Cleanup

```bash
# Uninstall Helm release
make helm-uninstall

# Destroy k3d cluster
make k3d-destroy

# Clean Docker images
docker rmi localhost:5000/bugdrill-api:dev
docker rmi localhost:5000/bugdrill-tests:latest
```

## 📝 Next Steps

1. ✅ **Add more test scenarios** - Cover snippets, progress tracking
2. ✅ **CI/CD integration** - GitHub Actions workflow
3. ✅ **Monitoring** - Prometheus + Grafana Helm charts
4. ✅ **Load testing** - k6 scripts for performance testing
5. ✅ **Multi-region** - Expand k3d to simulate geo-distribution

---

**Documentation complete!** You now have a production-like k8s environment for development and testing.
