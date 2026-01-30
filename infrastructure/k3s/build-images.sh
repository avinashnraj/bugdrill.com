#!/bin/bash
# Build and push Docker images for BugDrill
# Run this locally or on EC2 instance

set -e

# Configuration
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.io"}  # Use Docker Hub by default
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}  # CHANGE THIS
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "=== Building BugDrill Docker Images ==="
echo "Registry: $DOCKER_REGISTRY"
echo "Username: $DOCKER_USERNAME"
echo "Tag: $IMAGE_TAG"
echo ""

# Login to Docker registry
echo "Logging in to Docker registry..."
docker login $DOCKER_REGISTRY

# Build API image
echo "Building API image..."
cd backend
docker build \
    -t $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-api:$IMAGE_TAG \
    -f Dockerfile \
    .

echo "Pushing API image..."
docker push $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-api:$IMAGE_TAG

# Build Executor image
echo "Building Executor image..."
docker build \
    -t $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-executor:$IMAGE_TAG \
    -f executor/Dockerfile \
    .

echo "Pushing Executor image..."
docker push $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-executor:$IMAGE_TAG

cd ..

echo ""
echo "=== Build Complete ==="
echo "API Image: $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-api:$IMAGE_TAG"
echo "Executor Image: $DOCKER_REGISTRY/$DOCKER_USERNAME/bugdrill-executor:$IMAGE_TAG"
echo ""
echo "Update these image names in values-micro.yaml before deploying"
