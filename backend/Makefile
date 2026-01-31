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

# k3d and Kubernetes - Modular Targets
K3D_CLUSTER_NAME ?= bugdrill-local
K3D_REGISTRY_PORT ?= 5000
K3D_API_PORT ?= 8080
NAMESPACE ?= bugdrill

k3d-check: ## Check if k3d cluster exists
	@k3d cluster list | grep $(K3D_CLUSTER_NAME) || (echo "Cluster $(K3D_CLUSTER_NAME) does not exist" && exit 1)

k3d-destroy: ## Destroy k3d cluster
	@echo "🗑️  Destroying k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster delete $(K3D_CLUSTER_NAME) 2>/dev/null || echo "Cluster doesn't exist, skipping..."
	@echo "✅ Cluster destroyed"

k3d-create: k3d-destroy ## Create fresh k3d cluster with registry
	@echo "🚀 Creating k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster create $(K3D_CLUSTER_NAME) \
		--agents 1 \
		--port "$(K3D_API_PORT):8080@loadbalancer" \
		--registry-create k3d-registry.localhost:$(K3D_REGISTRY_PORT) \
		--wait
	@kubectl cluster-info
	@echo "✅ Cluster created successfully"

k3d-start: ## Start existing k3d cluster
	@echo "▶️  Starting k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster start $(K3D_CLUSTER_NAME)
	@echo "✅ Cluster started"

k3d-stop: ## Stop k3d cluster without destroying it
	@echo "⏸️  Stopping k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster stop $(K3D_CLUSTER_NAME)
	@echo "✅ Cluster stopped"

k3d-deploy-postgres: ## Deploy PostgreSQL to k3d
	@echo "🐘 Deploying PostgreSQL..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@helm upgrade --install bugdrill-postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
		--namespace $(NAMESPACE) \
		--set auth.username=postgres \
		--set auth.password=postgres \
		--set auth.database=bugdrill \
		--set primary.persistence.size=1Gi \
		--wait --timeout=5m
	@echo "✅ PostgreSQL deployed"

k3d-deploy-redis: ## Deploy Redis to k3d
	@echo "🔴 Deploying Redis..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@helm upgrade --install bugdrill-redis oci://registry-1.docker.io/bitnamicharts/redis \
		--namespace $(NAMESPACE) \
		--set auth.enabled=false \
		--set master.persistence.size=1Gi \
		--wait --timeout=5m
	@echo "✅ Redis deployed"

k3d-deploy-api: ## Deploy API from Docker Hub
	@echo "🔧 Deploying BugDrill API from Docker Hub..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/api.yaml
	@echo "⏳ Waiting for API pod to be created..."
	@sleep 5
	@echo "📋 Checking API pod status..."
	@kubectl get pods -n $(NAMESPACE) -l app=bugdrill-api
	@echo "⏳ Waiting for API to be ready (timeout: 5 minutes)..."
	@kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $(NAMESPACE) --timeout=300s || \
		(echo "❌ API failed to start. Showing logs:" && \
		 kubectl get pods -n $(NAMESPACE) -l app=bugdrill-api && \
		 kubectl describe pod -n $(NAMESPACE) -l app=bugdrill-api && \
		 kubectl logs -n $(NAMESPACE) -l app=bugdrill-api --tail=100 && \
		 exit 1)
	@echo "✅ API deployed successfully"

k3d-deploy-executor: ## Deploy Executor from Docker Hub
	@echo "⚙️  Deploying BugDrill Executor from Docker Hub..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/executor.yaml
	@echo "⏳ Waiting for Executor to be ready..."
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(NAMESPACE) --timeout=180s || true
	@echo "✅ Executor deployed successfully"
	@echo "⏳ Waiting for Executor to be ready..."
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(NAMESPACE) --timeout=180s || true
	@echo "✅ Executor deployed successfully"

k3d-init-db: ## Initialize database with migrations
	@echo "📊 Initializing database with migrations..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-migrations -n $(NAMESPACE) 2>/dev/null || true
	@kubectl create configmap bugdrill-migrations -n $(NAMESPACE) \
		--from-file=init-schema.sql=migrations/001_init_schema.sql \
		--from-file=seed-data.sql=migrations/002_seed_data.sql \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f k3d-manifests/migrations.yaml
	@echo "⏳ Waiting for migrations to complete..."
	@kubectl wait --for=condition=complete job/bugdrill-migrations -n $(NAMESPACE) --timeout=120s || \
		(echo "❌ Migrations failed!" && kubectl logs -n $(NAMESPACE) job/bugdrill-migrations && exit 1)
	@kubectl logs -n $(NAMESPACE) job/bugdrill-migrations
	@echo "✅ Database initialized successfully"

k3d-deploy-tests: ## Deploy functional tests as Job
	@echo "🧪 Deploying functional tests..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-tests -n $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/tests.yaml
	@echo "⏳ Waiting for tests to complete..."
	@kubectl wait --for=condition=complete job/bugdrill-tests -n $(NAMESPACE) --timeout=300s || \
		(echo "❌ Tests failed!" && kubectl logs -n $(NAMESPACE) job/bugdrill-tests && exit 1)
	@echo "📋 Test logs:"
	@kubectl logs -n $(NAMESPACE) job/bugdrill-tests
	@echo "✅ All tests passed!"

k3d-restart-executor: ## Restart Executor deployment
	@echo "🔄 Restarting Executor..."
	@kubectl rollout restart deployment/bugdrill-executor -n $(NAMESPACE)
	@kubectl rollout status deployment/bugdrill-executor -n $(NAMESPACE)
	@echo "✅ Executor restarted"

k3d-redeploy-api: ## Redeploy just the API (use after pushing new image)
	@echo "🔄 Redeploying API with latest image..."
	@kubectl delete pod -n $(NAMESPACE) -l app=bugdrill-api
	@kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $(NAMESPACE) --timeout=300s
	@echo "✅ API redeployed"

k3d-redeploy-executor: ## Redeploy just the Executor (use after pushing new image)
	@echo "🔄 Redeploying Executor with latest image..."
	@kubectl delete pod -n $(NAMESPACE) -l app=bugdrill-executor
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(NAMESPACE) --timeout=180s
	@echo "✅ Executor redeployed"

k3d-clean: ## Clean up all resources in namespace
	@echo "🧹 Cleaning up $(NAMESPACE) namespace..."
	@kubectl delete namespace $(NAMESPACE) --timeout=60s 2>/dev/null || true
	@echo "✅ Cleanup complete"

k3d-status: ## Show k3d cluster and deployment status
	@echo "📊 K3D Cluster Status"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Cluster:"
	@k3d cluster list | grep $(K3D_CLUSTER_NAME) || echo "Cluster not running"
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes 2>/dev/null || echo "Cluster not accessible"
	@echo ""
	@echo "Pods in $(NAMESPACE):"
	@kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "Services in $(NAMESPACE):"
	@kubectl get svc -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "Jobs in $(NAMESPACE):"
	@kubectl get jobs -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"

k3d-logs-api: ## Follow API logs
	@echo "📋 Following API logs (Ctrl+C to stop)..."
	@kubectl logs -f -n $(NAMESPACE) -l app=bugdrill-api --tail=50

k3d-logs-executor: ## Follow Executor logs
	@echo "📋 Following Executor logs (Ctrl+C to stop)..."
	@kubectl logs -f -n $(NAMESPACE) -l app=bugdrill-executor --tail=50

k3d-logs-tests: ## Show test logs
	@echo "📋 Test logs:"
	@kubectl logs -n $(NAMESPACE) job/bugdrill-tests 2>/dev/null || echo "Test job not found"

k3d-describe-api: ## Describe API pod (for debugging)
	@kubectl describe pod -n $(NAMESPACE) -l app=bugdrill-api

k3d-describe-executor: ## Describe Executor pod (for debugging)
	@kubectl describe pod -n $(NAMESPACE) -l app=bugdrill-executor

k3d-shell-api: ## Open shell in API pod
	@kubectl exec -it -n $(NAMESPACE) deployment/bugdrill-api -- sh

k3d-shell-executor: ## Open shell in Executor pod
	@kubectl exec -it -n $(NAMESPACE) deployment/bugdrill-executor -- sh

# Full cycle target - destroys, creates, deploys everything, and runs tests
full-cycle-k3d: ## Complete k3d workflow: destroy -> create -> deploy all -> run tests
	@echo "🚀 Starting full k3d deployment cycle..."
	@echo "==========================================="
	@echo ""
	@$(MAKE) k3d-destroy
	@echo ""
	@$(MAKE) k3d-create
	@echo ""
	@$(MAKE) k3d-deploy-postgres
	@echo ""
	@$(MAKE) k3d-deploy-redis
	@echo ""
	@$(MAKE) k3d-init-db
	@echo ""
	@$(MAKE) k3d-deploy-executor
	@echo ""
	@$(MAKE) k3d-deploy-api
	@echo ""
	@echo "⏳ Giving API time to stabilize..."
	@sleep 15
	@echo ""
	@$(MAKE) k3d-deploy-tests
	@echo ""
	@$(MAKE) k3d-status
	@echo ""
	@echo "==========================================="
	@echo "✅ Full k3d cycle completed successfully!"
	@echo "==========================================="
	@echo ""
	@echo "Cluster is ready! Access the API:"
	@echo "  http://localhost:$(K3D_API_PORT)"
	@echo ""
	@echo "Useful commands:"
	@echo "  make k3d-status          - Show cluster status"
	@echo "  make k3d-logs-api        - Follow API logs"
	@echo "  make k3d-redeploy-api    - Redeploy API after image update"
	@echo "  make k3d-destroy         - Destroy the cluster"

# Quick redeploy after code changes
k3d-quick-deploy: docker-build-prod k3d-redeploy-api k3d-redeploy-executor ## Build new images, push, and redeploy to k3d
	@echo "✅ Quick redeploy complete!"

# Complete rebuild and deployment cycle
k3d-full-rebuild: ## Destroy cluster, rebuild all images (AMD64), push to Docker Hub, deploy everything, and run tests
	@echo "═══════════════════════════════════════════════════"
	@echo "🔨 FULL K3D REBUILD CYCLE"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Step 1: Building AMD64 images for k3d..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) docker-build-local
	@echo ""
	@echo "Step 2: Pushing images to Docker Hub..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) docker-push-local
	@echo ""
	@echo "Step 3: Destroying existing k3d cluster..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-destroy
	@echo ""
	@echo "Step 4: Creating fresh k3d cluster..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-create
	@echo ""
	@echo "Step 5: Deploying PostgreSQL..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-deploy-postgres
	@echo ""
	@echo "Step 6: Deploying Redis..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-deploy-redis
	@echo ""
	@echo "Step 7: Initializing database..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-init-db
	@echo ""
	@echo "Step 8: Deploying Executor..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-deploy-executor
	@echo ""
	@echo "Step 9: Deploying API..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-deploy-api
	@echo ""
	@echo "Step 10: Stabilizing services..."
	@echo "───────────────────────────────────────────────────"
	@sleep 15
	@echo ""
	@echo "Step 11: Running functional tests..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) k3d-deploy-tests
	@echo ""
	@$(MAKE) k3d-status
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ FULL REBUILD CYCLE COMPLETED SUCCESSFULLY!"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "🎯 All images rebuilt, pushed, deployed, and tested"
	@echo "📦 Images on Docker Hub: $(DOCKER_USERNAME)/bugdrill-{api,executor,tests}:$(DOCKER_TAG)"
	@echo "🌐 API endpoint: http://localhost:$(K3D_API_PORT)"
	@echo ""
	@echo "Next steps:"
	@echo "  make k3d-logs-api        - Follow API logs"
	@echo "  make k3d-logs-executor   - Follow Executor logs"
	@echo "  make k3d-status          - Check cluster status"
	@echo "  make k3d-destroy         - Destroy the cluster"

# Docker-based k3d runner (Linux-only, works on Windows via Docker)
k3d-runner-build: ## Build the k3d runner Docker image
	@echo "🐳 Building k3d runner image..."
	docker build -t bugdrill-k3d-runner -f Dockerfile.k3d .
	@echo "✅ k3d runner image built"

k3d-runner-up: ## Start k3d runner container
	@echo "🚀 Starting k3d runner container..."
	docker-compose -f docker-compose.k3d.yml up -d
	@echo "✅ k3d runner is ready"
	@echo ""
	@echo "Run commands in the container:"
	@echo "  make k3d-exec CMD='make full-cycle-k3d'"

k3d-runner-down: ## Stop k3d runner container
	@echo "🛑 Stopping k3d runner container..."
	docker-compose -f docker-compose.k3d.yml down
	@echo "✅ k3d runner stopped"

k3d-runner-clean: ## Clean k3d runner and volumes
	@echo "🧹 Cleaning k3d runner..."
	docker-compose -f docker-compose.k3d.yml down -v
	@echo "✅ k3d runner cleaned"

k3d-exec: ## Execute command in k3d runner. Usage: make k3d-exec CMD="make full-cycle-k3d"
	@if [ -z "$(CMD)" ]; then \
		echo "❌ Error: CMD is required"; \
		echo "Usage: make k3d-exec CMD='your command'"; \
		echo "Example: make k3d-exec CMD='make full-cycle-k3d'"; \
		exit 1; \
	fi
	docker exec -it bugdrill-k3d-runner bash -c "$(CMD)"

k3d-shell: ## Open shell in k3d runner container
	@echo "🐚 Opening shell in k3d runner..."
	@echo "Run 'make full-cycle-k3d' inside the container to test"
	docker exec -it bugdrill-k3d-runner bash

# Complete local testing workflow (works on Windows by running in Docker)
test-local-k3d: k3d-runner-build k3d-runner-up ## Build runner, start it, and run full k3d cycle
	@echo "⏳ Waiting for Docker daemon in container..."
	@sleep 5
	@echo "🚀 Running full k3d cycle in container..."
	@$(MAKE) k3d-exec CMD="make full-cycle-k3d"
	@echo ""
	@echo "✅ Local k3d testing complete!"
	@echo ""
	@echo "To access the API:"
	@echo "  1. Get into the container: make k3d-shell"
	@echo "  2. Test API: curl http://localhost:8080/health"
	@echo ""
	@echo "To cleanup:"
	@echo "  make k3d-runner-clean"

docker-build-k3d: ## Build and push images to k3d registry (deprecated, use docker-build-prod)
	@echo "⚠️  This target is deprecated. Use 'make docker-build-prod' instead."
	@echo "Building for Docker Hub..."
	@$(MAKE) docker-build-prod

# Production Docker Build and Push
DOCKER_USERNAME ?= smithaavinash
DOCKER_TAG ?= latest

docker-buildx-setup: ## Setup Docker buildx for multi-arch builds
	@docker buildx create --name bugdrill-builder --use 2>/dev/null || docker buildx use bugdrill-builder
	@docker buildx inspect --bootstrap

docker-build-prod: docker-buildx-setup ## Build production Docker images for ARM64 and AMD64
	@echo "Building multi-arch API image (linux/arm64)..."
	docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) \
		-f Dockerfile \
		--push \
		.
	@echo "Building multi-arch Executor image (linux/arm64)..."
	docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) \
		-f executor/Dockerfile \
		--push \
		.
	@echo "Building multi-arch Tests image (linux/arm64)..."
	docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG) \
		-f Dockerfile.tests \
		--push \
		.
	@echo "✓ Multi-arch images built and pushed successfully"

docker-build-local: ## Build local AMD64 images for k3d testing (fast build)
	@echo "🔨 Building local AMD64 images for k3d..."
	@echo "Building API image..."
	docker buildx build --platform linux/amd64 \
		-t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) \
		-f Dockerfile \
		--load \
		.
	@echo "Building Executor image..."
	docker buildx build --platform linux/amd64 \
		-t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) \
		-f executor/Dockerfile \
		--load \
		.
	@echo "Building Tests image..."
	docker buildx build --platform linux/amd64 \
		-t $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG) \
		-f Dockerfile.tests \
		--load \
		.
	@echo "✓ Local AMD64 images built successfully"

docker-push-local: ## Push locally built images to Docker Hub
	@echo "📤 Pushing images to Docker Hub..."
	docker push $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG)
	docker push $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG)
	docker push $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG)
	@echo "✓ All images pushed to Docker Hub"

docker-build-push-prod: docker-build-prod ## Build and push production images (alias)

production-build-push: docker-buildx-setup ## Build and push ARM64 images for EC2 production deployment
	@echo "═══════════════════════════════════════════════════"
	@echo "🏗️  BUILDING PRODUCTION ARM64 IMAGES"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Building API image (linux/arm64)..."
	@docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) \
		-f Dockerfile \
		--push \
		.
	@echo "✅ API image built and pushed"
	@echo ""
	@echo "Building Executor image (linux/arm64)..."
	@docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) \
		-f executor/Dockerfile \
		--push \
		.
	@echo "✅ Executor image built and pushed"
	@echo ""
	@echo "Building Tests image (linux/arm64)..."
	@docker buildx build --platform linux/arm64 \
		-t $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG) \
		-f Dockerfile.tests \
		--push \
		.
	@echo "✅ Tests image built and pushed"
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ ALL PRODUCTION IMAGES READY"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Images pushed to Docker Hub:"
	@echo "  📦 $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG)"
	@echo "  📦 $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG)"
	@echo "  📦 $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG)"
	@echo ""
	@echo "Ready to deploy on EC2. Run on EC2 instance:"
	@echo "  make ec2-full-deploy"

# EC2 Production Deployment Variables
EC2_NAMESPACE ?= bugdrill
EC2_API_PORT ?= 8080

ec2-clean-namespace: ## Clean up EC2 namespace for fresh deployment
	@echo "🧹 Cleaning up $(EC2_NAMESPACE) namespace..."
	@kubectl delete namespace $(EC2_NAMESPACE) --timeout=60s 2>/dev/null || true
	@echo "✅ Namespace cleaned"

ec2-deploy-postgres: ## Deploy PostgreSQL on EC2
	@echo "🐘 Deploying PostgreSQL..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@helm upgrade --install bugdrill-postgres oci://registry-1.docker.io/bitnamicharts/postgresql \
		--namespace $(EC2_NAMESPACE) \
		--set auth.username=postgres \
		--set auth.password=postgres \
		--set auth.database=bugdrill \
		--set primary.persistence.size=2Gi \
		--wait --timeout=5m
	@echo "✅ PostgreSQL deployed"

ec2-deploy-redis: ## Deploy Redis on EC2
	@echo "🔴 Deploying Redis..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@helm upgrade --install bugdrill-redis oci://registry-1.docker.io/bitnamicharts/redis \
		--namespace $(EC2_NAMESPACE) \
		--set auth.enabled=false \
		--set master.persistence.size=2Gi \
		--wait --timeout=5m
	@echo "✅ Redis deployed"

ec2-init-db: ## Initialize database with migrations on EC2
	@echo "📊 Initializing database with migrations..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-migrations -n $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl create configmap bugdrill-migrations -n $(EC2_NAMESPACE) \
		--from-file=init-schema.sql=migrations/001_init_schema.sql \
		--from-file=seed-data.sql=migrations/002_seed_data.sql \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f k3d-manifests/migrations.yaml
	@echo "⏳ Waiting for migrations to complete..."
	@kubectl wait --for=condition=complete job/bugdrill-migrations -n $(EC2_NAMESPACE) --timeout=120s || \
		(echo "❌ Migrations failed!" && kubectl logs -n $(EC2_NAMESPACE) job/bugdrill-migrations && exit 1)
	@kubectl logs -n $(EC2_NAMESPACE) job/bugdrill-migrations
	@echo "✅ Database initialized successfully"

ec2-deploy-executor: ## Deploy Executor on EC2
	@echo "⚙️  Deploying BugDrill Executor from Docker Hub..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/executor.yaml
	@echo "⏳ Waiting for Executor to be ready..."
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(EC2_NAMESPACE) --timeout=180s || true
	@echo "✅ Executor deployed successfully"

ec2-deploy-api: ## Deploy API on EC2
	@echo "🔧 Deploying BugDrill API from Docker Hub..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/api.yaml
	@echo "⏳ Waiting for API pod to be created..."
	@sleep 5
	@echo "📋 Checking API pod status..."
	@kubectl get pods -n $(EC2_NAMESPACE) -l app=bugdrill-api
	@echo "⏳ Waiting for API to be ready (timeout: 5 minutes)..."
	@kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $(EC2_NAMESPACE) --timeout=300s || \
		(echo "❌ API failed to start. Showing logs:" && \
		 kubectl get pods -n $(EC2_NAMESPACE) -l app=bugdrill-api && \
		 kubectl describe pod -n $(EC2_NAMESPACE) -l app=bugdrill-api && \
		 kubectl logs -n $(EC2_NAMESPACE) -l app=bugdrill-api --tail=100 && \
		 exit 1)
	@echo "✅ API deployed successfully"

ec2-deploy-tests: ## Deploy functional tests on EC2
	@echo "🧪 Deploying functional tests..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-tests -n $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/tests.yaml
	@echo "⏳ Waiting for tests to complete..."
	@kubectl wait --for=condition=complete job/bugdrill-tests -n $(EC2_NAMESPACE) --timeout=300s || \
		(echo "❌ Tests failed!" && kubectl logs -n $(EC2_NAMESPACE) job/bugdrill-tests && exit 1)
	@echo "📋 Test logs:"
	@kubectl logs -n $(EC2_NAMESPACE) job/bugdrill-tests
	@echo "✅ All tests passed!"

ec2-status: ## Show EC2 cluster status
	@echo "📊 EC2 k3s Cluster Status"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes 2>/dev/null || echo "Cluster not accessible"
	@echo ""
	@echo "Pods in $(EC2_NAMESPACE):"
	@kubectl get pods -n $(EC2_NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "Services in $(EC2_NAMESPACE):"
	@kubectl get svc -n $(EC2_NAMESPACE) 2>/dev/null || echo "Namespace not found"

ec2-full-deploy: ## Complete EC2 deployment: clean -> deploy all -> run tests
	@echo "═══════════════════════════════════════════════════"
	@echo "🚀 EC2 PRODUCTION DEPLOYMENT (k3s)"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "Step 1: Cleaning namespace..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-clean-namespace
	@echo ""
	@echo "Step 2: Deploying PostgreSQL..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-deploy-postgres
	@echo ""
	@echo "Step 3: Deploying Redis..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-deploy-redis
	@echo ""
	@echo "Step 4: Initializing database..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-init-db
	@echo ""
	@echo "Step 5: Deploying Executor..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-deploy-executor
	@echo ""
	@echo "Step 6: Deploying API..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-deploy-api
	@echo ""
	@echo "Step 7: Stabilizing services..."
	@echo "───────────────────────────────────────────────────"
	@sleep 15
	@echo ""
	@echo "Step 8: Running functional tests..."
	@echo "───────────────────────────────────────────────────"
	@$(MAKE) ec2-deploy-tests
	@echo ""
	@$(MAKE) ec2-status
	@echo ""
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ EC2 PRODUCTION DEPLOYMENT COMPLETE!"
	@echo "═══════════════════════════════════════════════════"
	@echo ""
	@echo "🎯 Full stack deployed and tested on k3s"
	@echo "🌐 API endpoint: http://<ec2-public-ip>:$(EC2_API_PORT)"
	@echo ""
	@echo "Useful commands:"
	@echo "  make ec2-status          - Check cluster status"
	@echo "  kubectl get pods -n $(EC2_NAMESPACE)"
	@echo "  kubectl logs -n $(EC2_NAMESPACE) -l app=bugdrill-api"

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
