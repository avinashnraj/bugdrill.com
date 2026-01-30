#!/bin/bash
# Deployment script for BugDrill on K3s
# Run this from your EC2 instance after building images

set -e

NAMESPACE=bugdrill
RELEASE_NAME=bugdrill-api
CHART_PATH=./backend/helm/interviewpal-api
VALUES_FILE=./backend/helm/interviewpal-api/values-micro.yaml

echo "=== BugDrill Deployment Script ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install K3s first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Helm not found. Please install Helm first."
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

# Check if secrets exist
if ! kubectl get secret bugdrill-secrets -n $NAMESPACE &> /dev/null; then
    echo "Error: bugdrill-secrets not found in namespace $NAMESPACE"
    echo "Please create secrets first using install-k3s.sh or manually"
    exit 1
fi

# Deploy using Helm
echo "Deploying $RELEASE_NAME..."
helm upgrade --install $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --wait \
    --timeout 5m

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Checking pod status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "Checking services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "To view logs:"
echo "kubectl logs -f -n $NAMESPACE -l app.kubernetes.io/name=interviewpal-api"

echo ""
echo "To access the API:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "http://$PUBLIC_IP/health"
