# CI/CD Pipeline Documentation

This document explains the GitHub Actions workflows for BugDrill.

## Overview

We have two main workflows:

1. **ci-cd.yml** - Main CI/CD pipeline (runs on push to main/develop)
2. **pr-validation.yml** - Pull request validation (runs on PRs)

## Workflow: ci-cd.yml

### Trigger Events

- **Push** to `main` or `develop` branches
- **Pull Request** to `main` or `develop` branches
- **Manual trigger** (workflow_dispatch) with optional AWS deployment

### Jobs

#### 1. test-backend
- Runs Go unit tests
- Generates code coverage report
- Runs linter (golangci-lint)
- Uses PostgreSQL and Redis services

**Duration:** ~2-3 minutes

#### 2. build-images
- Builds Docker images for API and Executor
- Pushes to Docker Hub (except on PRs)
- Uses Docker layer caching for speed
- Tags images with branch name and commit SHA

**Duration:** ~3-5 minutes (first run), ~1-2 minutes (cached)

#### 3. test-k3s-deployment
- Installs K3s in GitHub runner
- Deploys application with Helm
- Runs smoke tests (signup, login, API calls)
- Validates the deployment actually works

**Duration:** ~5-7 minutes

**This is the key innovation** - we verify the deployment works BEFORE deploying to AWS!

#### 4. deploy-to-aws
- Only runs on `main` branch or manual trigger
- SSHs into AWS EC2 instance
- Pulls latest code
- Updates Helm deployment with new images
- Verifies deployment success

**Duration:** ~2-3 minutes

**Requires:** Environment "production" configured

#### 5. security-scan
- Scans Docker images for vulnerabilities
- Uses Trivy scanner
- Uploads results to GitHub Security tab

**Duration:** ~2-3 minutes

### Total Pipeline Duration

- **PR validation:** ~5-8 minutes
- **Main branch (no deploy):** ~10-15 minutes
- **Production deployment:** ~15-20 minutes

## Workflow: pr-validation.yml

Runs on all pull requests to ensure code quality.

### Jobs

#### 1. lint-and-format
- Checks Go code formatting
- Runs golangci-lint with strict rules

#### 2. test-changes
- Runs full test suite with coverage
- Requires minimum 50% coverage
- Comments coverage report on PR

#### 3. build-check
- Verifies Docker images build successfully
- Doesn't push images (just validation)

#### 4. size-check
- Checks compiled binary size
- Warns if binary exceeds 50MB

## Usage Examples

### Automatic: Push to Main

```bash
git checkout main
git add .
git commit -m "feat: add new feature"
git push origin main
```

This will:
1. Run all tests
2. Build Docker images
3. Test in K3s
4. Deploy to AWS (if configured)
5. Run security scan

### Manual: Deploy to AWS

```bash
# Via GitHub UI
1. Go to Actions tab
2. Select "CI/CD Pipeline"
3. Click "Run workflow"
4. Check "Deploy to AWS after tests pass"
5. Click "Run workflow"

# Via GitHub CLI
gh workflow run ci-cd.yml -f deploy_to_aws=true
```

### Pull Request Workflow

```bash
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "feat: implement new feature"
git push origin feature/new-feature

# Create PR on GitHub
# PR validation workflow runs automatically
```

## Monitoring Workflows

### Via GitHub UI

1. Go to repository → Actions tab
2. Click on a workflow run
3. View job details and logs

### Via GitHub CLI

```bash
# List recent workflow runs
gh run list

# View specific run
gh run view RUN_ID

# Watch a running workflow
gh run watch
```

## Environment Setup

### GitHub Secrets

See [SECRETS.md](./SECRETS.md) for complete list.

Required for full pipeline:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `AWS_SSH_PRIVATE_KEY` (for deployment)
- `AWS_HOST` (for deployment)

### GitHub Environment

Create "production" environment:

```bash
# Via GitHub UI
1. Settings → Environments
2. New environment → "production"
3. Add protection rules:
   - Required reviewers: 1
   - Deployment branches: main only
```

## Debugging Failed Workflows

### Test Failures

```bash
# Check test logs in GitHub Actions
# Run tests locally first
cd backend
make test

# Run with verbose output
go test -v ./...
```

### Build Failures

```bash
# Test Docker build locally
cd backend
docker build -t bugdrill-api:test -f Dockerfile .
docker build -t bugdrill-executor:test -f executor/Dockerfile .
```

### K3s Deployment Failures

```bash
# Check the "Test K3s Deployment" job logs
# Look for pod status and events

# Test locally with K3s
cd infrastructure/k3s
./install-k3s.sh
./deploy.sh
```

### AWS Deployment Failures

```bash
# SSH into EC2 instance
ssh ubuntu@YOUR_IP

# Check cluster status
kubectl get pods -n bugdrill
kubectl logs -n bugdrill POD_NAME

# Check recent deployments
helm history bugdrill-api -n bugdrill
```

## Best Practices

### 1. Always Create PRs

Don't push directly to `main` - use PRs so validation runs first.

### 2. Check Workflow Status

Before merging, ensure all checks pass (green checkmarks).

### 3. Monitor First Deployment

Watch the first deployment to AWS carefully:
```bash
# In one terminal - watch workflow
gh run watch

# In another terminal - monitor AWS
ssh ubuntu@YOUR_IP
watch kubectl get pods -n bugdrill
```

### 4. Use Semantic Commits

Follow conventional commits format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

Example:
```bash
git commit -m "feat: add user profile endpoint"
git commit -m "fix: resolve authentication bug"
```

### 5. Keep Dependencies Updated

```bash
# Update Go dependencies
cd backend
go get -u ./...
go mod tidy

# Update GitHub Actions versions (check .github/workflows/*.yml)
```

## Optimization Tips

### Speed Up Builds

1. **Use caching** - Already configured for Go modules and Docker layers
2. **Run tests in parallel** - Already using `go test ./...` which parallelizes
3. **Optimize Docker images** - Use multi-stage builds (already done)

### Reduce Costs

1. **Cancel redundant workflows**
   ```bash
   # Auto-cancel previous runs on new push
   # Add to workflow:
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   ```

2. **Skip CI for docs**
   ```bash
   # In commit message:
   git commit -m "docs: update README [skip ci]"
   ```

## Troubleshooting Common Issues

### "Docker login failed"
- Check DOCKER_USERNAME and DOCKER_PASSWORD secrets
- Ensure token hasn't expired

### "K3s installation timeout"
- GitHub runners occasionally slow - retry the workflow

### "SSH connection refused"
- Check EC2 instance is running
- Verify security group allows GitHub IPs
- Ensure AWS_SSH_PRIVATE_KEY is correct

### "Helm upgrade failed"
- Check if namespace exists: `kubectl get ns`
- Verify secrets are created
- Check pod logs for errors

## Advanced Features

### Matrix Builds (Future Enhancement)

Test against multiple Go versions:

```yaml
strategy:
  matrix:
    go-version: ['1.21', '1.22', '1.23']
```

### Scheduled Tests (Future Enhancement)

Run nightly integration tests:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
```

### Deployment Slots (Future Enhancement)

Blue-green deployments:

```yaml
- name: Deploy to blue slot
  run: helm upgrade --set slot=blue ...
  
- name: Switch traffic to blue
  run: kubectl patch svc ...
```

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [K3s Documentation](https://docs.k3s.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

## Support

If you encounter issues:

1. Check the workflow logs in GitHub Actions
2. Review this documentation
3. Test locally using the same commands
4. Open an issue with workflow run URL and error details
