#!/bin/sh

set -eu

# Backup Script with Optional Encryption
# This script creates encrypted backups of Grafana and Prometheus data

BACKUP_INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-86400}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_ENCRYPT="${BACKUP_ENCRYPT:-false}"
BACKUP_GPG_RECIPIENT="${BACKUP_GPG_RECIPIENT:-}"

mkdir -p /backups/grafana /backups/prometheus

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

check_gpg() {
    if [ "$BACKUP_ENCRYPT" = "true" ]; then
        if ! command -v gpg >/dev/null 2>&1; then
            log_error "GPG requested but not installed. Installing..."
            apk add --no-cache gnupg
        fi

        if [ -z "$BACKUP_GPG_RECIPIENT" ]; then
            log_error "BACKUP_GPG_RECIPIENT is required when BACKUP_ENCRYPT=true"
            log_error "Falling back to unencrypted backups"
            BACKUP_ENCRYPT="false"
        fi
    fi
}

backup_grafana() {
    TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
    DESTINATION="/backups/grafana"
    SOURCE="/source/grafana"

    log_info "Creating Grafana backup..."

    if [ "$BACKUP_ENCRYPT" = "true" ]; then
        tar -czf - -C "$SOURCE" . | gpg --encrypt --recipient "$BACKUP_GPG_RECIPIENT" --output "$DESTINATION/grafana-$TIMESTAMP.tar.gz.gpg"
        log_info "Grafana backup encrypted: $DESTINATION/grafana-$TIMESTAMP.tar.gz.gpg"
    else
        tar -czf "$DESTINATION/grafana-$TIMESTAMP.tar.gz" -C "$SOURCE" .
        log_info "Grafana backup created: $DESTINATION/grafana-$TIMESTAMP.tar.gz"
    fi

    # Clean old backups
    find "$DESTINATION" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete
    log_info "Cleaned backups older than $BACKUP_RETENTION_DAYS days"
}

backup_prometheus() {
    TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
    DESTINATION="/backups/prometheus"
    SOURCE="/source/prometheus"

    log_info "Creating Prometheus backup..."

    if [ "$BACKUP_ENCRYPT" = "true" ]; then
        tar -czf - -C "$SOURCE" . | gpg --encrypt --recipient "$BACKUP_GPG_RECIPIENT" --output "$DESTINATION/prometheus-$TIMESTAMP.tar.gz.gpg"
        log_info "Prometheus backup encrypted: $DESTINATION/prometheus-$TIMESTAMP.tar.gz.gpg"
    else
        tar -czf "$DESTINATION/prometheus-$TIMESTAMP.tar.gz" -C "$SOURCE" .
        log_info "Prometheus backup created: $DESTINATION/prometheus-$TIMESTAMP.tar.gz"
    fi

    # Clean old backups
    find "$DESTINATION" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete
    log_info "Cleaned backups older than $BACKUP_RETENTION_DAYS days"
}

backup_all() {
    log_info "Starting backup process..."
    check_gpg
    backup_grafana
    backup_prometheus
    log_info "Backup process completed successfully"
}

# Initial backup
backup_all

# Schedule regular backups
while true; do
    sleep "$BACKUP_INTERVAL_SECONDS"
    backup_all
done