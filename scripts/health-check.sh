#!/bin/bash

# Health Check Script for Monitoring Stack
# This script verifies all services are running and accessible

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
GRAFANA_URL="${GRAFANA_URL:-https://grafana.luam.us.kg}"
PROMETHEUS_URL="${PROMETHEUS_URL:-https://prometheus.luam.us.kg}"
CADVISOR_URL="${CADVISOR_URL:-https://cadvisor.luam.us.kg}"

# Counters
PASS=0
FAIL=0
WARN=0

# Functions
log_pass() {
    echo -e "${GREEN}✓ PASS${NC} $1"
    ((PASS++))
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC} $1"
    ((FAIL++))
}

log_warn() {
    echo -e "${YELLOW}⚠ WARN${NC} $1"
    ((WARN++))
}

log_info() {
    echo -e "${BLUE}ℹ INFO${NC} $1"
}

check_docker() {
    echo -e "\n${BLUE}=== Docker Environment ===${NC}"

    # Check if Docker is running
    if docker info &> /dev/null; then
        log_pass "Docker daemon is running"
    else
        log_fail "Docker daemon is not running"
        return 1
    fi

    # Check Docker Compose
    if command -v docker compose &> /dev/null; then
        log_pass "Docker Compose is available"
    else
        log_fail "Docker Compose is not available"
        return 1
    fi
}

check_services() {
    echo -e "\n${BLUE}=== Service Status ===${NC}"

    # Check if services are running
    if docker compose -f "$COMPOSE_FILE" ps &> /dev/null; then
        log_pass "Docker Compose services defined"
    else
        log_fail "Docker Compose services not properly defined"
        return 1
    fi

    # Check individual services
    local services=("caddy" "grafana" "prometheus" "cadvisor" "node-exporter" "backup")
    for service in "${services[@]}"; do
        if docker compose -f "$COMPOSE_FILE" ps -q "$service" &> /dev/null; then
            if docker compose -f "$COMPOSE_FILE" ps -q "$service" | xargs docker inspect &> /dev/null; then
                local status=$(docker compose -f "$COMPOSE_FILE" ps -q "$service" | xargs docker inspect --format='{{.State.Status}}')
                if [ "$status" = "running" ]; then
                    log_pass "Service $service is running"
                else
                    log_fail "Service $service is not running (status: $status)"
                fi
            else
                log_fail "Service $service container not found"
            fi
        else
            log_fail "Service $service not defined in compose file"
        fi
    done
}

check_volumes() {
    echo -e "\n${BLUE}=== Docker Volumes ===${NC}"

    local volumes=("grafana-data" "prometheus-data" "caddy-data" "caddy-config")
    for volume in "${volumes[@]}"; do
        if docker volume ls -q | grep -q "^${volume}\$"; then
            log_pass "Volume $volume exists"
        else
            log_warn "Volume $volume does not exist (will be created on first start)"
        fi
    done
}

check_network() {
    echo -e "\n${BLUE}=== Network Configuration ===${NC}"

    if docker network ls -q | grep -q "monitoring"; then
        log_pass "Docker network 'monitoring' exists"
    else
        log_fail "Docker network 'monitoring' not found"
    fi
}

check_configuration_files() {
    echo -e "\n${BLUE}=== Configuration Files ===${NC}"

    local files=(
        "docker-compose.yml"
        "Caddyfile"
        "prometheus.yml"
        ".env"
        "alerts/monitoring.rules.yml"
        "grafana/provisioning/datasources/prometheus.yml"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "Configuration file exists: $file"
        else
            log_fail "Configuration file missing: $file"
        fi
    done
}

check_endpoints() {
    echo -e "\n${BLUE}=== HTTP Endpoints ===${NC}"

    # Load credentials from .env if available
    if [ -f ".env" ]; then
        source .env
    fi

    # Check Grafana
    if curl -f -s -o /dev/null "$GRAFANA_URL"; then
        log_pass "Grafana endpoint is accessible"
    else
        log_fail "Grafana endpoint is not accessible"
    fi

    # Check Prometheus (without auth for basic connectivity)
    if curl -f -s -o /dev/null "$PROMETHEUS_URL"; then
        log_pass "Prometheus endpoint is accessible"
    else
        log_fail "Prometheus endpoint is not accessible"
    fi

    # Check cAdvisor
    if curl -f -s -o /dev/null "$CADVISOR_URL"; then
        log_pass "cAdvisor endpoint is accessible"
    else
        log_fail "cAdvisor endpoint is not accessible"
    fi
}

check_prometheus_targets() {
    echo -e "\n${BLUE}=== Prometheus Targets ===${NC}"

    # Load credentials
    if [ -f ".env" ]; then
        source .env
        PROM_USER="${PROMETHEUS_BASIC_AUTH_USER:-prometheus-admin}"
        PROM_PASS="${PROMETHEUS_BASIC_AUTH_PASSWORD:-}"

        if [ -n "$PROM_USER" ] && [ -n "$PROM_PASS" ]; then
            local targets=$(curl -s -u "$PROM_USER:$PROM_PASS" "$PROMETHEUS_URL/api/v1/targets" 2>/dev/null)

            if [ $? -eq 0 ]; then
                local up_count=$(echo "$targets" | jq -r '.data.activeTargets[] | select(.health=="up") | .job' | wc -l)
                local total_count=$(echo "$targets" | jq -r '.data.activeTargets[] | .job' | wc -l)

                log_pass "Prometheus targets: $up_count/$total_count up"

                # List each target
                echo "$targets" | jq -r '.data.activeTargets[] | "\(.job): \(.health)"' | while read -r line; do
                    if echo "$line" | grep -q "up"; then
                        log_pass "  $line"
                    else
                        log_fail "  $line"
                    fi
                done
            else
                log_fail "Failed to query Prometheus targets (authentication may be required)"
            fi
        else
            log_warn "Prometheus credentials not configured, skipping target check"
        fi
    else
        log_warn ".env file not found, skipping Prometheus target check"
    fi
}

check_disk_space() {
    echo -e "\n${BLUE}=== Disk Space ===${NC}"

    local df_output=$(df -h / | tail -1)
    local usage_percent=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')

    if [ "$usage_percent" -lt 80 ]; then
        log_pass "Disk usage: ${usage_percent}% (healthy)"
    elif [ "$usage_percent" -lt 90 ]; then
        log_warn "Disk usage: ${usage_percent}% (warning)"
    else
        log_fail "Disk usage: ${usage_percent}% (critical)"
    fi

    # Check backup directory
    if [ -d "backups" ]; then
        local backup_size=$(du -sh backups 2>/dev/null | awk '{print $1}')
        log_info "Backup directory size: $backup_size"
    fi
}

check_memory() {
    echo -e "\n${BLUE}=== Memory Usage ===${NC}"

    local mem_percent=$(free | awk '/Mem/{printf("%.0f"), ($3/$2)*100}')

    if [ "$mem_percent" -lt 80 ]; then
        log_pass "Memory usage: ${mem_percent}%"
    elif [ "$mem_percent" -lt 90 ]; then
        log_warn "Memory usage: ${mem_percent}%"
    else
        log_fail "Memory usage: ${mem_percent}%"
    fi
}

print_summary() {
    echo -e "\n${BLUE}=== Health Check Summary ===${NC}"
    echo -e "${GREEN}Passed: $PASS${NC}"
    echo -e "${YELLOW}Warnings: $WARN${NC}"
    echo -e "${RED}Failed: $FAIL${NC}"
    echo ""

    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}✓ All critical checks passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some checks failed. Please review the output above.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Monitoring Stack Health Check${NC}"
    echo -e "${BLUE}================================${NC}"

    check_docker || exit 1
    check_configuration_files || exit 1
    check_services
    check_volumes
    check_network
    check_endpoints
    check_prometheus_targets
    check_disk_space
    check_memory

    print_summary
}

# Run main function
main "$@"