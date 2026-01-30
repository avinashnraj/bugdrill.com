#!/bin/bash
set -e

CLUSTER_NAME="bugdrill"
REGISTRY_NAME="k3d-registry.localhost"
REGISTRY_PORT="5000"

echo "🚀 Creating k3d cluster: ${CLUSTER_NAME}"

# Check if cluster already exists
if k3d cluster list | grep -q "${CLUSTER_NAME}"; then
    echo "⚠️  Cluster ${CLUSTER_NAME} already exists. Delete it first with: ./scripts/k3d-destroy.sh"
    exit 1
fi

# Create local registry
echo "📦 Creating local Docker registry..."
k3d registry create ${REGISTRY_NAME} --port ${REGISTRY_PORT} || echo "Registry already exists"

# Create k3d cluster with registry
echo "🏗️  Creating k3d cluster..."
k3d cluster create ${CLUSTER_NAME} \
    --api-port 6550 \
    --servers 1 \
    --agents 2 \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --registry-use k3d-${REGISTRY_NAME}:${REGISTRY_PORT} \
    --k3s-arg "--disable=traefik@server:0" \
    --wait

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=60s

# Create namespace
echo "📁 Creating bugdrill namespace..."
kubectl create namespace bugdrill || echo "Namespace already exists"
kubectl create namespace bugdrill-test || echo "Test namespace already exists"

# Set default namespace
kubectl config set-context --current --namespace=bugdrill

echo "✅ k3d cluster created successfully!"
echo ""
echo "🔍 Cluster Info:"
echo "  Cluster: ${CLUSTER_NAME}"
echo "  Registry: localhost:${REGISTRY_PORT}"
echo "  API Server: https://0.0.0.0:6550"
echo "  HTTP: http://localhost:8080"
echo ""
echo "📝 Next steps:"
echo "  1. Build and push images: make docker-build-k3d"
echo "  2. Deploy with Helm: make helm-install"
echo "  3. Run functional tests: make test-k3d"
