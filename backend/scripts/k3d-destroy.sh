#!/bin/bash
set -e

CLUSTER_NAME="bugdrill"

echo "🗑️  Destroying k3d cluster: ${CLUSTER_NAME}"

k3d cluster delete ${CLUSTER_NAME}

echo "✅ Cluster destroyed successfully!"
