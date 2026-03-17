# Operations Guide

Complete operational procedures for maintaining the monitoring stack.

## 🚨 Disaster Recovery

### Backup Restoration

**Prerequisites:**
- Latest backup files available
- Docker and Docker Compose installed
- Sufficient disk space

**Restore Grafana:**
```bash
# Stop Grafana service
docker compose stop grafana

# Restore from backup
tar -xzf backups/grafana/grafana-YYYYMMDD-HHMMSS.tar.gz -C /var/lib/docker/volumes/monitoring_grafana-data/_data/

# Restart service
docker compose start grafana
```

**Restore Prometheus:**
```bash
# Stop Prometheus service
docker compose stop prometheus

# Restore from backup
tar -xzf backups/prometheus/prometheus-YYYYMMDD-HHMMSS.tar.gz -C /var/lib/docker/volumes/monitoring_prometheus-data/_data/

# Restart service
docker compose start prometheus
```

**Restore Encrypted Backups:**
```bash
# Decrypt and restore
gpg --decrypt backups/grafana/grafana-YYYYMMDD-HHMMSS.tar.gz.gpg | tar -xz -C /var/lib/docker/volumes/monitoring_grafana-data/_data/
```

### Complete System Recovery

**Procedure:**
1. **System Preparation**
   ```bash
   # Install dependencies
   apt update && apt install -y docker.io docker-compose-plugin

   # Clone repository
   git clone <your-repo>
   cd monitoring
   ```

2. **Credential Restoration**
   ```bash
   # Restore .env from secure backup
   # OR regenerate credentials
   ./scripts/setup-auth.sh
   ```

3. **Service Recovery**
   ```bash
   # Start all services
   docker compose up -d

   # Verify services
   docker compose ps
   ```

4. **Data Validation**
   ```bash
   # Check Grafana dashboards
   curl -u admin:password https://grafana.luam.us.kg/api/search

   # Verify Prometheus targets
   curl -u prometheus-admin:password https://prometheus.luam.us.kg/api/v1/targets
   ```

## 🔄 Maintenance Procedures

### Daily Operations

**Health Checks:**
```bash
# Check service status
docker compose ps

# Check logs for errors
docker compose logs --tail=100 | grep -i error

# Verify backups are running
ls -lh backups/grafana/ | tail -5
ls -lh backups/prometheus/ | tail -5
```

**Metrics Verification:**
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="up") | .job'

# Verify Grafana data source
curl -s http://localhost:3000/api/datasources | jq '.[0].name'
```

### Weekly Operations

**Log Rotation:**
```bash
# Rotate Caddy logs
docker exec caddy logrotate -f /etc/logrotate.conf

# Check disk usage
du -sh /var/lib/docker/volumes/
```

**Performance Review:**
```bash
# Check container resource usage
docker stats --no-stream

# Review Prometheus performance metrics
curl -s http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_samples_appended_total
```

### Monthly Operations

**Security Updates:**
```bash
# Pull latest images
docker compose pull

# Recreate services
docker compose up -d --force-recreate

# Verify functionality
./scripts/health-check.sh
```

**Backup Verification:**
```bash
# Test restore procedure
./scripts/test-backup-restore.sh

# Verify backup integrity
./scripts/verify-backups.sh
```

## 🚀 Deployment Procedures

### Initial Deployment

**Pre-Deployment Checklist:**
- [ ] DNS records configured
- [ ] Firewall rules enabled (80/443)
- [ ] SSL certificates ready (or Let's Encrypt)
- [ ] Backup destination configured
- [ ] Monitoring alerts configured
- [ ] Security review completed

**Deployment Steps:**
```bash
# 1. Setup credentials
./scripts/setup-auth.sh

# 2. Configure environment
cp .env.example .env
# Edit .env with your values

# 3. Start services
docker compose up -d

# 4. Verify deployment
docker compose ps
curl -I https://grafana.luam.us.kg
curl -I https://prometheus.luam.us.kg

# 5. Configure initial dashboards
# Access Grafana and import default dashboards
```

### Rolling Updates

**Zero-Downtime Updates:**
```bash
# 1. Pull new images
docker compose pull

# 2. Update one service at a time
docker compose up -d --no-deps grafana
docker compose up -d --no-deps prometheus

# 3. Verify each service
docker compose ps
docker compose logs --tail=50 grafana
```

### Emergency Rollback

**Procedure:**
```bash
# 1. Stop current services
docker compose down

# 2. Restore previous image versions
# Edit docker-compose.yml with previous tags

# 3. Restore data if needed
./scripts/restore-backup.sh <backup-file>

# 4. Start services
docker compose up -d

# 5. Verify functionality
docker compose ps
```

## 🔍 Troubleshooting

### Common Issues

**Service Won't Start:**
```bash
# Check logs
docker compose logs <service>

# Check resource availability
docker system df

# Check port conflicts
netstat -tulpn | grep -E ':(80|443|3000|9090)'

# Restart Docker daemon
sudo systemctl restart docker
```

**High Memory Usage:**
```bash
# Check container stats
docker stats

# Restart memory-intensive service
docker compose restart prometheus

# Adjust Prometheus retention
# Edit prometheus.yml: --storage.tsdb.retention.time=15d
```

**Backup Failures:**
```bash
# Check backup logs
docker compose logs -f backup

# Verify backup destination
ls -lh backups/

# Test backup manually
docker exec backup /bin/sh -c "tar -czf /tmp/test.tar.gz -C /source/grafana ."
```

### Debug Mode

**Enable Debug Logging:**
```yaml
# docker-compose.yml
services:
  grafana:
    environment:
      GF_LOG_LEVEL: "debug"

  prometheus:
    command:
      - '--log.level=debug'
```

**Network Issues:**
```bash
# Test internal connectivity
docker exec grafana wget -O- http://prometheus:9090

# Check DNS resolution
docker exec grafana nslookup prometheus

# Verify network connectivity
docker network inspect monitoring
```

## 📊 Performance Tuning

### Prometheus Optimization

**Adjust Scrape Intervals:**
```yaml
# prometheus.yml
global:
  scrape_interval: 30s  # Reduce from 15s
  evaluation_interval: 30s
```

**Configure Retention:**
```yaml
# docker-compose.yml
command:
  - '--storage.tsdb.retention.time=30d'  # 30 days retention
  - '--storage.tsdb.retention.size=50GB'  # Max 50GB
```

### Grafana Optimization

**Enable Caching:**
```ini
# grafana.ini
[caching]
enabled = true
ttl = 5m
```

**Adjust Query Timeout:**
```ini
[database]
max_open_conns = 10
max_idle_conns = 5
conn_max_lifetime = 14400
```

## 🔧 Configuration Management

### Environment-Specific Configs

**Development:**
```bash
cp .env.development .env
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

**Staging:**
```bash
cp .env.staging .env
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

**Production:**
```bash
cp .env.production .env
docker compose up -d
```

### Configuration Validation

**Validate Caddyfile:**
```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

**Validate Prometheus config:**
```bash
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

**Validate alert rules:**
```bash
docker exec prometheus promtool check rules /etc/prometheus/alerts/*.yml
```

## 📈 Monitoring the Monitoring Stack

**Self-Monitoring Dashboard:**
- Import Grafana dashboard for Docker metrics
- Set up alerts for:
  - Container restarts
  - High memory usage
  - Disk space exhaustion
  - Backup failures

**Health Check Endpoints:**
```bash
# Service health checks
curl -f http://localhost:3000/api/health || echo "Grafana down"
curl -f http://localhost:9090/-/healthy || echo "Prometheus down"
curl -f http://localhost:8080/healthz || echo "cAdvisor down"
```

---

**Document Owner**: Infrastructure Team
**Last Updated**: 2026-03-17
**Next Review**: 2026-06-17