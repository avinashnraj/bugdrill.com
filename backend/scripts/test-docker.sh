#!/bin/bash
set -e

echo "🧪 Running functional tests in Docker Compose environment..."

# Start services
echo "📦 Starting API services..."
docker-compose up -d dev postgres redis

# Wait for API to be healthy
echo "⏳ Waiting for API to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ API is healthy"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Run tests
echo "🧪 Running tests..."
docker-compose --profile test run --rm functional-tests

# Capture exit code
TEST_EXIT_CODE=$?

# Cleanup
echo "🧹 Cleaning up..."
docker-compose down

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed with exit code $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE
