# CI/CD Quick Reference Card

## 📋 Common Commands

### Local Testing (Before Push)

```bash
# Run all CI tests locally
make ci-full                    # Test + Build (recommended)
make ci-test                    # Tests only
make ci-build                   # Build only

# Or use the scripts
.\.github\scripts\test-pipeline.ps1          # Windows
./.github/scripts/test-pipeline.sh           # Linux/Mac

# Individual steps
make test                       # Run tests
make test-coverage             # Tests with coverage
make lint                      # Run linter
gofmt -w .                     # Format code
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature
# Make changes...
make ci-full                   # Test locally
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
# Create PR on GitHub

# Merge to main (triggers deployment)
git checkout main
git merge develop
git push origin main           # Deploys to AWS automatically
```

### GitHub CLI

```bash
# Watch current workflow
gh run watch

# List recent runs
gh run list --limit 10

# View specific run
gh run view <run-id> --log

# Manually trigger deployment
gh workflow run ci-cd.yml -f deploy_to_aws=true

# Re-run failed jobs
gh run rerun <run-id> --failed

# Cancel running workflow
gh run cancel <run-id>
```

### Secrets Management

```bash
# Set secrets
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set AWS_SSH_PRIVATE_KEY < ~/.ssh/id_rsa
gh secret set AWS_HOST

# List secrets
gh secret list

# Delete secret
gh secret delete SECRET_NAME
```

### Monitoring on AWS

```bash
# SSH to instance
ssh ubuntu@YOUR_IP

# Check pod status
kubectl get pods -n bugdrill

# View logs
kubectl logs -f -n bugdrill -l app.kubernetes.io/name=interviewpal-api

# Check deployment
helm status bugdrill-api -n bugdrill

# View recent events
kubectl get events -n bugdrill --sort-by='.lastTimestamp' | tail -20

# Check resource usage
kubectl top pods -n bugdrill
```

## 🎯 Workflow Triggers

| Action | Workflow | Jobs Run | Deploys? |
|--------|----------|----------|----------|
| Push to feature branch | None | - | No |
| Create PR to main | pr-validation.yml | Lint, Test, Build Check | No |
| Push to develop | ci-cd.yml | All except AWS deploy | No |
| Push to main | ci-cd.yml | All including AWS deploy | **Yes** |
| Manual trigger | ci-cd.yml | All + optional AWS deploy | Optional |

## ⏱️ Typical Durations

| Workflow | Duration | Billable Minutes |
|----------|----------|------------------|
| PR Validation | 5-8 min | Free (public repo) |
| CI/CD (no deploy) | 10-15 min | Free (public repo) |
| CI/CD (with deploy) | 15-20 min | Free (public repo) |
| Security Scan | 2-3 min | Free (public repo) |

## 🔧 Troubleshooting

### Tests Failing in CI but Pass Locally

```bash
# Check environment differences
# CI uses services, local uses docker-compose

# Run tests with CI environment
docker-compose up -d postgres redis
sleep 10
make test

# Check database migrations
PGPASSWORD=postgres psql -h localhost -U postgres -d bugdrill_test -f migrations/001_init_schema.sql
```

### Docker Build Failing

```bash
# Test build locally
cd backend
docker build -t test -f Dockerfile .
docker build -t test -f executor/Dockerfile .

# Check .dockerignore
# Ensure no required files are ignored
```

### K3s Deployment Timeout

```bash
# Usually a resource issue
# Check pod events in workflow logs
kubectl describe pod <pod-name> -n bugdrill

# Common fixes:
# - Increase timeout in workflow
# - Reduce resource requests
# - Check image pull errors
```

### AWS SSH Connection Failed

```bash
# Verify key
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_IP

# Check security group
# Must allow SSH from 0.0.0.0/0 or GitHub IPs

# Verify instance is running
aws ec2 describe-instances --instance-ids INSTANCE_ID

# Check AWS_SSH_PRIVATE_KEY secret
# Must include header/footer and proper newlines
```

## 📊 Status Badges

Add to README.md:

```markdown
![CI/CD](https://github.com/USERNAME/bugdrill/actions/workflows/ci-cd.yml/badge.svg)
![Tests](https://github.com/USERNAME/bugdrill/actions/workflows/pr-validation.yml/badge.svg)
[![codecov](https://codecov.io/gh/USERNAME/bugdrill/branch/main/graph/badge.svg)](https://codecov.io/gh/USERNAME/bugdrill)
```

## 🎛️ Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| ci-cd.yml | Main pipeline | .github/workflows/ |
| pr-validation.yml | PR checks | .github/workflows/ |
| values-ci.yaml | K3s test config | backend/helm/interviewpal-api/ |
| values-micro.yaml | AWS prod config | backend/helm/interviewpal-api/ |
| Makefile | Build commands | backend/ |

## 🚦 Pipeline Stages

```
Tests (2-3 min)
  ↓
Build Images (3-5 min)
  ↓
Test in K3s (5-7 min) ← VALIDATION GATE
  ↓
Deploy to AWS (2-3 min)
  ↓
Security Scan (2-3 min)
```

## 📝 Commit Message Format

```bash
# Feature
git commit -m "feat: add user authentication"

# Bug fix
git commit -m "fix: resolve login timeout issue"

# Documentation
git commit -m "docs: update deployment guide"

# Refactor
git commit -m "refactor: optimize database queries"

# Test
git commit -m "test: add unit tests for auth service"

# Chore
git commit -m "chore: update dependencies"

# Skip CI
git commit -m "docs: fix typo [skip ci]"
```

## 🔐 Security Best Practices

```bash
# Never commit secrets
# Use .gitignore

# Rotate secrets regularly
gh secret set DOCKER_PASSWORD  # Every 90 days

# Use environment protection
# Settings → Environments → production

# Review security alerts
# Security tab → View alerts

# Update dependencies
cd backend
go get -u ./...
go mod tidy
```

## 📞 Getting Help

1. **Check workflow logs** - Actions tab → Click run → View logs
2. **Review documentation** - .github/CICD.md
3. **Test locally** - make ci-full
4. **Check issues** - Search existing issues
5. **Create issue** - Include workflow run URL

## 🎓 Learning Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [K3s Documentation](https://docs.k3s.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Go Testing](https://go.dev/doc/tutorial/add-a-test)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Print this for your desk!** 📄

Save as: `ci-cd-cheatsheet.txt`
