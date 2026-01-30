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
