#!/bin/sh
# Script to run functional tests from within the dev container

set -e

echo "🧪 Running functional tests..."
echo ""

# Wait for API to be ready
echo "⏳ Waiting for API to be ready..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt + 1))
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✓ API is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ API failed to become ready after $max_attempts attempts"
        exit 1
    fi
    
    echo "Attempt $attempt/$max_attempts - waiting..."
    sleep 2
done

echo ""
echo "🚀 Running Godog tests..."
echo ""

# Run the tests
cd /app/tests
go test -v

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed with exit code $exit_code"
fi

exit $exit_code
