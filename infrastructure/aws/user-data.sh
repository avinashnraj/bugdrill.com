#!/bin/bash
# User data script to initialize EC2 instance for K3s
# This runs on first boot

set -e

echo "=== Starting BugDrill K3s Setup ==="

# Update system
apt-get update
apt-get upgrade -y

# Install basic utilities
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    jq \
    unzip \
    ca-certificates

# Format and mount EBS volume for PostgreSQL (if not already formatted)
if ! blkid /dev/nvme1n1; then
    mkfs.ext4 /dev/nvme1n1
fi

mkdir -p /mnt/postgres-data
echo '/dev/nvme1n1 /mnt/postgres-data ext4 defaults,nofail 0 2' >> /etc/fstab
mount -a
chown -R 999:999 /mnt/postgres-data  # PostgreSQL UID/GID in container

# Install K3s (lightweight Kubernetes)
# --disable traefik: We'll use our own ingress or none
# --write-kubeconfig-mode 644: Make kubeconfig readable
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --kube-apiserver-arg 'service-node-port-range=80-32767'

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until kubectl get nodes 2>/dev/null; do
    sleep 5
done

# Create namespace for our application
kubectl create namespace bugdrill || true

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create persistent volume for PostgreSQL on EBS mount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 15Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/postgres-data
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: bugdrill
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 15Gi
EOF

# Create a swap file (helps with 1GB RAM constraint)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Enable kernel parameters for better performance
cat <<EOF >> /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
net.ipv4.tcp_keepalive_time=600
EOF
sysctl -p

# Create deployment script
cat <<'DEPLOY_SCRIPT' > /home/ubuntu/deploy.sh
#!/bin/bash
# Deployment script for BugDrill application

set -e

NAMESPACE=bugdrill
RELEASE_NAME=bugdrill-api

echo "=== Deploying BugDrill to K3s ==="

# Update Helm chart
helm upgrade --install $RELEASE_NAME /home/ubuntu/bugdrill/backend/helm/interviewpal-api \
    --namespace $NAMESPACE \
    --values /home/ubuntu/bugdrill/backend/helm/interviewpal-api/values-micro.yaml \
    --create-namespace \
    --wait

echo "=== Deployment complete ==="
kubectl get pods -n $NAMESPACE
DEPLOY_SCRIPT

chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh

echo "=== K3s setup complete ==="
echo "Cluster is ready!"
kubectl get nodes
