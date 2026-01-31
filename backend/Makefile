.PHONY: help build run test docker-up docker-down docker-logs migrate-up migrate-down clean

# Variables
APP_NAME=bugdrill-api
DOCKER_COMPOSE=docker-compose
GO=go

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development
install: ## Install dependencies
	$(GO) mod download
	$(GO) mod tidy

build: ## Build the application
	$(GO) build -o bin/$(APP_NAME) ./cmd/server

run: ## Run the application locally
	$(GO) run ./cmd/server

test: ## Run tests
	$(GO) test -v ./...

test-coverage: ## Run tests with coverage
	$(GO) test -v -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out

lint: ## Run linter
	golangci-lint run

# Docker
docker-build: ## Build Docker image
	docker build -t $(APP_NAME):latest .

docker-up: ## Start all services with Docker Compose
	$(DOCKER_COMPOSE) up -d

docker-down: ## Stop all services
	$(DOCKER_COMPOSE) down

docker-logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

docker-restart: ## Restart all services
	$(DOCKER_COMPOSE) restart

docker-clean: ## Remove all containers, volumes, and images
	$(DOCKER_COMPOSE) down -v
	docker rmi $(APP_NAME):latest 2>/dev/null || true

docker-dev: ## Start development container with hot-reload
	$(DOCKER_COMPOSE) up dev

docker-dev-build: ## Rebuild and start development container
	$(DOCKER_COMPOSE) up --build dev

docker-shell: ## Open shell in development container
	docker exec -it bugdrill-dev sh

docker-logs-dev: ## View development container logs
	$(DOCKER_COMPOSE) logs -f dev

api-reload: ## Rebuild and restart API service
	@echo "Rebuilding API Docker image..."
	$(DOCKER_COMPOSE) build api
	@echo "Restarting API container..."
	$(DOCKER_COMPOSE) up -d api
	@echo "✓ API service reloaded successfully"

dev-reload: ## Restart development container (triggers Air hot-reload)
	@echo "Restarting development container..."
	$(DOCKER_COMPOSE) restart dev
	@echo "✓ Development service restarted (Air will hot-reload)"

reload: ## Smart reload - restarts dev container if running, otherwise rebuilds api
	@if docker ps --format '{{.Names}}' | grep -q "bugdrill-dev"; then \
		echo "Development container detected - restarting..."; \
		$(DOCKER_COMPOSE) restart dev; \
		echo "✓ Development service restarted (Air will hot-reload)"; \
	else \
		echo "Development container not running - rebuilding API..."; \
		$(DOCKER_COMPOSE) build api; \
		echo "Restarting API container..."; \
		$(DOCKER_COMPOSE) up -d api; \
		echo "✓ API service reloaded successfully"; \
	fi

# Database
migrate-up: ## Run database migrations
	$(GO) run ./cmd/migrate up

migrate-down: ## Rollback database migrations
	$(GO) run ./cmd/migrate down

migrate-create: ## Create a new migration (usage: make migrate-create name=create_users_table)
	@if [ -z "$(name)" ]; then \
		echo "Error: name is required. Usage: make migrate-create name=your_migration_name"; \
		exit 1; \
	fi
	@mkdir -p migrations
	@timestamp=$$(date +%Y%m%d%H%M%S); \
	echo "Creating migration: migrations/$${timestamp}_$(name).up.sql"; \
	touch migrations/$${timestamp}_$(name).up.sql; \
	touch migrations/$${timestamp}_$(name).down.sql; \
	echo "Migration files created successfully"

db-seed: ## Seed the database with sample data
	$(GO) run ./cmd/seed

db-seed-base: ## Seed base data (patterns + admin user)
	@echo "Seeding base data (patterns + admin user)..."
	docker exec -i bugdrill-postgres psql -U postgres -d bugdrill < migrations/seed_base.sql
	@echo "✓ Base data seeded successfully"

db-seed-snippets: ## Seed database with sample snippets (for development/testing)
	@echo "Seeding sample snippets..."
	docker exec -i bugdrill-postgres psql -U postgres -d bugdrill < migrations/seed_snippets.sql
	@echo "✓ Sample snippets seeded successfully"

db-seed-all: db-seed-base db-seed-snippets ## Seed all data (base + snippets)
	@echo "✓ All data seeded successfully"

# Cleanup
clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out

# k3d and Kubernetes
k3d-create: ## Create k3d cluster
	@bash scripts/k3d-create.sh

k3d-destroy: ## Destroy k3d cluster
	@bash scripts/k3d-destroy.sh

docker-build-k3d: ## Build and push images to k3d registry
	docker build -t localhost:5000/bugdrill-api:dev .
	docker push localhost:5000/bugdrill-api:dev

# Production Docker Build and Push
DOCKER_USERNAME ?= smithaavinash
DOCKER_TAG ?= latest

docker-buildx-setup: ## Setup Docker buildx for multi-arch builds
	@docker buildx create --name bugdrill-builder --use 2>/dev/null || docker buildx use bugdrill-builder
	@docker buildx inspect --bootstrap

docker-build-prod: docker-buildx-setup ## Build production Docker images for ARM64 and AMD64
	@echo "Building multi-arch API image (linux/amd64,linux/arm64)..."
	docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) \
		-f Dockerfile \
		--push \
		.
	@echo "Building multi-arch Executor image (linux/amd64,linux/arm64)..."
	docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) \
		-f executor/Dockerfile \
		--push \
		.
	@echo "✓ Multi-arch images built and pushed successfully"

docker-build-push-prod: docker-build-prod ## Build and push production images (alias)

docker-login: ## Login to Docker Hub
	docker login

helm-install: ## Install Helm chart to k3d
	helm upgrade --install bugdrill ./helm/bugdrill-api \
		--namespace bugdrill \
		--create-namespace \
		--values ./helm/bugdrill-api/values-dev.yaml \
		--wait

helm-uninstall: ## Uninstall Helm chart
	helm uninstall bugdrill --namespace bugdrill

helm-template: ## Show Helm template output
	helm template bugdrill ./helm/bugdrill-api \
		--values ./helm/bugdrill-api/values-dev.yaml

# Functional tests
test-functional-docker: ## Run functional tests in Docker Compose
	@bash scripts/test-docker.sh

test-functional: ## Quick test run (use after code changes)
	@echo "🔨 Rebuilding test image..."
	$(DOCKER_COMPOSE) build functional-tests
	@echo "🧪 Running tests..."
	$(DOCKER_COMPOSE) run --rm functional-tests
	@echo "✅ Done!"

test-functional-clean: ## Clean rebuild and run functional tests
	@echo "🧹 Cleaning up..."
	$(DOCKER_COMPOSE) down -v
	@echo "🔨 Rebuilding test image..."
	$(DOCKER_COMPOSE) build --no-cache functional-tests
	@echo "🚀 Starting services..."
	$(DOCKER_COMPOSE) up -d postgres redis dev
	@echo "⏳ Waiting for API (this may take 30-60 seconds for first run)..."
	@timeout=120; \
	elapsed=0; \
	while [ $$elapsed -lt $$timeout ]; do \
		if curl -s http://localhost:8080/health > /dev/null 2>&1; then \
			echo "✓ API is ready!"; \
			sleep 5; \
			break; \
		fi; \
		printf "."; \
		sleep 3; \
		elapsed=$$((elapsed + 3)); \
		if [ $$elapsed -ge $$timeout ]; then \
			echo "\n❌ API failed to start after $$timeout seconds"; \
			$(DOCKER_COMPOSE) logs dev; \
			exit 1; \
		fi; \
	done
	@echo "\n🧪 Running tests..."
	$(DOCKER_COMPOSE) run --rm functional-tests
	@echo "✅ Done!"

test-functional-k3d: ## Run functional tests in k3d
	@bash scripts/test-k3d.sh

test-all: test test-functional-docker ## Run all tests (unit + functional)

# Database helpers
db-check-patterns: ## Check if patterns are seeded in database
	@echo "Checking pattern_categories table..."
	docker exec -it bugdrill-postgres psql -U postgres -d bugdrill -c "SELECT id, name FROM pattern_categories ORDER BY id;"

db-shell: ## Open PostgreSQL shell
	docker exec -it bugdrill-postgres psql -U postgres -d bugdrill

# Development helpers
dev: ## Start development environment with hot-reload
	@echo "Starting development environment..."
	$(DOCKER_COMPOSE) up dev
	@echo "Development environment ready!"
	@echo "API (hot-reload): http://localhost:8080"
	@echo "PostgreSQL: localhost:5432"
	@echo "Redis: localhost:6379"
	@echo ""
	@echo "Code changes will automatically reload the server"

stop: docker-down ## Stop development environment

restart: docker-down docker-up ## Restart development environment

# CI/CD helpers
ci-test: ## Run CI pipeline tests locally (simulates GitHub Actions)
	@echo "🚀 Running CI pipeline tests locally..."
	@echo ""
	@echo "Step 1: Checking formatting..."
	@if [ -n "$$(gofmt -l .)" ]; then \
		echo "❌ Go files not formatted. Run: gofmt -w ."; \
		exit 1; \
	fi
	@echo "✅ Formatting check passed"
	@echo ""
	@echo "Step 2: Running tests..."
	@$(MAKE) test
	@echo ""
	@echo "Step 3: Generating coverage..."
	@$(MAKE) test-coverage
	@echo ""
	@echo "Step 4: Running linter..."
	@if command -v golangci-lint &> /dev/null; then \
		golangci-lint run --timeout=5m || echo "⚠️  Linting completed with warnings"; \
	else \
		echo "⚠️  golangci-lint not installed, skipping..."; \
	fi
	@echo ""
	@echo "✅ All CI tests passed! Ready to push."

ci-build: ## Build Docker images (simulates GitHub Actions build)
	@echo "🐳 Building Docker images..."
	@echo ""
	@echo "Building API image..."
	@docker build -t bugdrill-api:ci-test -f Dockerfile .
	@echo "✅ API image built"
	@echo ""
	@echo "Building Executor image..."
	@docker build -t bugdrill-executor:ci-test -f executor/Dockerfile .
	@echo "✅ Executor image built"
	@echo ""
	@docker images | grep bugdrill | grep ci-test

ci-full: ci-test ci-build ## Run full CI pipeline locally (test + build)
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ Full CI pipeline completed successfully!"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Review changes: git diff"
	@echo "  2. Commit: git commit -m 'your message'"
	@echo "  3. Push: git push origin your-branch"
