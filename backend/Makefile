.PHONY: help build run test clean

APP_NAME=bugdrill-api
DOCKER_COMPOSE=docker-compose
GO=go
K3D_CLUSTER_NAME ?= bugdrill-local
K3D_REGISTRY_PORT ?= 5005
K3D_API_PORT ?= 8080
NAMESPACE ?= bugdrill
DOCKER_USERNAME ?= smithaavinash
DOCKER_TAG ?= latest
EC2_NAMESPACE ?= bugdrill
EC2_API_PORT ?= 8080

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-30s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	$(GO) mod download
	$(GO) mod tidy

build: ## Build the application
	$(GO) build -o bin/$(APP_NAME) ./cmd/server

run: ## Run the application locally
	$(GO) run ./cmd/server

test: ## Run tests
	$(GO) test -v ./...

clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out

docker-up: ## Start all services with Docker Compose
	$(DOCKER_COMPOSE) up -d

docker-down: ## Stop all services
	$(DOCKER_COMPOSE) down

docker-buildx-setup: ## Setup Docker buildx for multi-arch builds
	@docker buildx create --name bugdrill-builder --use 2>/dev/null || docker buildx use bugdrill-builder
	@docker buildx inspect --bootstrap

docker-build-local: ## Build local AMD64 images for k3d
	@echo "🔨 Building local AMD64 images..."
	@docker buildx build --platform linux/amd64 --target api -t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) --load .
	@docker buildx build --platform linux/amd64 --target executor -t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) --load .
	@docker buildx build --platform linux/amd64 --target tests -t $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG) --load .
	@echo "✓ Local AMD64 images built"

docker-push-local: ## Push locally built images to Docker Hub
	@echo "📤 Pushing images..."
	@docker push $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG)
	@docker push $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG)
	@docker push $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG)
	@echo "✓ Images pushed"

production-build-push: docker-buildx-setup ## Build and push ARM64 images for production
	@echo "═══════════════════════════════════════════════════"
	@echo "🏗️  BUILDING PRODUCTION ARM64 IMAGES"
	@echo "═══════════════════════════════════════════════════"
	@docker buildx build --platform linux/arm64 --target api -t $(DOCKER_USERNAME)/bugdrill-api:$(DOCKER_TAG) --push .
	@docker buildx build --platform linux/arm64 --target executor -t $(DOCKER_USERNAME)/bugdrill-executor:$(DOCKER_TAG) --push .
	@docker buildx build --platform linux/arm64 --target tests -t $(DOCKER_USERNAME)/bugdrill-tests:$(DOCKER_TAG) --push .
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ ALL PRODUCTION IMAGES READY"
	@echo "═══════════════════════════════════════════════════"
	@echo "Images: $(DOCKER_USERNAME)/bugdrill-{api,executor,tests}:$(DOCKER_TAG)"
	@echo "Next: make ec2-full-deploy (on EC2)"

k3d-destroy: ## Destroy k3d cluster
	@echo "🗑️  Destroying k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster delete $(K3D_CLUSTER_NAME) 2>/dev/null || echo "Cluster doesn't exist"
	@echo "✅ Cluster destroyed"

k3d-create: k3d-destroy ## Create fresh k3d cluster
	@echo "🚀 Creating k3d cluster: $(K3D_CLUSTER_NAME)"
	@k3d cluster create $(K3D_CLUSTER_NAME) --agents 1 --port "80:80@loadbalancer" --port "443:443@loadbalancer" --registry-create k3d-registry.localhost:$(K3D_REGISTRY_PORT) --wait
	@kubectl cluster-info
	@echo "✅ Cluster created"

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

k3d-init-db: ## Initialize database with migrations
	@echo "📊 Initializing database..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-migrations -n $(NAMESPACE) 2>/dev/null || true
	@kubectl create configmap bugdrill-migrations -n $(NAMESPACE) \
		--from-file=init-schema.sql=migrations/001_init_schema.sql \
		--from-file=seed-data.sql=migrations/002_seed_data.sql \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f k3d-manifests/migrations.yaml
	@kubectl wait --for=condition=complete job/bugdrill-migrations -n $(NAMESPACE) --timeout=120s
	@echo "✅ Database initialized"

k3d-deploy-executor: ## Deploy Executor
	@echo "⚙️  Deploying Executor..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/executor.yaml
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(NAMESPACE) --timeout=180s || true
	@echo "✅ Executor deployed"

k3d-deploy-api: ## Deploy API
	@echo "🔧 Deploying API..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/api.yaml
	@sleep 5
	@kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $(NAMESPACE) --timeout=300s
	@echo "✅ API deployed"

k3d-deploy-tests: ## Deploy and run functional tests
	@echo "🧪 Running tests..."
	@kubectl create namespace $(NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-tests -n $(NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/tests.yaml
	@kubectl wait --for=condition=complete job/bugdrill-tests -n $(NAMESPACE) --timeout=300s
	@kubectl logs -n $(NAMESPACE) job/bugdrill-tests
	@echo "✅ Tests passed"

k3d-status: ## Show k3d cluster status
	@echo "📊 Cluster Status"
	@echo "═══════════════════════════════════════════════════"
	@k3d cluster list | grep $(K3D_CLUSTER_NAME) || echo "Cluster not running"
	@kubectl get nodes
	@kubectl get pods -n $(NAMESPACE)
	@kubectl get svc -n $(NAMESPACE)

k3d-logs-api: ## Follow API logs
	@kubectl logs -f -n $(NAMESPACE) -l app=bugdrill-api --tail=50

k3d-logs-executor: ## Follow Executor logs
	@kubectl logs -f -n $(NAMESPACE) -l app=bugdrill-executor --tail=50

k3d-full-rebuild: ## Complete k3d rebuild: build images, destroy cluster, deploy all, run tests
	@echo "═══════════════════════════════════════════════════"
	@echo "🔨 FULL K3D REBUILD CYCLE"
	@echo "═══════════════════════════════════════════════════"
	@$(MAKE) docker-build-local
	@$(MAKE) docker-push-local
	@$(MAKE) k3d-destroy
	@$(MAKE) k3d-create
	@$(MAKE) k3d-deploy-postgres
	@$(MAKE) k3d-deploy-redis
	@$(MAKE) k3d-init-db
	@$(MAKE) k3d-deploy-executor
	@$(MAKE) k3d-deploy-api
	@sleep 15
	@$(MAKE) k3d-deploy-tests
	@$(MAKE) k3d-status
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ FULL REBUILD COMPLETE"
	@echo "═══════════════════════════════════════════════════"
	@echo "API: http://localhost:$(K3D_API_PORT)"

k3d-runner-up: ## Start k3d runner container
	@docker-compose -f docker-compose.k3d.yml up -d
	@echo "✅ k3d runner ready. Use: docker exec -ti bugdrill-k3d-runner bash"
	@echo "📱 Mobile app: Update config.ts to use http://localhost:8080/api/v1"

k3d-runner-down: ## Stop k3d runner container
	@docker-compose -f docker-compose.k3d.yml down

ec2-check-k3s: ## Check if k3s is installed
	@if command -v k3s >/dev/null 2>&1; then \
		echo "✅ k3s is installed"; \
		k3s --version; \
	else \
		echo "❌ k3s is not installed"; \
		exit 1; \
	fi

ec2-fix-kubeconfig: ## Fix kubectl permissions
	@echo "🔧 Fixing kubeconfig..."
	@sudo chmod 644 /etc/rancher/k3s/k3s.yaml
	@mkdir -p $$HOME/.kube
	@sudo cp /etc/rancher/k3s/k3s.yaml $$HOME/.kube/config
	@sudo chown $$USER:$$USER $$HOME/.kube/config
	@echo "✅ Kubeconfig fixed"
	@echo "Add to ~/.bashrc: export KUBECONFIG=~/.kube/config"

ec2-install-k3s: ## Install k3s on EC2
	@echo "📦 Installing k3s..."
	@if command -v k3s >/dev/null 2>&1; then \
		echo "⚠️  k3s already installed. Use 'make ec2-rebuild-k3s' to reinstall"; \
		k3s --version; \
	else \
		curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644; \
		sleep 10; \
		sudo k3s kubectl wait --for=condition=ready node --all --timeout=60s; \
		sudo chmod 644 /etc/rancher/k3s/k3s.yaml; \
		mkdir -p $$HOME/.kube; \
		sudo cp /etc/rancher/k3s/k3s.yaml $$HOME/.kube/config; \
		sudo chown $$USER:$$USER $$HOME/.kube/config; \
		echo "✅ k3s installed"; \
		echo "Add to ~/.bashrc: export KUBECONFIG=~/.kube/config"; \
	fi

ec2-uninstall-k3s: ## Uninstall k3s
	@echo "🗑️  Uninstalling k3s..."
	@if command -v k3s-uninstall.sh >/dev/null 2>&1; then \
		sudo k3s-uninstall.sh; \
		echo "✅ k3s uninstalled"; \
	else \
		echo "⚠️  k3s not installed"; \
	fi

ec2-rebuild-k3s: ec2-uninstall-k3s ec2-install-k3s ## Rebuild k3s from scratch
	@echo "✅ k3s rebuilt"

ec2-clean-namespace: ## Clean bugdrill namespace
	@echo "🧹 Cleaning namespace..."
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

ec2-init-db: ## Initialize database on EC2
	@echo "📊 Initializing database..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-migrations -n $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl create configmap bugdrill-migrations -n $(EC2_NAMESPACE) \
		--from-file=init-schema.sql=migrations/001_init_schema.sql \
		--from-file=seed-data.sql=migrations/002_seed_data.sql \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f k3d-manifests/migrations.yaml
	@kubectl wait --for=condition=complete job/bugdrill-migrations -n $(EC2_NAMESPACE) --timeout=120s
	@echo "✅ Database initialized"

ec2-deploy-executor: ## Deploy Executor on EC2
	@echo "⚙️  Deploying Executor..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/executor.yaml
	@kubectl wait --for=condition=ready pod -l app=bugdrill-executor -n $(EC2_NAMESPACE) --timeout=180s || true
	@echo "✅ Executor deployed"

ec2-deploy-api: ## Deploy API on EC2
	@echo "🔧 Deploying API..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/api.yaml
	@sleep 5
	@kubectl wait --for=condition=ready pod -l app=bugdrill-api -n $(EC2_NAMESPACE) --timeout=300s
	@echo "✅ API deployed"

ec2-deploy-tests: ## Run functional tests on EC2
	@echo "🧪 Running tests..."
	@kubectl create namespace $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl delete job bugdrill-tests -n $(EC2_NAMESPACE) 2>/dev/null || true
	@kubectl apply -f k3d-manifests/tests.yaml
	@kubectl wait --for=condition=complete job/bugdrill-tests -n $(EC2_NAMESPACE) --timeout=300s
	@kubectl logs -n $(EC2_NAMESPACE) job/bugdrill-tests
	@echo "✅ Tests passed"

ec2-status: ## Show EC2 cluster status
	@echo "📊 EC2 k3s Cluster Status"
	@echo "═══════════════════════════════════════════════════"
	@kubectl get nodes
	@kubectl get pods -n $(EC2_NAMESPACE)
	@kubectl get svc -n $(EC2_NAMESPACE)

ec2-full-deploy: ## Complete EC2 deployment
	@echo "═══════════════════════════════════════════════════"
	@echo "🚀 EC2 PRODUCTION DEPLOYMENT"
	@echo "═══════════════════════════════════════════════════"
	@$(MAKE) ec2-clean-namespace
	@$(MAKE) ec2-deploy-postgres
	@$(MAKE) ec2-deploy-redis
	@$(MAKE) ec2-init-db
	@$(MAKE) ec2-deploy-executor
	@$(MAKE) ec2-deploy-api
	@sleep 15
	@$(MAKE) ec2-deploy-tests
	@$(MAKE) ec2-status
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ EC2 DEPLOYMENT COMPLETE"
	@echo "═══════════════════════════════════════════════════"

ec2-full-rebuild: ## Complete rebuild: k3s + full deployment
	@echo "═══════════════════════════════════════════════════"
	@echo "🔨 COMPLETE EC2 REBUILD"
	@echo "═══════════════════════════════════════════════════"
	@$(MAKE) ec2-rebuild-k3s
	@$(MAKE) ec2-full-deploy
	@echo "═══════════════════════════════════════════════════"
	@echo "✅ COMPLETE REBUILD FINISHED"
	@echo "═══════════════════════════════════════════════════"
