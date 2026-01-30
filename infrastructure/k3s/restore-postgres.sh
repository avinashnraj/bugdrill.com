#!/bin/bash
# Restore PostgreSQL from backup
# Usage: ./restore-postgres.sh <backup-file>

set -e

NAMESPACE=bugdrill

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh ~/backups/bugdrill_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "=== PostgreSQL Restore ==="
echo "Backup file: $BACKUP_FILE"
echo ""

# Get PostgreSQL pod name
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "Error: PostgreSQL pod not found"
    exit 1
fi

echo "Restoring to pod: $POD_NAME"
echo ""

# Warning
read -p "This will OVERWRITE the current database. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Restore
echo "Restoring database..."
gunzip -c $BACKUP_FILE | kubectl exec -i -n $NAMESPACE $POD_NAME -- psql -U postgres bugdrill

echo ""
echo "Restore complete!"
