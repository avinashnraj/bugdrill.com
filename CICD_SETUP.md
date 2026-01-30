# 🚀 CI/CD Setup Complete!

Your GitHub Actions CI/CD pipeline is ready to use. Here's everything that was created:

## 📁 What Was Created

```
.github/
├── workflows/
│   ├── ci-cd.yml              # Main CI/CD pipeline
│   ├── pr-validation.yml      # Pull request validation
│   └── README.md              # Quick reference guide
├── scripts/
│   ├── test-pipeline.sh       # Local testing script (Linux/Mac)
│   └── test-pipeline.ps1      # Local testing script (Windows)
├── CICD.md                    # Complete CI/CD documentation
└── SECRETS.md                 # Secrets configuration guide
```

## 🎯 Pipeline Features

### ✅ Automated Testing
- Unit tests with coverage reporting
- Integration tests with PostgreSQL & Redis
- Code formatting and linting
- 50% minimum coverage requirement for PRs

### 🐳 Docker Build & Push
- Multi-stage Docker builds
- Layer caching for speed
- Automatic tagging (branch, SHA, latest)
- Push to Docker Hub on main/develop

### ☸️ K3s Deployment Testing
- **Key Innovation**: Tests deployment in K3s BEFORE deploying to AWS!
- Installs K3s in GitHub runner
- Deploys with Helm
- Runs smoke tests (signup, login, API calls)
- Ensures everything works before production

### 🚀 AWS Deployment
- Automatic deployment on `main` branch push
- Manual trigger option via GitHub UI
- SSH-based deployment
- Health check verification
- Rollback on failure

### 🔒 Security
- Vulnerability scanning with Trivy
- Results uploaded to GitHub Security tab
- Secret management with GitHub Secrets
- Environment protection rules

## 🏁 Getting Started

### 1. Configure Secrets (5 minutes)

```bash
# Install GitHub CLI if needed
winget install GitHub.cli

# Set secrets
gh secret set DOCKER_USERNAME
# Enter your Docker Hub username

gh secret set DOCKER_PASSWORD
# Enter your Docker Hub access token (not password!)

gh secret set AWS_SSH_PRIVATE_KEY < ~/.ssh/id_rsa
# Your SSH private key for EC2

gh secret set AWS_HOST
# Your EC2 public IP or domain
```

**Detailed instructions**: [.github/SECRETS.md](.github/SECRETS.md)

### 2. Create Production Environment

1. Go to repository Settings → Environments
2. Create "production" environment
3. Add protection rules:
   - ✅ Required reviewers: 1
   - ✅ Wait timer: 0 minutes
   - ✅ Deployment branches: `main` only

### 3. Test Locally First

**Windows (PowerShell):**
```powershell
.\.github\scripts\test-pipeline.ps1
```

**Linux/Mac:**
```bash
chmod +x .github/scripts/test-pipeline.sh
./.github/scripts/test-pipeline.sh
```

### 4. Push and Watch

```bash
git add .
git commit -m "feat: enable CI/CD pipeline"
git push origin main

# Watch the workflow
gh run watch
```

## 📊 What Happens When You Push

### On Pull Request:
1. ✅ Code formatting check
2. ✅ Linting with golangci-lint
3. ✅ Run all tests with coverage
4. ✅ Build Docker images (no push)
5. ✅ Size check
6. 💬 Comment coverage report on PR

**Duration**: ~5-8 minutes

### On Push to `main`:
1. ✅ Run all tests
2. ✅ Build Docker images
3. ✅ Push images to Docker Hub
4. ✅ Deploy to K3s test cluster
5. ✅ Run smoke tests
6. ✅ Deploy to AWS EC2
7. ✅ Verify deployment health
8. ✅ Security scan with Trivy

**Duration**: ~15-20 minutes

### On Push to `develop`:
Same as main, but **without AWS deployment**

## 🎮 Common Workflows

### Create a Feature
```bash
git checkout -b feature/new-feature
# Make changes
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
# Create PR on GitHub - validation runs automatically
```

### Deploy to Production
```bash
# Merge PR to main - deploys automatically
git checkout main
git merge develop
git push origin main

# OR use manual trigger
gh workflow run ci-cd.yml -f deploy_to_aws=true
```

### Check Workflow Status
```bash
# List recent runs
gh run list

# Watch current run
gh run watch

# View specific run with logs
gh run view <run-id> --log
```

### Debug Failed Workflow
```bash
# View failure details
gh run view <run-id> --log-failed

# Re-run just failed jobs
gh run rerun <run-id> --failed

# Re-run entire workflow
gh run rerun <run-id>
```

## 🧪 Testing Strategy

### Unit Tests (backend/internal/)
```bash
cd backend
make test
make test-coverage
```

### Integration Tests (Godog)
```bash
cd backend
make test-functional
```

### K3s Deployment Test (Local)
```bash
cd infrastructure/k3s
./install-k3s.sh
./deploy.sh
```

### Full Pipeline Simulation
```bash
.\.github\scripts\test-pipeline.ps1     # Windows
./.github/scripts/test-pipeline.sh      # Linux/Mac
```

## 📈 Monitoring

### GitHub UI
- Go to repository → **Actions** tab
- Click on workflow run to see details
- Each job shows real-time logs
- Failed steps highlighted in red

### GitHub CLI
```bash
# Watch in terminal
gh run watch

# Get notifications
gh run list --limit 5

# View full logs
gh run view <run-id> --log
```

### AWS Deployment
```bash
# SSH to EC2
ssh ubuntu@YOUR_IP

# Check pods
kubectl get pods -n bugdrill

# View logs
kubectl logs -f -n bugdrill -l app.kubernetes.io/name=interviewpal-api

# Check deployment history
helm history bugdrill-api -n bugdrill
```

## 🔧 Customization

### Skip CI on Commits
```bash
git commit -m "docs: update README [skip ci]"
```

### Run Tests Only
```bash
.\.github\scripts\test-pipeline.ps1 -SkipBuild
```

### Include K3s Test
```bash
./.github/scripts/test-pipeline.sh --with-k3s
```

## 🆘 Troubleshooting

### "Docker login failed"
- Verify DOCKER_USERNAME is correct
- Ensure DOCKER_PASSWORD is an **access token**, not your password
- Check token at https://hub.docker.com/settings/security

### "Tests failing in CI but pass locally"
- Check environment variables
- Verify database migrations are applied
- Look for timing issues (increase timeouts)

### "K3s deployment times out"
- GitHub runners can be slow sometimes
- Click "Re-run failed jobs"
- Check resource limits in values-ci.yaml

### "AWS deployment failed"
- Verify EC2 instance is running: `aws ec2 describe-instances`
- Check SSH key is correct: `ssh ubuntu@YOUR_IP`
- Ensure security group allows SSH from anywhere (or GitHub IPs)

### "Security scan shows vulnerabilities"
- Check severity (Low, Medium, High, Critical)
- Update base images in Dockerfiles
- Update Go dependencies: `go get -u ./...`

## 📚 Documentation

- **[CI/CD Guide](.github/CICD.md)** - Complete documentation
- **[Secrets Setup](.github/SECRETS.md)** - Configure GitHub secrets
- **[Workflow README](.github/workflows/README.md)** - Quick reference
- **[Infrastructure Guide](infrastructure/DEPLOYMENT_GUIDE.md)** - AWS deployment

## 🎓 Next Steps

1. ✅ Configure GitHub secrets
2. ✅ Create production environment
3. ✅ Test locally with test-pipeline script
4. ✅ Push to trigger first pipeline run
5. ✅ Monitor workflow in Actions tab
6. ✅ Verify deployment on AWS
7. ✅ Set up branch protection rules (optional)
8. ✅ Enable Codecov (optional)
9. ✅ Add status badges to README (optional)

## 💡 Pro Tips

1. **Use draft PRs** for work in progress
2. **Test locally first** with test-pipeline scripts
3. **Monitor costs** - GitHub Actions has monthly limits
4. **Review security alerts** regularly
5. **Keep dependencies updated** weekly
6. **Use semantic commit messages** (feat:, fix:, docs:)
7. **Add branch protection** to prevent direct pushes to main

## 📊 GitHub Actions Limits

### Free Tier (Public Repos)
- ✅ Unlimited minutes
- ✅ Unlimited concurrent jobs

### Free Tier (Private Repos)
- ⚠️ 2,000 minutes/month
- ⚠️ 20 concurrent jobs
- Each workflow run uses ~15-20 minutes
- **~100 deployments per month** on free tier

### Paid Plans
- Pro: $4/month for 3,000 minutes
- Team: $21/month for 10,000 minutes

## 🎉 Benefits You Get

1. **Catch bugs before production** - Tests run on every PR
2. **Consistent deployments** - No manual steps, no human error
3. **Fast feedback** - Know if your code works in <20 minutes
4. **Safe deployments** - K3s test ensures deployment works
5. **Automatic rollback** - Failed health checks cancel deployment
6. **Security** - Vulnerability scanning on every build
7. **Audit trail** - See what was deployed when and by whom
8. **Confidence** - Deploy to production safely

---

**Ready to deploy?** Start with [.github/SECRETS.md](.github/SECRETS.md)

**Questions?** Check [.github/CICD.md](.github/CICD.md)

**Need help?** Open an issue with the workflow run URL
