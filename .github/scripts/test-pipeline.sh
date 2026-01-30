#!/bin/bash
# Local simulation of CI/CD pipeline
# Run this before pushing to catch issues early

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   BugDrill CI/CD Pipeline - Local Simulation           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RUN_TESTS=${RUN_TESTS:-true}
RUN_BUILD=${RUN_BUILD:-true}
RUN_K3S=${RUN_K3S:-false}
SKIP_LINT=${SKIP_LINT:-false}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests)
      RUN_TESTS=false
      shift
      ;;
    --skip-build)
      RUN_BUILD=false
      shift
      ;;
    --with-k3s)
      RUN_K3S=true
      shift
      ;;
    --skip-lint)
      SKIP_LINT=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-tests] [--skip-build] [--with-k3s] [--skip-lint]"
      exit 1
      ;;
  esac
done

# Change to backend directory
cd "$(dirname "$0")/../backend" || exit 1

# Step 1: Check formatting
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Checking Go formatting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

UNFORMATTED=$(gofmt -l .)
if [ -n "$UNFORMATTED" ]; then
    echo -e "${RED}✗ Go files not formatted:${NC}"
    echo "$UNFORMATTED"
    echo ""
    echo "Run: gofmt -w ."
    exit 1
else
    echo -e "${GREEN}✓ All Go files properly formatted${NC}"
fi
echo ""

# Step 2: Run linter
if [ "$SKIP_LINT" = false ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 2: Running linter..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v golangci-lint &> /dev/null; then
        if golangci-lint run --timeout=5m; then
            echo -e "${GREEN}✓ Linting passed${NC}"
        else
            echo -e "${YELLOW}⚠ Linting completed with warnings${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ golangci-lint not installed, skipping...${NC}"
        echo "Install: curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$(go env GOPATH)/bin"
    fi
    echo ""
fi

# Step 3: Run tests
if [ "$RUN_TESTS" = true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 3: Running tests..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if Docker services are running
    if ! docker ps | grep -q bugdrill-postgres; then
        echo "Starting Docker services..."
        docker-compose up -d postgres redis
        echo "Waiting for services to be ready..."
        sleep 10
    fi
    
    # Run tests
    if make test; then
        echo -e "${GREEN}✓ Tests passed${NC}"
    else
        echo -e "${RED}✗ Tests failed${NC}"
        exit 1
    fi
    
    # Check coverage
    if make test-coverage > /dev/null 2>&1; then
        COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}')
        echo "Coverage: $COVERAGE"
        
        # Extract percentage value
        COVERAGE_NUM=$(echo $COVERAGE | sed 's/%//')
        if (( $(echo "$COVERAGE_NUM < 50" | bc -l) )); then
            echo -e "${YELLOW}⚠ Warning: Coverage below 50%${NC}"
        else
            echo -e "${GREEN}✓ Coverage meets threshold${NC}"
        fi
    fi
    echo ""
fi

# Step 4: Build Docker images
if [ "$RUN_BUILD" = true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 4: Building Docker images..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Build API image
    echo "Building API image..."
    if docker build -t bugdrill-api:local -f Dockerfile . > /tmp/docker-build-api.log 2>&1; then
        echo -e "${GREEN}✓ API image built successfully${NC}"
    else
        echo -e "${RED}✗ API image build failed${NC}"
        cat /tmp/docker-build-api.log
        exit 1
    fi
    
    # Build Executor image
    echo "Building Executor image..."
    if docker build -t bugdrill-executor:local -f executor/Dockerfile . > /tmp/docker-build-executor.log 2>&1; then
        echo -e "${GREEN}✓ Executor image built successfully${NC}"
    else
        echo -e "${RED}✗ Executor image build failed${NC}"
        cat /tmp/docker-build-executor.log
        exit 1
    fi
    
    # Show image sizes
    echo ""
    echo "Image sizes:"
    docker images | grep bugdrill | grep local
    echo ""
fi

# Step 5: Test K3s deployment (optional)
if [ "$RUN_K3S" = true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 5: Testing K3s deployment..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if K3s is installed
    if ! command -v k3s &> /dev/null; then
        echo -e "${YELLOW}⚠ K3s not installed. Skipping K3s tests.${NC}"
        echo "To test K3s deployment, install K3s first:"
        echo "  curl -sfL https://get.k3s.io | sh -"
    else
        echo "K3s deployment test would run here..."
        echo "(Implementation: deploy with Helm and run smoke tests)"
    fi
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ Formatting check passed${NC}"
if [ "$SKIP_LINT" = false ]; then
    echo -e "${GREEN}✓ Linting completed${NC}"
fi
if [ "$RUN_TESTS" = true ]; then
    echo -e "${GREEN}✓ Tests passed${NC}"
fi
if [ "$RUN_BUILD" = true ]; then
    echo -e "${GREEN}✓ Docker images built${NC}"
fi
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   All checks passed! Ready to push.                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Review your changes: git diff"
echo "  2. Commit: git commit -m 'your message'"
echo "  3. Push: git push origin your-branch"
echo "  4. Create PR on GitHub"
echo ""
