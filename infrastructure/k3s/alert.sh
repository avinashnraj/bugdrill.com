# Basic monitoring alerts
# This script checks for critical issues and sends alerts
# Run via cron: */5 * * * * /home/ubuntu/alert.sh

#!/bin/bash

NAMESPACE=bugdrill
ALERT_FILE=/tmp/k3s-alerts.txt

# Clear previous alerts
> $ALERT_FILE

# Check if any pods are not running
NOT_RUNNING=$(kubectl get pods -n $NAMESPACE --no-headers | grep -v "Running" | wc -l)
if [ $NOT_RUNNING -gt 0 ]; then
    echo "⚠️  Warning: $NOT_RUNNING pods are not running" >> $ALERT_FILE
    kubectl get pods -n $NAMESPACE | grep -v "Running" >> $ALERT_FILE
fi

# Check disk space
DISK_USAGE=$(df /mnt/postgres-data | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "⚠️  Warning: PostgreSQL disk usage at $DISK_USAGE%" >> $ALERT_FILE
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ $MEM_USAGE -gt 85 ]; then
    echo "⚠️  Warning: Memory usage at $MEM_USAGE%" >> $ALERT_FILE
fi

# If there are alerts, display them
if [ -s $ALERT_FILE ]; then
    echo "=== ALERTS ===" 
    cat $ALERT_FILE
    
    # Optional: Send email or webhook
    # curl -X POST your-webhook-url -d "$(cat $ALERT_FILE)"
fi
