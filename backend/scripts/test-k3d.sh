#!/bin/bash
set -e

NAMESPACE="bugdrill-test"
RELEASE_NAME="bugdrill"

echo "🧪 Running functional tests in k3d environment..."

# Deploy application to k3d
echo "🚀 Deploying application to k3d..."
helm upgrade --install ${RELEASE_NAME} ./helm/bugdrill-api \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --values ./helm/bugdrill-api/values-dev.yaml \
    --wait \
    --timeout 5m

# Wait for deployment to be ready
echo "⏳ Waiting for deployment..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/${RELEASE_NAME}-bugdrill-api \
    -n ${NAMESPACE}

# Get service URL
SERVICE_URL=$(kubectl get svc ${RELEASE_NAME}-bugdrill-api -n ${NAMESPACE} -o jsonpath='{.spec.clusterIP}')
API_URL="http://${SERVICE_URL}:8080"

echo "🌐 API URL: ${API_URL}"

# Build and push test image to k3d registry
echo "🐳 Building test image..."
docker build -t localhost:5000/bugdrill-tests:latest -f Dockerfile.tests .
docker push localhost:5000/bugdrill-tests:latest

# Run tests as a Kubernetes Job
echo "🧪 Running tests..."
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: functional-tests-$(date +%s)
  namespace: ${NAMESPACE}
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: tests
        image: localhost:5000/bugdrill-tests:latest
        env:
        - name: API_BASE_URL
          value: "${API_URL}"
EOF

# Wait for job to complete
JOB_NAME=$(kubectl get jobs -n ${NAMESPACE} -l job-name --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
echo "📊 Watching job: ${JOB_NAME}"

kubectl wait --for=condition=complete --timeout=300s job/${JOB_NAME} -n ${NAMESPACE} || true

# Get test results
echo "📄 Test Results:"
kubectl logs job/${JOB_NAME} -n ${NAMESPACE}

# Check if tests passed
if kubectl get job ${JOB_NAME} -n ${NAMESPACE} -o jsonpath='{.status.succeeded}' | grep -q 1; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Tests failed!"
    exit 1
fi
