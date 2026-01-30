# BugDrill AWS K3s Deployment Guide

Complete guide to deploy BugDrill on AWS EC2 with K3s (Kubernetes) for **~$10/month**.

## 📋 Prerequisites

- AWS Account (Free tier eligible)
- SSH key pair (`ssh-keygen -t rsa -b 4096`)
- Terraform installed ([download](https://www.terraform.io/downloads))
- Docker Hub account (free)
- Git installed

## 💰 Cost Breakdown

| Resource | Year 1 (Free Tier) | Year 2+ |
|----------|-------------------|---------|
| EC2 t4g.micro | $0 | $6.57/month |
| EBS 20GB (root) | $0 | $1.60/month |
| EBS 20GB (data) | $0 | $1.60/month |
| Elastic IP | $0 | $0 (attached) |
| Data Transfer (1GB) | $0 | ~$0.09/month |
| **Total** | **~$0-3/month** | **~$10/month** |

## 🚀 Quick Start (5 steps)

### Step 1: Provision AWS Infrastructure

```bash
# Navigate to infrastructure directory
cd infrastructure/aws

# Copy and edit terraform variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - aws_region (e.g., "us-east-1")
# - my_ip (get your IP: curl ifconfig.me)
# - ssh_public_key_path

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates EC2 instance, VPC, security groups, etc.)
terraform apply

# Save the output - you'll need the public IP
# Output example: public_ip = "3.91.123.456"
```

**What this creates:**
- VPC with public subnet
- EC2 t4g.micro instance (ARM-based, 1GB RAM)
- 2x 20GB EBS volumes (root + PostgreSQL data)
- Elastic IP (static IP address)
- Security groups (SSH, HTTP, HTTPS, K8s API)

### Step 2: Connect to Your Instance

```bash
# Get your instance IP from Terraform output
ssh ubuntu@YOUR_ELASTIC_IP

# Or use the command from Terraform output
terraform output ssh_command
```

### Step 3: Install K3s and Setup Cluster

```bash
# On your EC2 instance, clone your repository
git clone https://github.com/YOUR_USERNAME/bugdrill.git
cd bugdrill

# Run the K3s installation script
chmod +x infrastructure/k3s/install-k3s.sh
./infrastructure/k3s/install-k3s.sh

# This script will:
# - Install K3s (lightweight Kubernetes)
# - Format and mount EBS volume for PostgreSQL
# - Create swap file (2GB)
# - Set up persistent volumes
# - Generate secrets
# - Install Helm

# Wait 5-10 minutes for installation to complete
```

### Step 4: Build and Push Docker Images

**Option A: Build on your local machine** (recommended for Windows)

```powershell
# On your local Windows machine
cd backend

# Login to Docker Hub
docker login

# Build API image
docker build -t YOUR_DOCKERHUB_USERNAME/bugdrill-api:latest -f Dockerfile .
docker push YOUR_DOCKERHUB_USERNAME/bugdrill-api:latest

# Build Executor image
docker build -t YOUR_DOCKERHUB_USERNAME/bugdrill-executor:latest -f executor/Dockerfile .
docker push YOUR_DOCKERHUB_USERNAME/bugdrill-executor:latest
```

**Option B: Build on EC2 instance**

```bash
# On your EC2 instance
# Install Docker first
sudo apt-get install -y docker.io
sudo usermod -aG docker ubuntu
# Log out and back in for group to take effect

cd ~/bugdrill
chmod +x infrastructure/k3s/build-images.sh

# Edit the script to set your Docker Hub username
nano infrastructure/k3s/build-images.sh
# Change: DOCKER_USERNAME="your-dockerhub-username"

# Build and push
./infrastructure/k3s/build-images.sh
```

### Step 5: Deploy to K3s

```bash
# On your EC2 instance

# Update values-micro.yaml with your Docker Hub images
nano backend/helm/interviewpal-api/values-micro.yaml

# Change these lines:
# image:
#   repository: YOUR_DOCKERHUB_USERNAME/bugdrill-api
# executor:
#   image:
#     repository: YOUR_DOCKERHUB_USERNAME/bugdrill-executor

# Deploy!
cd ~/bugdrill
chmod +x infrastructure/k3s/deploy.sh
./infrastructure/k3s/deploy.sh

# Check deployment status
kubectl get pods -n bugdrill
kubectl logs -f -n bugdrill -l app.kubernetes.io/name=interviewpal-api
```

### Step 6: Access Your Application

```bash
# Get your public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Test the API
curl http://YOUR_IP/health

# Your API is now accessible at:
# http://YOUR_IP/
```

## 📱 Configure Mobile Apps

Update your mobile app configuration:

```typescript
// mobile/src/constants/config.ts
export const API_BASE_URL = 'http://YOUR_ELASTIC_IP';
```

## 🔧 Management & Operations

### Monitor Your Cluster

```bash
# Real-time monitoring (on EC2 instance)
watch -n 5 ~/bugdrill/infrastructure/k3s/monitor.sh

# Check pod logs
kubectl logs -f -n bugdrill POD_NAME

# Check resource usage
kubectl top pods -n bugdrill
```

### Setup Automated Backups

```bash
# On your EC2 instance
cd ~/bugdrill
chmod +x infrastructure/k3s/setup-backups.sh
./infrastructure/k3s/setup-backups.sh

# Backups will run daily at 2 AM
# Stored in: ~/backups/
# Retention: 7 days
```

### Manual Backup & Restore

```bash
# Manual backup
~/bugdrill/infrastructure/k3s/backup-postgres.sh

# Restore from backup
~/bugdrill/infrastructure/k3s/restore-postgres.sh ~/backups/bugdrill_TIMESTAMP.sql.gz

# List backups
ls -lh ~/backups/
```

### Update Your Application

```bash
# Build new images locally or on EC2
docker build -t YOUR_DOCKERHUB_USERNAME/bugdrill-api:v1.1.0 .
docker push YOUR_DOCKERHUB_USERNAME/bugdrill-api:v1.1.0

# Update values-micro.yaml with new tag
nano backend/helm/interviewpal-api/values-micro.yaml
# image:
#   tag: "v1.1.0"

# Deploy update
helm upgrade bugdrill-api backend/helm/interviewpal-api \
  -n bugdrill \
  -f backend/helm/interviewpal-api/values-micro.yaml

# Watch rollout
kubectl rollout status deployment/bugdrill-api -n bugdrill
```

### Access Cluster from Local Machine

```bash
# On your local machine
# Copy kubeconfig from EC2
scp ubuntu@YOUR_IP:~/.kube/config ~/.kube/bugdrill-config

# Edit the config file
code ~/.kube/bugdrill-config
# Replace 127.0.0.1 with YOUR_ELASTIC_IP

# Use the config
export KUBECONFIG=~/.kube/bugdrill-config

# Now you can use kubectl locally!
kubectl get pods -n bugdrill
```

## 🔒 Security Hardening (Optional but Recommended)

### 1. Enable HTTPS with Let's Encrypt

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create certificate issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Install nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### 2. Restrict SSH Access

```bash
# Edit security group in AWS Console
# Or update main.tf and run terraform apply
# Change SSH ingress from your IP to a specific IP range
```

### 3. Enable Automatic Security Updates

```bash
# On EC2 instance
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📊 Monitoring & Alerts

### Setup CloudWatch (Optional - $3-5/month)

```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure to send logs and metrics to CloudWatch
# Follow: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html
```

### Free Monitoring with Prometheus (Uses ~50MB RAM)

```bash
# Install kube-prometheus-stack (lightweight version)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.resources.requests.memory=50Mi \
  --set prometheus.prometheusSpec.resources.limits.memory=100Mi

# Access Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000 (admin/prom-operator)
```

## 🆙 Scaling Up (When You Need It)

### When to Scale?

Scale up when you see:
- Consistent CPU > 70%
- Memory > 80% without swap
- API latency > 200ms
- Database queries slowing down

### How to Scale?

**Option 1: Vertical Scaling (Bigger Instance)**

```bash
# Stop instance
aws ec2 stop-instances --instance-ids INSTANCE_ID

# Change instance type
aws ec2 modify-instance-attribute \
  --instance-id INSTANCE_ID \
  --instance-type t4g.small  # 2GB RAM: $13/month

# Start instance
aws ec2 start-instances --instance-ids INSTANCE_ID

# Update resource limits in values-micro.yaml
```

**Option 2: Add Another Node (Multi-Node K3s)**

```bash
# Create a second EC2 instance (t4g.micro)
# Get K3s join token from master:
sudo cat /var/lib/rancher/k3s/server/node-token

# On new instance:
curl -sfL https://get.k3s.io | K3S_URL=https://MASTER_IP:6443 \
  K3S_TOKEN=YOUR_TOKEN sh -

# Now you have 2 nodes!
kubectl get nodes
```

**Option 3: Managed Database (When DB is bottleneck)**

```bash
# Create RDS PostgreSQL db.t4g.micro (~$15/month)
# Update Helm values to point to RDS endpoint
# Migrate data using pg_dump/pg_restore
```

## 🚨 Troubleshooting

### Pods not starting?

```bash
# Check pod status
kubectl describe pod POD_NAME -n bugdrill

# Check logs
kubectl logs POD_NAME -n bugdrill

# Common issue: Out of memory
free -h
# Solution: Enable swap or scale up instance
```

### Database connection failed?

```bash
# Check PostgreSQL pod
kubectl get pods -n bugdrill | grep postgres

# Check PostgreSQL logs
kubectl logs -n bugdrill POD_NAME

# Test connection from API pod
kubectl exec -it -n bugdrill API_POD_NAME -- nc -zv postgres-service 5432
```

### Out of disk space?

```bash
# Check disk usage
df -h

# Clean up old Docker images
docker system prune -a

# Clean up old logs
kubectl logs --tail=100 POD_NAME -n bugdrill
```

### High memory usage?

```bash
# Check what's using memory
kubectl top pods -n bugdrill

# Restart high-memory pod
kubectl rollout restart deployment/bugdrill-api -n bugdrill

# Adjust resource limits in values-micro.yaml
```

## 💡 Cost Optimization Tips

1. **Use AWS Free Tier**: First 12 months are essentially free
2. **Reserved Instances**: After free tier, save 40% with 1-year commitment
3. **Stop instance at night**: Save 50% if you're just testing
   ```bash
   # Stop
   aws ec2 stop-instances --instance-ids INSTANCE_ID
   # Start
   aws ec2 start-instances --instance-ids INSTANCE_ID
   ```
4. **Use Spot Instances**: Save 70% (not recommended for production)
5. **Optimize images**: Multi-stage builds reduce Docker image size
6. **CloudFlare CDN**: Free tier includes DDoS protection + caching

## 🎯 Production Checklist

Before going live:

- [ ] Set up automated backups (daily)
- [ ] Enable HTTPS with Let's Encrypt
- [ ] Set up monitoring/alerts
- [ ] Test backup restore process
- [ ] Document emergency procedures
- [ ] Set up DNS with your domain
- [ ] Enable auto-restart for pods
- [ ] Configure resource limits properly
- [ ] Set up log rotation
- [ ] Test mobile app connectivity
- [ ] Load test your API
- [ ] Set up health check monitoring (UptimeRobot - free)

## 📚 Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [PostgreSQL Tuning](https://pgtune.leopard.in.ua/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

## 🆘 Need Help?

- Check logs: `kubectl logs -f POD_NAME -n bugdrill`
- Cluster status: `./infrastructure/k3s/monitor.sh`
- K3s status: `sudo systemctl status k3s`
- Describe resources: `kubectl describe pod/svc/deployment NAME -n bugdrill`

---

**Estimated Setup Time**: 30-45 minutes  
**Monthly Cost**: $0 (Year 1) → $10 (Year 2+)  
**Scalability**: Add nodes as needed  
**Maintenance**: ~30 mins/week
