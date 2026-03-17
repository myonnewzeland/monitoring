# Updates and Maintenance Guide

Procedimientos para actualizar y mantener el stack de monitoreo.

## 🔄 Update Procedures

### Version Compatibility Matrix

| Component | Current Version | Compatible Updates | Testing Required |
|-----------|----------------|-------------------|------------------|
| Caddy | latest | Major versions | ✅ Yes |
| Grafana | latest | Major versions | ✅ Yes |
| Prometheus | latest | Major versions | ✅ Yes |
| cAdvisor | latest | Any version | ⚠️ Recommended |
| node-exporter | latest | Any version | ⚠️ Recommended |

### Pre-Update Checklist

- [ ] Create full backup of all volumes
- [ ] Test update in staging environment first
- [ ] Review changelog for breaking changes
- [ ] Schedule maintenance window
- [ ] Notify users of potential downtime
- [ ] Prepare rollback plan

### Update Methods

#### Method 1: Rolling Updates (Zero Downtime)

**For minor version updates:**
```bash
# 1. Pull latest images
docker compose pull

# 2. Update one service at a time
docker compose up -d --no-deps grafana
sleep 30  # Wait for health check
docker compose up -d --no-deps prometheus
sleep 30
docker compose up -d --no-deps caddy

# 3. Verify all services
docker compose ps
./scripts/health-check.sh
```

#### Method 2: Full Stack Update (Downtime Required)

**For major version updates:**
```bash
# 1. Stop all services
docker compose down

# 2. Pull new images
docker compose pull

# 3. Update configuration files if needed
# Edit docker-compose.yml, Caddyfile, etc.

# 4. Start services
docker compose up -d

# 5. Verify functionality
./scripts/health-check.sh
```

### Component-Specific Updates

#### Grafana Updates
```bash
# 1. Backup Grafana data
docker run --rm -v monitoring_grafana-data:/data -v $(pwd)/backups:/backup alpine tar -czf /backup/grafana-pre-update.tar.gz -C /data .

# 2. Update image
docker compose pull grafana
docker compose up -d grafana

# 3. Check plugins compatibility
docker exec grafana grafana-cli plugins ls

# 4. Verify dashboards
curl -u admin:password https://grafana.luam.us.kg/api/search
```

#### Prometheus Updates
```bash
# 1. Backup Prometheus data
docker run --rm -v monitoring_prometheus-data:/data -v $(pwd)/backups:/backup alpine tar -czf /backup/prometheus-pre-update.tar.gz -C /data .

# 2. Validate new configuration
docker run --rm -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:ro prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml

# 3. Update service
docker compose pull prometheus
docker compose up -d prometheus

# 4. Verify data migration
curl http://localhost:9090/api/v1/query?query=up
```

#### Caddy Updates
```bash
# 1. Backup Caddy data
docker run --rm -v monitoring_caddy-data:/data -v $(pwd)/backups:/backup alpine tar -czf /backup/caddy-pre-update.tar.gz -C /data .

# 2. Validate Caddyfile
docker run --rm -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro caddy:latest caddy validate --config /etc/caddy/Caddyfile

# 3. Update service
docker compose pull caddy
docker compose up -d caddy

# 4. Verify HTTPS
curl -I https://grafana.luam.us.kg
```

## 🔙 Rollback Procedures

### Immediate Rollback
```bash
# 1. Stop affected services
docker compose stop <service>

# 2. Restore previous version
# Edit docker-compose.yml to use previous image tag
docker compose up -d --no-deps <service>

# 3. Verify functionality
./scripts/health-check.sh
```

### Data Restoration Rollback
```bash
# 1. Stop services
docker compose down

# 2. Restore data from backup
docker run --rm -v monitoring_grafana-data:/data -v $(pwd)/backups:/backup alpine tar -xzf /backup/grafana-pre-update.tar.gz -C /data
docker run --rm -v monitoring_prometheus-data:/data -v $(pwd)/backups:/backup alpine tar -xzf /backup/prometheus-pre-update.tar.gz -C /data

# 3. Start services
docker compose up -d

# 4. Verify data integrity
curl -u admin:password https://grafana.luam.us.kg/api/datasources
```

## 📅 Maintenance Schedule

### Daily Tasks
- [ ] Check service health: `docker compose ps`
- [ ] Review logs for errors: `docker compose logs --tail=50`
- [ ] Verify backups are running: `ls -lh backups/`
- [ ] Check disk space: `df -h`

### Weekly Tasks
- [ ] Review Prometheus targets: https://prometheus.luam.us.kg/targets
- [ ] Check Grafana dashboards functionality
- [ ] Review alert rules firing
- [ ] Verify backup integrity
- [ ] Check for security updates

### Monthly Tasks
- [ ] Review and update container images
- [ ] Test backup restoration procedure
- [ ] Review and rotate credentials (quarterly)
- [ ] Audit security configurations
- [ ] Review resource usage and capacity planning
- [ ] Update documentation

### Quarterly Tasks
- [ ] Security audit of all configurations
- [ ] Performance testing and optimization
- [ ] Disaster recovery testing
- [ ] Review and update alerting rules
- [ ] Credential rotation
- [ ] Review retention policies

## 🔍 Troubleshooting Updates

### Update Fails to Start

**Symptoms:** Service won't start after update

**Solutions:**
```bash
# 1. Check logs
docker compose logs <service>

# 2. Check for configuration errors
docker compose config

# 3. Verify image pull
docker images | grep <service>

# 4. Try recreating container
docker compose up -d --force-recreate <service>
```

### Data Loss After Update

**Symptoms:** Missing data after update

**Solutions:**
```bash
# 1. Stop service immediately
docker compose stop <service>

# 2. Restore from backup
# See rollback procedures above

# 3. Investigate cause
docker inspect <container>
```

### Performance Degradation

**Symptoms:** Slower performance after update

**Solutions:**
```bash
# 1. Check resource usage
docker stats

# 2. Review configuration changes
git diff HEAD~1 docker-compose.yml

# 3. Check for new features causing overhead
# Review release notes

# 4. Consider rollback if severe
```

## 📋 Update Templates

### Update Notification Template

```
SUBJECT: Scheduled Maintenance - Monitoring Stack Update

Dear Team,

We will be performing scheduled maintenance on the monitoring stack:

**Date:** [Date]
**Time:** [Time window]
**Duration:** [Expected duration]
**Impact:** [Expected impact]

**Services affected:**
- Grafana: [Expected behavior]
- Prometheus: [Expected behavior]
- cAdvisor: [Expected behavior]

**Rollback plan:** [Rollback procedure]

**Contact:** [Your contact information]
```

### Post-Update Checklist Template

```
## Post-Update Verification

- [ ] All services running
- [ ] Health checks passing
- [ ] Data integrity verified
- [ ] Alerts functioning
- [ ] Dashboards accessible
- [ ] Performance baseline met
- [ ] No errors in logs
- [ ] Backups continuing
- [ ] Security features active
- [ ] Documentation updated
```

## 🚨 Emergency Procedures

### Critical Update Failure

**If update causes system-wide failure:**

1. **Immediate Actions:**
   ```bash
   # Stop update process
   docker compose down

   # Restore from pre-update backup
   # See rollback procedures

   # Notify stakeholders
   ```

2. **Investigation:**
   - Collect logs: `docker compose logs > update-failure.log`
   - Document errors
   - Identify root cause

3. **Recovery:**
   - Implement fix
   - Test thoroughly
   - Retry update with new approach

### Security Emergency Update

**For critical security vulnerabilities:**

1. **Assess Severity:**
   - Check CVSS score
   - Review exploit availability
   - Evaluate exposure risk

2. **Emergency Update:**
   ```bash
   # Expedited update process
   docker compose pull
   docker compose up -d --force-recreate

   # Skip testing if critical
   # Monitor closely
   ```

3. **Post-Emergency:**
   - Full security audit
   - Review all configurations
   - Update procedures

---

**Document Owner:** Infrastructure Team
**Last Updated:** 2026-03-17
**Next Review:** 2026-06-17