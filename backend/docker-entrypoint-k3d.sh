#!/bin/bash
set -e

# Start Docker daemon in background
dockerd &

# Wait for Docker to be ready
echo "Waiting for Docker daemon to start..."
timeout=30
elapsed=0
while ! docker info >/dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "Docker daemon failed to start after ${timeout}s"
        exit 1
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "Docker daemon is ready!"

# Execute the command
exec "$@"
