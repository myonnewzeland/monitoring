#!/bin/sh

set -eu

BACKUP_INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-86400}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
TIMESTAMP=""
DESTINATION=""

mkdir -p /backups/grafana /backups/prometheus

backup_once() {
  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  DESTINATION="/backups"

  tar -czf "$DESTINATION/grafana/grafana-$TIMESTAMP.tar.gz" -C /source/grafana .
  tar -czf "$DESTINATION/prometheus/prometheus-$TIMESTAMP.tar.gz" -C /source/prometheus .

  find "$DESTINATION/grafana" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete
  find "$DESTINATION/prometheus" -type f -mtime +"$BACKUP_RETENTION_DAYS" -delete
}

backup_once

while true; do
  sleep "$BACKUP_INTERVAL_SECONDS"
  backup_once
done
