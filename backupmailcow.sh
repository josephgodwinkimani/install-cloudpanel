#!/bin/bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

read -p "Enter the backup location (default: /opt/mailcow-backups): " USER_BACKUP_LOCATION

BACKUP_LOCATION=${USER_BACKUP_LOCATION:-/opt/mailcow-backups}

if [ ! -d "$BACKUP_LOCATION" ]; then
    log_info "Backup directory does not exist. Creating directory: $BACKUP_LOCATION"
    mkdir -p "$BACKUP_LOCATION"
else
    log_info "Using existing backup directory: $BACKUP_LOCATION"
fi

read -p "Enter the number of days to retain backups (default: 30 days): " USER_RETENTION_DAYS

RETENTION_DAYS=${USER_RETENTION_DAYS:-30}

SCRIPT="/opt/mailcow-dockerized/helper-scripts/backup_and_restore.sh"

PARAMETERS="backup all"
OPTIONS="--delete-days $RETENTION_DAYS"

log_info "Starting Mailcow backup..."
set +e
"$SCRIPT" $PARAMETERS $OPTIONS 2>&1 | tee "$BACKUP_LOCATION/backup_log_$(date +%Y%m%d_%H%M%S).log"
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "MailDir Backup encountered an error. Check the log for details."
else
    echo "MailDir Backup completed successfully."
fi

log_info "Backing up Mailcow MySQL database..."
source /opt/mailcow-dockerized/mailcow.conf
DATE=$(date +"%Y%m%d_%H%M%S")
docker compose exec -T mysql-mailcow mysqldump --default-character-set=utf8mb4 -u${DBUSER} -p${DBPASS} ${DBNAME} > "$BACKUP_LOCATION/backup_${DBNAME}_${DATE}.sql"

if [ $? -eq 0 ]; then
  echo "Mailcow Backup successful! Located at: $BACKUP_LOCATION"
else
  echo "Mailcow Backup failed!"
fi
