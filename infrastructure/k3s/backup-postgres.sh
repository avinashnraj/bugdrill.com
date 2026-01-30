#!/bin/bash
# PostgreSQL backup script for K3s deployment
# Schedule this with cron: 0 2 * * * /home/ubuntu/backup-postgres.sh

set -e

NAMESPACE=bugdrill
BACKUP_DIR=/home/ubuntu/backups
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

echo "=== PostgreSQL Backup - $TIMESTAMP ==="

# Get PostgreSQL pod name
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "Error: PostgreSQL pod not found"
    exit 1
fi

echo "Backing up from pod: $POD_NAME"

# Create backup
kubectl exec -n $NAMESPACE $POD_NAME -- pg_dump -U postgres bugdrill | gzip > $BACKUP_DIR/bugdrill_$TIMESTAMP.sql.gz

# Check backup size
BACKUP_SIZE=$(du -h $BACKUP_DIR/bugdrill_$TIMESTAMP.sql.gz | cut -f1)
echo "Backup created: bugdrill_$TIMESTAMP.sql.gz ($BACKUP_SIZE)"

# Upload to S3 (optional - uncomment if you set up AWS CLI)
# aws s3 cp $BACKUP_DIR/bugdrill_$TIMESTAMP.sql.gz s3://your-bucket/backups/

# Clean up old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "bugdrill_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup complete!"
echo ""
echo "Recent backups:"
ls -lh $BACKUP_DIR/bugdrill_*.sql.gz | tail -5
