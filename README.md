# Monitoring Stack

Lightweight self-hosted monitoring stack with `Caddy`, `Prometheus`, `Grafana`, `cAdvisor`, and `node-exporter` running on Docker Compose.

Only `80` and `443` are exposed on the host. `Caddy` terminates TLS, applies shared security headers, and proxies each public domain to an internal service.

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
- `prometheus.luam.us.kg` -> Prometheus UI and targets page
- `cadvisor.luam.us.kg` -> cAdvisor container metrics UI

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
```

3. Recreate the stack:

```bash
docker compose up -d --force-recreate
```

Notes:

- Do not commit `.env`
- Change the default password before exposing Grafana publicly
- `Prometheus` and `cAdvisor` do not have authentication enabled in this setup yet

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

## Security Notes

- Only `80` and `443` are exposed to the host
- Internal services are reachable only through the Docker network
- Shared security headers are applied by `Caddy`
- Compression is enabled with `zstd` and `gzip`
- Grafana admin credentials are loaded from `.env`
- The fallback password in `docker-compose.yml` is only a bootstrap default and should be replaced immediately

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

- If HTTPS is not issued, verify DNS and confirm ports `80` and `443` are open
- If a target is down, check `prometheus.luam.us.kg/targets`
- If Grafana does not load, inspect `docker compose logs -f grafana`
- If proxying fails, inspect `docker compose logs -f caddy`
- If host metrics are missing, confirm `node-exporter` has access to `/proc`, `/sys`, and `/`

## Next Improvements

- Add Grafana provisioning for data sources and dashboards
- Add alerting rules for Prometheus
- Add persistent backup strategy for Grafana and Prometheus volumes
- Add authentication hardening in front of Prometheus and cAdvisor if they should not be public
