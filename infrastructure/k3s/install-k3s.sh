#!/bin/bash
# Setup script to install K3s on Ubuntu server
# Run this after SSH'ing into your EC2 instance

set -e

echo "=== BugDrill K3s Installation Script ==="
echo "This script will install K3s and configure it for BugDrill"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please run as normal user (not root)"
    exit 1
fi

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    htop \
    jq \
    ca-certificates \
    gnupg \
    lsb-release

# Create swap file (2GB) to help with memory constraints
if [ ! -f /swapfile ]; then
    echo "Creating swap file (2GB)..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    # Optimize swap usage
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Format and mount EBS volume for PostgreSQL data
echo "Setting up PostgreSQL data volume..."
if ! sudo blkid /dev/nvme1n1; then
    echo "Formatting EBS volume..."
    sudo mkfs.ext4 /dev/nvme1n1
fi

sudo mkdir -p /mnt/postgres-data

# Add to fstab if not already there
if ! grep -q "/mnt/postgres-data" /etc/fstab; then
    echo '/dev/nvme1n1 /mnt/postgres-data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
fi

sudo mount -a
sudo chown -R 999:999 /mnt/postgres-data  # PostgreSQL container UID/GID

# Install K3s
echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --kube-apiserver-arg 'service-node-port-range=80-32767'

# Wait for K3s to be ready
echo "Waiting for K3s to start..."
sleep 10
until sudo kubectl get nodes 2>/dev/null; do
    echo "Waiting for K3s..."
    sleep 5
done

# Set up kubectl for regular user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Install Helm
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Create namespace
echo "Creating bugdrill namespace..."
kubectl create namespace bugdrill || true

# Create persistent volume for PostgreSQL
echo "Creating persistent volume for PostgreSQL..."
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

# Create secrets template
echo "Creating secrets template..."
cat <<EOF > ~/bugdrill-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bugdrill-secrets
  namespace: bugdrill
type: Opaque
stringData:
  DB_PASSWORD: "CHANGE_ME_$(openssl rand -hex 16)"
  JWT_ACCESS_SECRET: "$(openssl rand -hex 32)"
  JWT_REFRESH_SECRET: "$(openssl rand -hex 32)"
EOF

kubectl apply -f ~/bugdrill-secrets.yaml

echo ""
echo "=== K3s installation complete! ==="
echo ""
echo "Cluster status:"
kubectl get nodes
echo ""
echo "To access this cluster from your local machine:"
echo "1. Run: scp ubuntu@YOUR_IP:~/.kube/config ~/.kube/bugdrill-config"
echo "2. Edit ~/.kube/bugdrill-config and replace '127.0.0.1' with your EC2 public IP"
echo "3. Run: export KUBECONFIG=~/.kube/bugdrill-config"
echo ""
echo "Next steps:"
echo "1. Clone your repository: git clone https://github.com/YOUR_USERNAME/bugdrill.git"
echo "2. Build and push Docker images"
echo "3. Run: helm upgrade --install bugdrill-api ./bugdrill/backend/helm/interviewpal-api -f ./bugdrill/backend/helm/interviewpal-api/values-micro.yaml -n bugdrill"
