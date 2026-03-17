# Monitoring Stack

Lightweight self-hosted monitoring stack with `Caddy`, `Prometheus`, `Grafana`, `cAdvisor`, and `node-exporter` running on Docker Compose.

Only `80` and `443` are exposed on the host. `Caddy` terminates TLS, applies shared security headers, and proxies each public domain to an internal service. Grafana is provisioned automatically, Prometheus loads alert rules on startup, backups are generated on a schedule, and sensitive endpoints can be protected with basic auth.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                      Public Domain Access                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ grafana.luam... │  │ prometheus.l... │  │ cadvisor.lua... │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Caddy Reverse Proxy                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Auto HTTPS  │  │ Compression │  │ Sec Headers │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Internal Monitoring Network                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Grafana   │  │ Prometheus  │  │  cAdvisor   │              │
│  │    :3000    │  │    :9090    │  │    :8080    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                 │
│                 ┌─────────────────────────────┐                 │
│                 │      node-exporter:9100     │                 │
│                 └─────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## Public Endpoints

- `grafana.luam.us.kg` -> Grafana UI
- `prometheus.luam.us.kg` -> Prometheus UI and targets page, protected with basic auth
- `cadvisor.luam.us.kg` -> cAdvisor container metrics UI, protected with basic auth

## Internal Services

- `grafana:3000`
- `prometheus:9090`
- `cadvisor:8080`
- `node-exporter:9100`

## Components

- `Caddy` handles HTTPS, reverse proxying, compression, and shared response headers
- `Prometheus` scrapes and stores metrics from the stack
- `Grafana` visualizes metrics collected by Prometheus
- `cAdvisor` exposes Docker container metrics
- `node-exporter` exposes host-level CPU, memory, disk, and filesystem metrics
- `backup` creates compressed backups of Grafana and Prometheus data volumes

## Requirements

- Docker and Docker Compose installed
- DNS records for `grafana.luam.us.kg`, `prometheus.luam.us.kg`, and `cadvisor.luam.us.kg` pointing to the host
- Ports `80` and `443` reachable from the internet

## Credentials

Grafana now reads its admin credentials from environment variables.

1. Copy the example file:

```bash
cp .env.example .env
```

2. Set a strong password in `.env`:

```dotenv
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=use-a-long-random-password-here
PROMETHEUS_BASIC_AUTH_USER=prometheus-admin
PROMETHEUS_BASIC_AUTH_HASH=<bcrypt-hash>
CADVISOR_BASIC_AUTH_USER=cadvisor-admin
CADVISOR_BASIC_AUTH_HASH=<bcrypt-hash>
```

3. Recreate the stack:

```bash
docker compose up -d --force-recreate
```

Notes:

- Do not commit `.env`
- Change the default password before exposing Grafana publicly
- `Prometheus` and `cAdvisor` are protected by Caddy basic auth in this setup
- You can generate bcrypt hashes with `htpasswd -nbBC 12 user your-password | cut -d: -f2`

## Provisioning

Grafana is provisioned automatically with:

- a default `Prometheus` data source
- a starter dashboard provider
- a `Monitoring Overview` dashboard from `grafana/dashboards/monitoring-overview.json`

Provisioning files:

- `grafana/provisioning/datasources/prometheus.yml`
- `grafana/provisioning/dashboards/default.yml`
- `grafana/dashboards/monitoring-overview.json`

## Prometheus Alerts

Prometheus loads rule files from `alerts/*.yml`.

Included alert rules:

- `PrometheusTargetDown`
- `HighHostCpuUsage`
- `HighHostMemoryUsage`
- `LowHostDiskSpace`

Alert rules file:

- `alerts/monitoring.rules.yml`

## Quick Start

Start the full stack:

```bash
docker compose up -d
```

Check container status:

```bash
docker compose ps
```

Follow logs:

```bash
docker compose logs -f caddy
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f backup
```

## Day-to-Day Operations

Restart all services:

```bash
docker compose restart
```

Recreate containers after config changes:

```bash
docker compose up -d --force-recreate
```

Stop the stack:

```bash
docker compose down
```

## How Metrics Flow

1. `node-exporter` exposes host metrics
2. `cAdvisor` exposes container metrics
3. `Prometheus` scrapes both exporters and its own endpoint
4. `Grafana` queries Prometheus to build dashboards
5. `Caddy` exposes the UIs securely over HTTPS

## File Layout

- `docker-compose.yml` - container definitions, volumes, and network wiring
- `Caddyfile` - public domains, security headers, and reverse proxy rules
- `prometheus.yml` - Prometheus scrape jobs and global labels
- `alerts/monitoring.rules.yml` - Prometheus alerting rules
- `grafana/provisioning` - provisioned data sources and dashboard providers
- `grafana/dashboards` - versioned Grafana dashboards
- `scripts/backup.sh` - scheduled backup script for persistent volumes

## 🔒 Security

**⚠️ CRITICAL: Review complete security guidelines in [SECURITY.md](SECURITY.md)**

### Current Security Status
| Component | Authentication | Encryption | Hardening | Status |
|-----------|---------------|------------|-----------|--------|
| Grafana | ✅ Environment Variables | ✅ HTTPS | 🟡 Basic | 🟢 Secure |
| Prometheus | ✅ Basic Auth | ✅ HTTPS | 🟡 Basic | 🟢 Secure |
| cAdvisor | ✅ Basic Auth | ✅ HTTPS | 🟡 Basic | 🟢 Secure |
| Backups | 🔲 Configurable | 🔲 GPG | 🟡 Local | 🟡 Optional |

### Before Deployment
- [ ] Run `./scripts/setup-auth.sh` to generate secure credentials
- [ ] Review [SECURITY.md](SECURITY.md) for complete security checklist
- [ ] Configure firewall rules (allow only 80/443)
- [ ] Test authentication for all endpoints
- [ ] Set up backup encryption with GPG
- [ ] Configure security alerts in Prometheus

### Security Features
- ✅ Automatic HTTPS with Caddy
- ✅ Security headers (HSTS, CSP, X-Frame-Options, etc.)
- ✅ Basic authentication for sensitive endpoints
- ✅ Network isolation via Docker bridge network
- ✅ Read-only volume mounts where applicable
- ✅ Automated backup system

## Backup Strategy

The `backup` service creates compressed archives of:

- `grafana-data`
- `prometheus-data`

Backups are written to the local `backups/` directory on the host.

Environment variables:

- `BACKUP_INTERVAL_SECONDS` - how often backups run, default `86400`
- `BACKUP_RETENTION_DAYS` - how long to keep backup archives, default `7`

Backup output layout:

- `backups/grafana/`
- `backups/prometheus/`

Example restore flow:

```bash
docker compose down
tar -xzf backups/grafana/<archive>.tar.gz -C /tmp/grafana-restore
tar -xzf backups/prometheus/<archive>.tar.gz -C /tmp/prometheus-restore
```

Then copy the restored data back into the corresponding Docker volumes before starting the stack again.

## Extend the Stack

To add another monitored service:

1. Add the service to `docker-compose.yml`
2. Ensure it joins the `monitoring` network
3. Add a new scrape job to `prometheus.yml`
4. Recreate the stack

Example Prometheus job:

```yaml
- job_name: my-service
  static_configs:
    - targets:
        - my-service:8080
      labels:
        service: my-service
```

If you also want public access for that service, add a new site block in `Caddyfile`.

## Troubleshooting

### Common Issues

**Service won't start:**
```bash
# Check logs
docker compose logs -f <service>

# Check resource availability
docker system df

# Check port conflicts
netstat -tulpn | grep -E ':(80|443|3000|9090)'
```

**Authentication failures:**
```bash
# Verify .env file exists
cat .env

# Regenerate credentials
./scripts/setup-auth.sh

# Test basic auth manually
curl -u prometheus-admin:password https://prometheus.luam.us.kg
```

**High memory usage:**
```bash
# Check container stats
docker stats

# Restart Prometheus
docker compose restart prometheus

# Adjust retention in prometheus.yml
```

**Backup failures:**
```bash
# Check backup logs
docker compose logs -f backup

# Verify backup directory
ls -lh backups/

# Test backup manually
docker exec backup /bin/sh -c "tar -czf /tmp/test.tar.gz -C /source/grafana ."
```

### Health Checks

```bash
# Check service status
docker compose ps

# Verify all endpoints
curl -I https://grafana.luam.us.kg
curl -I https://prometheus.luam.us.kg
curl -I https://cadvisor.luam.us.kg

# Test Prometheus targets
curl -u prometheus-admin:password https://prometheus.luam.us.kg/api/v1/targets

# Check Grafana datasources
curl -u admin:password https://grafana.luam.us.kg/api/datasources
```

## 📚 Additional Documentation

- [SECURITY.md](SECURITY.md) - Complete security guidelines and hardening procedures
- [OPERATIONS.md](OPERATIONS.md) - Deployment, maintenance, and disaster recovery procedures
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Detailed troubleshooting guide
- [API.md](docs/API.md) - API endpoints and integration examples

## Next Improvements

- Add Alertmanager integration for notifications
- Add more Grafana dashboards for containers, host metrics, and disk I/O
- Push backups to object storage or another off-site location
- Add IP allowlists or SSO in front of protected endpoints
