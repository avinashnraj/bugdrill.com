# Ingress Setup Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ LOCAL DEVELOPMENT (k3d)                                     │
├─────────────────────────────────────────────────────────────┤
│ Mobile App → localhost:8080 → bugdrill-k3d-runner:80       │
│           → Traefik Ingress (api.bugdrill.local)           │
│           → bugdrill-api Service:8080                       │
│           → API Pod                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PRODUCTION (EC2 + k3s)                                      │
├─────────────────────────────────────────────────────────────┤
│ Route53 (api.bugdrill.com) → EC2 Public IP:80/443          │
│                            → Traefik Ingress                │
│                            → bugdrill-api Service:8080      │
│                            → API Pod                        │
└─────────────────────────────────────────────────────────────┘
```

## Local Setup (k3d)

### 1. Add to Windows hosts file
**File**: `C:\Windows\System32\drivers\etc\hosts` (requires Admin)

```
127.0.0.1  api.bugdrill.local
```

### 2. Restart k3d runner container
```powershell
cd backend
docker-compose -f docker-compose.k3d.yml down
docker-compose -f docker-compose.k3d.yml up -d
```

### 3. Run full rebuild
```powershell
docker exec -ti bugdrill-k3d-runner bash -c "cd /workspace && make k3d-full-rebuild"
```

### 4. Test the ingress
```powershell
# Test with curl
curl http://api.bugdrill.local:8080/api/v1/health

# Or test in browser
# http://api.bugdrill.local:8080/api/v1/health
```

### 5. Update mobile app config
**File**: `mobile/src/constants/config.ts`

```typescript
export const API_CONFIG = {
  BASE_URL: __DEV__ 
    ? 'http://api.bugdrill.local:8080/api/v1'  // Local k3d
    : 'https://api.bugdrill.com/api/v1',       // Production
  
  TIMEOUT: 10000,
};
```

## Production Setup (EC2 + k3s)

### 1. Point Route53 to EC2 Public IP
Create an **A Record**:
- **Name**: `api.bugdrill.com`
- **Type**: `A`
- **Value**: Your EC2 public IP (e.g., `54.123.45.67`)
- **TTL**: `300`

### 2. Configure EC2 Security Group
Allow inbound traffic:
- **Port 80** (HTTP) - from `0.0.0.0/0`
- **Port 443** (HTTPS) - from `0.0.0.0/0`
- **Port 22** (SSH) - from your IP only

### 3. Deploy to EC2
```bash
# SSH into EC2
ssh ubuntu@<your-ec2-ip>

# Navigate to backend
cd /path/to/bugdrill/backend

# Deploy everything
make ec2-full-deploy
```

### 4. Verify Traefik is running
```bash
kubectl get pods -n kube-system | grep traefik
kubectl get svc -n kube-system traefik
```

### 5. Test the production ingress
```bash
# From EC2 (local test)
curl http://localhost/api/v1/health

# From anywhere (public test)
curl http://api.bugdrill.com/api/v1/health
```

## SSL/TLS Setup (Optional - Future)

### Option 1: Let's Encrypt with cert-manager
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f k3d-manifests/ingress-production.yaml
```

### Option 2: Manual SSL Certificate
- Purchase SSL certificate
- Create Kubernetes secret:
```bash
kubectl create secret tls bugdrill-api-tls \
  --cert=/path/to/cert.pem \
  --key=/path/to/key.pem \
  -n bugdrill
```

## Cost Breakdown (No ALB)

| Service | Monthly Cost |
|---------|--------------|
| EC2 t4g.small | ~$12 |
| Route53 Hosted Zone | $0.50 |
| Route53 Queries (1M) | $0.40 |
| **Total** | **~$13/month** |

vs. with ALB: ~$28/month (ALB alone is $16/month + data transfer)

## Scaling Strategy

### Current (Single Node)
- EC2 t4g.small
- All pods on one node
- Traefik ingress controller
- Good for: 0-1000 users

### Future (Multi-Node + ALB)
When traffic increases:
1. Add more EC2 nodes to k3s cluster
2. Switch to AWS ALB for better load balancing
3. Use AWS Certificate Manager for free SSL
4. Enable autoscaling

```bash
# Future Makefile target (when ready)
make ec2-enable-alb
```

## Troubleshooting

### Ingress not working?
```bash
# Check Traefik
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# Check ingress
kubectl get ingress -n bugdrill
kubectl describe ingress bugdrill-api-ingress -n bugdrill

# Check service
kubectl get svc -n bugdrill bugdrill-api

# View Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
```

### DNS not resolving?
```bash
# Test DNS
nslookup api.bugdrill.com
dig api.bugdrill.com

# Verify Route53 record
aws route53 list-resource-record-sets --hosted-zone-id <your-zone-id>
```

### Connection timeout on EC2?
- Check security group rules (port 80/443 open)
- Verify Traefik service is exposed:
```bash
kubectl get svc -n kube-system traefik -o wide
```
