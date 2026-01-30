#!/bin/bash
# Setup automated backups with cron

set -e

echo "=== Setting up automated PostgreSQL backups ==="

# Make backup scripts executable
chmod +x ~/bugdrill/infrastructure/k3s/backup-postgres.sh
chmod +x ~/bugdrill/infrastructure/k3s/restore-postgres.sh

# Create cron job (runs daily at 2 AM)
CRON_JOB="0 2 * * * $HOME/bugdrill/infrastructure/k3s/backup-postgres.sh >> $HOME/backup.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "backup-postgres.sh"; then
    echo "Cron job already exists"
else
    echo "Adding cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added: Daily backups at 2 AM"
fi

# Create initial backup
echo ""
echo "Creating initial backup..."
$HOME/bugdrill/infrastructure/k3s/backup-postgres.sh

echo ""
echo "=== Backup setup complete ==="
echo ""
echo "Backups will run daily at 2 AM"
echo "Backups are stored in: $HOME/backups"
echo "Retention: 7 days"
echo ""
echo "Manual backup: ~/bugdrill/infrastructure/k3s/backup-postgres.sh"
echo "Restore: ~/bugdrill/infrastructure/k3s/restore-postgres.sh <backup-file>"
