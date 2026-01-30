# GitHub Actions Workflows

This directory contains the CI/CD pipeline for BugDrill.

## 🚀 Quick Start

### First Time Setup

1. **Configure secrets** (required)
   ```bash
   # See SECRETS.md for detailed instructions
   gh secret set DOCKER_USERNAME
   gh secret set DOCKER_PASSWORD
   gh secret set AWS_SSH_PRIVATE_KEY < ~/.ssh/id_rsa
   gh secret set AWS_HOST
   ```

2. **Create production environment**
   - Go to Settings → Environments → New environment
   - Name: `production`
   - Add protection rules (optional)

3. **Push code to trigger pipeline**
   ```bash
   git add .
   git commit -m "feat: initial setup"
   git push origin main
   ```

4. **Monitor workflow**
   ```bash
   gh run watch
   ```

## 📋 Workflows

### ci-cd.yml (Main Pipeline)

**Triggers:**
- Push to `main` or `develop`
- Pull requests
- Manual dispatch

**Jobs:**
1. ✅ Test Backend - Unit tests, coverage, linting
2. 🐳 Build Images - Docker images for API & Executor
3. ☸️ Test K3s Deployment - Deploy and test in K3s cluster
4. 🚀 Deploy to AWS - Production deployment (main branch only)
5. 🔒 Security Scan - Vulnerability scanning

**Duration:** 10-20 minutes

### pr-validation.yml (PR Checks)

**Triggers:**
- Pull requests to `main` or `develop`

**Jobs:**
1. Lint & format check
2. Test with coverage requirements
3. Build verification
4. Size check

**Duration:** 5-8 minutes

## 🎯 Common Tasks

### Create a Pull Request
```bash
git checkout -b feature/my-feature
# Make changes
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
# Create PR on GitHub
```

### Deploy to Production
```bash
# Option 1: Push to main (automatic)
git checkout main
git merge develop
git push origin main

# Option 2: Manual trigger
gh workflow run ci-cd.yml -f deploy_to_aws=true
```

### Check Workflow Status
```bash
# List recent runs
gh run list

# Watch current run
gh run watch

# View specific run
gh run view <run-id>
```

### Debug Failed Workflow
```bash
# View logs
gh run view <run-id> --log

# Re-run failed jobs
gh run rerun <run-id> --failed
```

## 📊 Pipeline Flow

```
┌─────────────────┐
│   Push Code     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Job 1: Test Backend               │
│  - Run unit tests                  │
│  - Generate coverage               │
│  - Run linter                      │
└────────┬────────────────────────────┘
         │ ✓ Pass
         ▼
┌─────────────────────────────────────┐
│  Job 2: Build Images               │
│  - Build API image                 │
│  - Build Executor image            │
│  - Push to Docker Hub              │
└────────┬────────────────────────────┘
         │ ✓ Pass
         ▼
┌─────────────────────────────────────┐
│  Job 3: Test K3s Deployment        │
│  - Install K3s in runner           │
│  - Deploy with Helm                │
│  - Run smoke tests                 │
│  - Verify API works                │
└────────┬────────────────────────────┘
         │ ✓ Pass
         ▼
┌─────────────────────────────────────┐
│  Job 4: Deploy to AWS (main only)  │
│  - SSH to EC2                      │
│  - Update deployment               │
│  - Verify health                   │
└────────┬────────────────────────────┘
         │ ✓ Pass
         ▼
┌─────────────────────────────────────┐
│  Job 5: Security Scan              │
│  - Scan for vulnerabilities        │
│  - Upload to GitHub Security       │
└─────────────────────────────────────┘
```

## 🔧 Configuration Files

- **ci-cd.yml** - Main CI/CD pipeline
- **pr-validation.yml** - PR validation checks
- **SECRETS.md** - Secret configuration guide
- **CICD.md** - Detailed documentation

## 🧪 Testing Locally

Before pushing, test locally:

```bash
# Run tests
cd backend
make test
make lint

# Build Docker images
make docker-build

# Test in local K3s
cd ../infrastructure/k3s
./install-k3s.sh
./deploy.sh
```

## 📚 Documentation

- [Complete CI/CD Guide](./CICD.md) - Detailed documentation
- [Secrets Setup](./SECRETS.md) - How to configure secrets
- [Infrastructure Guide](../infrastructure/DEPLOYMENT_GUIDE.md) - AWS deployment

## 🆘 Troubleshooting

### Workflow won't start
- Check if secrets are configured
- Verify branch protection rules
- Ensure workflow file is valid YAML

### Tests failing
```bash
# Run locally first
cd backend
make test
```

### Docker build failing
```bash
# Test build locally
docker build -t bugdrill-api:test -f backend/Dockerfile backend/
```

### K3s deployment failing
- Check pod logs in workflow output
- Look for "Show logs on failure" step
- Verify Helm values are correct

### AWS deployment failing
- Verify EC2 instance is running
- Check SSH key is correct
- Ensure security group allows SSH

## 💡 Tips

1. **Use draft PRs** for work in progress to skip some checks
2. **Add `[skip ci]`** to commit messages for documentation-only changes
3. **Monitor costs** - GitHub Actions has free tier limits
4. **Cache dependencies** - Already configured for faster builds
5. **Review security alerts** in Security tab regularly

## 🎓 Learning Resources

- [GitHub Actions Quickstart](https://docs.github.com/en/actions/quickstart)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [K3s Documentation](https://docs.k3s.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

---

**Questions?** Check [CICD.md](./CICD.md) or open an issue.
