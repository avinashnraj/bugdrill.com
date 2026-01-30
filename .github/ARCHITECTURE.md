# CI/CD Pipeline Architecture

## Complete Workflow Visualization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                               │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Feature    │ Push    │ Pull Request │ Merge   │     Main     │
│   Branch     ├────────►│  Validation  ├────────►│   Branch     │
│              │         │   Workflow   │         │   Deploy     │
└──────────────┘         └──────────────┘         └──────┬───────┘
                                │                         │
                                ├─────────────────────────┤
                                │                         │
                                ▼                         ▼
                    ┌───────────────────┐    ┌────────────────────┐
                    │  PR Validation    │    │  Full CI/CD        │
                    └───────────────────┘    └────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                        PR Validation Workflow
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│ Trigger: Pull Request to main/develop                                   │
│ Purpose: Ensure code quality before merge                               │
│ Duration: ~5-8 minutes                                                   │
└─────────────────────────────────────────────────────────────────────────┘

    ┌────────────────────┐
    │  Code Pushed       │
    │  to PR Branch      │
    └──────┬─────────────┘
           │
           ├───────────────────────────────────┐
           │                                   │
           ▼                                   ▼
    ┌─────────────────┐              ┌──────────────────┐
    │ Job 1: Lint     │              │ Job 2: Test      │
    │ & Format        │              │ with Coverage    │
    └─────────────────┘              └──────────────────┘
    • Check Go format                • Run all tests
    • golangci-lint                  • Require 50% coverage
    • No errors allowed              • Comment on PR
           │                                   │
           ├───────────────┬───────────────────┤
           │               │                   │
           ▼               ▼                   ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │ Build API   │ │Build Executor│ │ Size Check  │
    │ (no push)   │ │  (no push)   │ │             │
    └─────────────┘ └─────────────┘ └─────────────┘
           │               │                   │
           └───────────────┴───────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ All Checks   │
                    │    Pass?     │
                    └──────┬───────┘
                           │
                     Yes   │   No
                    ┌──────┴──────┐
                    ▼             ▼
              ✅ Ready       ❌ Fix Issues
              to Merge       Required


═══════════════════════════════════════════════════════════════════════════
                        Full CI/CD Pipeline
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│ Trigger: Push to main/develop or Manual                                 │
│ Purpose: Build, test, and deploy to production                          │
│ Duration: ~15-20 minutes                                                 │
└─────────────────────────────────────────────────────────────────────────┘

    ┌────────────────────┐
    │  Code Pushed to    │
    │   main/develop     │
    └──────┬─────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Stage 1: Test                                  │
│                          Duration: ~2-3 min                              │
└─────────────────────────────────────────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────┐
    │  Start PostgreSQL        │ ◄── GitHub Actions Service
    │  Start Redis             │ ◄── GitHub Actions Service
    └──────────────────────────┘
           │
           ▼
    ┌──────────────────────────┐
    │  Install Go 1.22         │
    │  Download dependencies   │
    └──────────────────────────┘
           │
           ▼
    ┌──────────────────────────┐
    │  Run Database Migrations │
    │  • 001_init_schema.sql   │
    │  • seed_base.sql         │
    └──────────────────────────┘
           │
           ▼
    ┌──────────────────────────┐
    │  make test               │ ◄── Your Makefile
    │  make test-coverage      │ ◄── Your Makefile
    │  make lint               │ ◄── Your Makefile
    └──────────────────────────┘
           │
           ▼
    ┌──────────────────────────┐
    │  Upload Coverage Report  │
    │  to Codecov              │
    └──────────┬───────────────┘
               │
               ▼ ✅ Tests Pass
               │
┌──────────────┴──────────────────────────────────────────────────────────┐
│                        Stage 2: Build Images                             │
│                          Duration: ~3-5 min                              │
└─────────────────────────────────────────────────────────────────────────┘
               │
               ├────────────────────────────┐
               │                            │
               ▼                            ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Build API Image     │    │ Build Executor Image │
    │                      │    │                      │
    │  Multi-stage Docker  │    │  Multi-stage Docker  │
    │  Layer caching       │    │  Layer caching       │
    │  Tag: main-{sha}     │    │  Tag: main-{sha}     │
    └──────────────────────┘    └──────────────────────┘
               │                            │
               ▼                            ▼
    ┌──────────────────────┐    ┌──────────────────────┐
    │  Push to Docker Hub  │    │  Push to Docker Hub  │
    └──────────────────────┘    └──────────────────────┘
               │                            │
               └────────────┬───────────────┘
                            ▼ ✅ Images Built
                            │
┌───────────────────────────┴─────────────────────────────────────────────┐
│                   Stage 3: Test K3s Deployment                           │
│                   Duration: ~5-7 min                                     │
│                   ⭐ KEY INNOVATION ⭐                                   │
└─────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Install K3s           │
                │  in GitHub Runner      │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Setup kubectl         │
                │  Install Helm          │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Create namespace      │
                │  Create secrets        │
                │  Create PV/PVC         │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Deploy with Helm      │
                │  • PostgreSQL          │
                │  • Redis               │
                │  • API                 │
                │  • Executor            │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Wait for Pods Ready   │
                │  Timeout: 5 minutes    │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Test Health Endpoint  │
                │  GET /health           │
                └────────────────────────┘
                            │
                            ▼
                ┌────────────────────────┐
                │  Run Smoke Tests       │
                │  • User Signup         │
                │  • User Login          │
                │  • Get Patterns (auth) │
                └────────────────────────┘
                            │
                      ┌─────┴─────┐
                      │   Tests   │
                      │   Pass?   │
                      └─────┬─────┘
                            │
                   Yes      │      No
              ┌─────────────┴─────────────┐
              ▼                           ▼
        ✅ Continue                  ❌ Show Logs
        to Deploy                    Stop Pipeline
              │
              ▼
┌─────────────┴───────────────────────────────────────────────────────────┐
│                  Stage 4: Deploy to AWS                                  │
│                  Duration: ~2-3 min                                      │
│                  Runs: main branch only                                  │
└─────────────────────────────────────────────────────────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Configure SSH       │
    │  Load Private Key    │
    └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  SSH to EC2          │
    │  ubuntu@AWS_HOST     │
    └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  On EC2 Instance:    │
    │  • Pull latest code  │
    │  • Update Helm values│
    │  • helm upgrade      │
    └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Wait for Rollout    │
    │  kubectl rollout     │
    └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Verify Health       │
    │  curl http://IP      │
    └──────────────────────┘
              │
              ▼ ✅ Deployed
              │
┌─────────────┴───────────────────────────────────────────────────────────┐
│                  Stage 5: Security Scan                                  │
│                  Duration: ~2-3 min                                      │
└─────────────────────────────────────────────────────────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Trivy Scanner       │
    │  Scan API Image      │
    │  Check CVEs          │
    └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │  Upload to GitHub    │
    │  Security Tab        │
    └──────────────────────┘
              │
              ▼
          ✅ COMPLETE!


═══════════════════════════════════════════════════════════════════════════
                        Deployment Environments
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Runner                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    K3s Test Cluster                              │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │PostgreSQL│  │  Redis   │  │   API    │  │ Executor │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│  │                                                                  │   │
│  │  Purpose: Validate deployment works before AWS                  │   │
│  │  Lifespan: ~5 minutes (destroyed after tests)                   │   │
│  │  Cost: FREE (GitHub Actions)                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ If tests pass
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance (Production)                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    K3s Production Cluster                        │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │PostgreSQL│  │  Redis   │  │   API    │  │ Executor │       │   │
│  │  │  (EBS)   │  │          │  │          │  │          │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │   │
│  │                                                                  │   │
│  │  Purpose: Serve production traffic                              │   │
│  │  Lifespan: Always running                                       │   │
│  │  Cost: ~$10/month (t4g.micro)                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                        Data Flow Diagram
═══════════════════════════════════════════════════════════════════════════

Developer                GitHub                  Docker Hub              AWS
────────                ──────────                ──────────              ───
    │                        │                         │                  │
    │  git push main         │                         │                  │
    ├───────────────────────►│                         │                  │
    │                        │                         │                  │
    │                        │  Trigger CI/CD          │                  │
    │                        ├─────────┐               │                  │
    │                        │         │               │                  │
    │                        │  ┌──────▼──────┐        │                  │
    │                        │  │ Run Tests   │        │                  │
    │                        │  └──────┬──────┘        │                  │
    │                        │         │               │                  │
    │                        │  ┌──────▼──────┐        │                  │
    │                        │  │Build Images │        │                  │
    │                        │  └──────┬──────┘        │                  │
    │                        │         │               │                  │
    │                        │         │ Push Images   │                  │
    │                        │         ├──────────────►│                  │
    │                        │         │               │                  │
    │                        │  ┌──────▼──────┐        │                  │
    │                        │  │   Test in   │        │                  │
    │                        │  │  K3s (temp) │        │                  │
    │                        │  └──────┬──────┘        │                  │
    │                        │         │               │                  │
    │                        │         │ Tests Pass    │                  │
    │                        │         │               │                  │
    │                        │         │    SSH Deploy │                  │
    │                        │         ├───────────────┼─────────────────►│
    │                        │         │               │                  │
    │                        │         │               │  Pull Images     │
    │                        │         │               │◄─────────────────┤
    │                        │         │               │                  │
    │                        │         │               │  Update Pods     │
    │                        │         │               ├─────────┐        │
    │                        │         │               │         │        │
    │                        │         │               │  ┌──────▼──────┐ │
    │                        │         │               │  │ New Version │ │
    │                        │         │               │  │  Running!   │ │
    │                        │         │               │  └─────────────┘ │
    │  Deployment            │         │               │                  │
    │  Notification          │◄────────┘               │                  │
    │◄───────────────────────┤                         │                  │
    │                        │                         │                  │


═══════════════════════════════════════════════════════════════════════════
                            Success Criteria
═══════════════════════════════════════════════════════════════════════════

Stage                   Success Criteria             Failure Action
────────────────────    ──────────────────────       ──────────────
1. Test Backend         • All tests pass             → Stop pipeline
                        • Coverage > 0%               → Show test logs
                        • Linter clean

2. Build Images         • Docker build succeeds      → Stop pipeline
                        • Images pushed to Hub        → Show build logs

3. Test K3s            • Pods start successfully     → Stop pipeline
                        • Health check returns 200    → Show pod logs
                        • Signup test passes          → Show events
                        • Login test passes
                        • API call succeeds

4. Deploy AWS          • SSH connection works        → Stop pipeline
                        • Helm upgrade succeeds       → Rollback
                        • Health check passes         → Alert team

5. Security Scan       • Scan completes              → Continue anyway
                        • No CRITICAL vulns           → Create issue


═══════════════════════════════════════════════════════════════════════════
                          Monitoring & Alerts
═══════════════════════════════════════════════════════════════════════════

You can monitor the pipeline through:

1. GitHub Actions UI
   • Real-time logs
   • Job status
   • Artifact downloads

2. GitHub CLI
   • gh run watch
   • gh run list
   • gh run view <id>

3. Email Notifications
   • Automatic on failure
   • Configure in Settings

4. GitHub Status Checks
   • Required for merge
   • Shown on PR

5. Security Tab
   • Vulnerability reports
   • Trend analysis
