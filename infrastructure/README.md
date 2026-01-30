# Infrastructure Overview

This directory contains everything needed to deploy BugDrill on AWS with K3s (lightweight Kubernetes).

## 📁 Directory Structure

```
infrastructure/
├── aws/                    # AWS provisioning (Terraform)
│   ├── main.tf            # Main Terraform configuration
│   ├── user-data.sh       # EC2 initialization script
│   └── terraform.tfvars.example
│
├── k3s/                   # K3s cluster management scripts
│   ├── install-k3s.sh     # K3s installation
│   ├── deploy.sh          # Application deployment
│   ├── build-images.sh    # Docker image building
│   ├── backup-postgres.sh # Database backups
│   ├── restore-postgres.sh# Database restore
│   ├── setup-backups.sh   # Automated backup setup
│   ├── monitor.sh         # Cluster monitoring
│   └── alert.sh           # Simple alerting
│
└── DEPLOYMENT_GUIDE.md    # Complete deployment guide
```

## 🎯 Deployment Options

### Option 1: K3s on EC2 t4g.micro (Recommended)
- **Cost**: $0 (Year 1 free tier) → $10/month (Year 2+)
- **Pros**: True Kubernetes, uses your existing Helm charts, highly scalable
- **Cons**: More complex setup (but automated with scripts)
- **Best for**: Learning K8s, future scalability, production-ready

### Option 2: Docker Compose on EC2
- **Cost**: $0 (Year 1) → $10/month (Year 2+)
- **Pros**: Simplest setup, you already have docker-compose.yml
- **Cons**: Not Kubernetes, harder to scale
- **Best for**: Quick MVP, testing

### Option 3: Managed Services (DigitalOcean App Platform)
- **Cost**: $26-40/month from day 1
- **Pros**: Zero DevOps, automatic scaling, managed DB
- **Cons**: More expensive, vendor lock-in
- **Best for**: Non-technical teams, rapid deployment

## 🚀 Quick Start

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed instructions.

**TL;DR:**
1. Provision AWS: `cd aws && terraform apply`
2. Install K3s: `ssh ubuntu@IP && ./infrastructure/k3s/install-k3s.sh`
3. Build images: `./infrastructure/k3s/build-images.sh`
4. Deploy: `./infrastructure/k3s/deploy.sh`

## 💰 Cost Comparison

| Setup | Year 1 | Year 2+ | Scalability | Complexity |
|-------|--------|---------|-------------|------------|
| **K3s on t4g.micro** | **$0-3** | **$10** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Docker Compose EC2 | $0-3 | $10 | ⭐⭐ | ⭐ |
| DigitalOcean App | $26+ | $26+ | ⭐⭐⭐⭐ | ⭐ |
| Managed K8s (EKS) | $100+ | $100+ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## 🔐 Security Notes

- SSH access restricted to your IP only
- Security groups configured for minimal exposure
- PostgreSQL data encrypted at rest (EBS encryption)
- Secrets generated automatically
- Regular automated backups

## 📊 Resource Allocation (1GB RAM)

```
Component          RAM    CPU    Notes
─────────────────────────────────────
K3s (system)       100Mi  100m   Kubernetes overhead
PostgreSQL         150Mi  200m   Database
Redis              64Mi   100m   Cache
Backend API        256Mi  400m   Main application
Executor           150Mi  200m   Code execution
─────────────────────────────────────
Total              720Mi  1000m  Fits in 1GB with swap
```

## 🆙 Scaling Path

### Phase 1: MVP (0-1K users)
- Single t4g.micro node
- All services in K3s
- Local PostgreSQL
- **Cost**: ~$10/month

### Phase 2: Growth (1K-10K users)
- Upgrade to t4g.small (2GB RAM)
- Move PostgreSQL to RDS db.t4g.micro
- Add CloudFront CDN
- **Cost**: ~$40/month

### Phase 3: Scale (10K+ users)
- Multi-node K3s or migrate to EKS
- RDS with read replicas
- ElastiCache Redis
- Auto-scaling
- **Cost**: $100-200/month

## 🛠️ Maintenance

### Daily
- Automated backups (2 AM daily)
- Automated security updates

### Weekly
- Check monitoring dashboards
- Review logs for errors
- Verify backup integrity

### Monthly
- Update K3s: `sudo k3s-killall.sh && curl -sfL https://get.k3s.io | sh -`
- Review costs in AWS console
- Test disaster recovery

## 📚 Resources

- [AWS Free Tier](https://aws.amazon.com/free/)
- [K3s Documentation](https://docs.k3s.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Charts Guide](https://helm.sh/docs/chart_template_guide/)

---

**Questions?** See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) or open an issue.
