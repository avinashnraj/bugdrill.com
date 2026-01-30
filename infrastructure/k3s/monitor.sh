#!/bin/bash
# Simple monitoring script for K3s cluster
# Run with: watch -n 5 ./monitor.sh

echo "=== BugDrill K3s Cluster Status ==="
echo ""

# System resources
echo "📊 System Resources:"
echo "-------------------"
free -h | grep -E "Mem|Swap"
echo ""
df -h /mnt/postgres-data | tail -1
echo ""

# Cluster status
echo "🔧 K3s Cluster:"
echo "-------------------"
kubectl get nodes
echo ""

# Namespace resources
echo "📦 BugDrill Pods (namespace: bugdrill):"
echo "-------------------"
kubectl top pods -n bugdrill 2>/dev/null || echo "Metrics not available (install metrics-server)"
kubectl get pods -n bugdrill
echo ""

# Services
echo "🌐 Services:"
echo "-------------------"
kubectl get svc -n bugdrill
echo ""

# Recent events
echo "📋 Recent Events:"
echo "-------------------"
kubectl get events -n bugdrill --sort-by='.lastTimestamp' | tail -10
