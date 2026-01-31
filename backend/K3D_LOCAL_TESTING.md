# K3d Local Testing Guide

This guide explains how to run the complete BugDrill stack locally using k3d (lightweight Kubernetes) for testing before deploying to AWS EC2.

## Overview

The k3d testing environment provides:
- **Identical environment** to production EC2 deployment
- **Full stack deployment** (PostgreSQL, Redis, API, Executor)
- **Automated testing** with functional tests running as Kubernetes jobs
- **Fast iteration** with component-level redeployment
- **Works everywhere** - runs in Docker, so works on Windows, Mac, Linux

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Docker Container (Linux)                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │  k3d Cluster                                       │  │
│  │  ┌──────────┐  ┌────────┐  ┌───────┐  ┌────────┐ │  │
│  │  │PostgreSQL│  │ Redis  │  │  API  │  │Executor│ │  │
│  │  └──────────┘  └────────┘  └───────┘  └────────┘ │  │
│  │  ┌──────────────────────────────────────────────┐ │  │
│  │  │  Functional Tests (Job)                      │ │  │
│  │  └──────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker Desktop (or Docker Engine with Docker Compose)
- Make

That's it! Everything else runs inside Docker.

## Quick Start

### Option 1: Automated Testing (Recommended)

Run the complete cycle in one command:

```bash
# Build the k3d runner, start it, and run full deployment + tests
make test-local-k3d
```

This will:
1. Build the k3d runner Docker image
2. Start the container with Docker-in-Docker
3. Create k3d cluster inside the container
4. Deploy PostgreSQL, Redis, Executor, and API
5. Run database migrations
6. Execute functional tests
7. Show status

### Option 2: Manual Control

For more control over individual steps:

```bash
# 1. Build and start the k3d runner container
make k3d-runner-build
make k3d-runner-up

# 2. Run the full cycle inside the container
make k3d-exec CMD="make full-cycle-k3d"

# 3. Check status
make k3d-exec CMD="make k3d-status"

# 4. View API logs
make k3d-exec CMD="make k3d-logs-api"
```

### Option 3: Interactive Shell

Get a shell inside the container and run commands directly:

```bash
# Open shell in k3d runner
make k3d-shell

# Inside the container, run any make command:
make full-cycle-k3d
make k3d-status
make k3d-logs-api
curl http://localhost:8080/health
```

## Available Make Targets

### Container Management

| Target | Description |
|--------|-------------|
| `make k3d-runner-build` | Build the k3d runner Docker image |
| `make k3d-runner-up` | Start the k3d runner container |
| `make k3d-runner-down` | Stop the k3d runner container |
| `make k3d-runner-clean` | Remove container and volumes |
| `make k3d-shell` | Open interactive shell in container |
| `make k3d-exec CMD="..."` | Execute command in container |

### Cluster Lifecycle

| Target | Description |
|--------|-------------|
| `make full-cycle-k3d` | Complete workflow: destroy → create → deploy → test |
| `make k3d-create` | Create fresh k3d cluster |
| `make k3d-destroy` | Destroy k3d cluster |
| `make k3d-start` | Start stopped cluster |
| `make k3d-stop` | Stop cluster without destroying |
| `make k3d-status` | Show cluster and deployment status |

### Component Deployment

| Target | Description |
|--------|-------------|
| `make k3d-deploy-postgres` | Deploy PostgreSQL |
| `make k3d-deploy-redis` | Deploy Redis |
| `make k3d-deploy-api` | Deploy API from Docker Hub |
| `make k3d-deploy-executor` | Deploy Executor from Docker Hub |
| `make k3d-init-db` | Run database migrations |
| `make k3d-deploy-tests` | Run functional tests as Job |

### Individual Component Updates

| Target | Description |
|--------|-------------|
| `make k3d-redeploy-api` | Redeploy just the API (after pushing new image) |
| `make k3d-redeploy-executor` | Redeploy just the Executor |
| `make k3d-restart-api` | Restart API deployment |
| `make k3d-restart-executor` | Restart Executor deployment |

### Logging and Debugging

| Target | Description |
|--------|-------------|
| `make k3d-logs-api` | Follow API logs |
| `make k3d-logs-executor` | Follow Executor logs |
| `make k3d-logs-tests` | Show test logs |

## Common Workflows

### 1. Testing After Code Changes

```bash
# 1. Build and push new Docker images
make docker-build-prod

# 2. Redeploy in k3d
make k3d-exec CMD="make k3d-redeploy-api"

# 3. Run tests
make k3d-exec CMD="make k3d-deploy-tests"
```

### 2. Testing Just the API

```bash
# Redeploy only the API component
make k3d-exec CMD="make k3d-redeploy-api"
```

### 3. Fresh Start

```bash
# Destroy everything and start from scratch
make k3d-exec CMD="make full-cycle-k3d"
```

### 4. Debugging Failed Deployments

```bash
# Get into the container
make k3d-shell

# Inside container:
kubectl get pods -n bugdrill
kubectl describe pod <pod-name> -n bugdrill
kubectl logs <pod-name> -n bugdrill
```

## Environment Variables

You can customize the deployment with environment variables:

```bash
# Use different Docker Hub username
export DOCKER_USERNAME=myusername

# Use different image tag
export DOCKER_TAG=v1.0.0

# Then run
make test-local-k3d
```

Available variables:
- `DOCKER_USERNAME` - Docker Hub username (default: smithaavinash)
- `DOCKER_TAG` - Image tag to use (default: latest)
- `K3D_CLUSTER_NAME` - Cluster name (default: bugdrill-local)
- `K3D_API_PORT` - API port mapping (default: 8080)
- `NAMESPACE` - Kubernetes namespace (default: bugdrill)

## Testing on EC2

The exact same commands work on your EC2 instance! Just SSH in and run:

```bash
# On EC2 Ubuntu instance
cd /path/to/bugdrill/backend

# Run the full cycle
make full-cycle-k3d
```

No Docker container needed on EC2 since it's already Linux.

## Troubleshooting

### Container won't start

```bash
# Clean everything and rebuild
make k3d-runner-clean
make k3d-runner-build
make k3d-runner-up
```

### API keeps restarting

```bash
# Check API logs
make k3d-exec CMD="make k3d-logs-api"

# Check pod description
make k3d-shell
kubectl describe pod -n bugdrill -l app=bugdrill-api
```

### Tests failing

```bash
# View test logs
make k3d-exec CMD="make k3d-logs-tests"

# Check API is healthy
make k3d-shell
curl http://bugdrill-api:8080/health
```

### Permission denied errors

This usually means the binary doesn't have execute permissions. We've fixed this in the Dockerfile with `RUN chmod +x ./main`.

### Database connection errors

```bash
# Check if PostgreSQL is ready
make k3d-shell
kubectl get pods -n bugdrill -l app.kubernetes.io/name=postgresql

# Check migrations ran
kubectl logs -n bugdrill job/bugdrill-migrations
```

## Cleanup

```bash
# Stop and remove everything
make k3d-runner-clean
```

This removes:
- The k3d runner container
- All Docker volumes
- The k3d cluster inside

## Architecture Notes

### Why Docker-in-Docker?

We run k3d inside a Docker container because:
1. **Consistency**: Same environment on Windows, Mac, Linux, and EC2
2. **Isolation**: k3d cluster is contained and easy to clean up
3. **Portability**: Works identically on dev machines and CI/CD
4. **Safety**: Can't mess up your host system

### Component Communication

Inside the k3d cluster:
- API connects to PostgreSQL via `bugdrill-postgres-postgresql:5432`
- API connects to Redis via `bugdrill-redis-master:6379`
- API connects to Executor via `http://bugdrill-executor:8081`
- Tests connect to API via `http://bugdrill-api:8080`

All services use Kubernetes DNS for discovery.

## Next Steps

After successful k3d testing:
1. Push your images: `make docker-build-prod`
2. Deploy to EC2: Follow the deployment guide
3. The k3d setup validates everything works before production deployment!
