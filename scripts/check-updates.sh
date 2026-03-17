#!/bin/bash

# Update Check Script for Monitoring Stack
# Checks for available updates and provides update recommendations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ INFO${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠ WARN${NC} $1"
}

log_error() {
    echo -e "${RED}✗ ERROR${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓ SUCCESS${NC} $1"
}

check_docker_updates() {
    echo -e "\n${BLUE}=== Checking Docker Image Updates ===${NC}"

    local images=(
        "caddy:latest"
        "grafana/grafana:latest"
        "prom/prometheus:latest"
        "gcr.io/cadvisor/cadvisor:latest"
        "prom/node-exporter:latest"
        "alpine:3.20"
    )

    local updates_available=0

    for image in "${images[@]}"; do
        log_info "Checking $image..."

        # Pull latest manifest
        if docker pull "$image" --quiet >/dev/null 2>&1; then
            # Get current image ID
            local current_id=$(docker images "$image" --format "{{.ID}}" | head -1)

            # Get latest image ID
            local latest_id=$(docker images "$image" --format "{{.ID}}" | head -1)

            if [ "$current_id" != "$latest_id" ]; then
                log_warn "Update available for $image"
                ((updates_available++))
            else
                log_success "$image is up to date"
            fi
        else
            log_error "Failed to check $image"
        fi
    done

    if [ $updates_available -eq 0 ]; then
        log_success "All images are up to date!"
    else
        log_warn "$updates_available image(s) have updates available"
    fi
}

check_security_vulnerabilities() {
    echo -e "\n${BLUE}=== Checking Security Vulnerabilities ===${NC}"

    if command -v docker scan &> /dev/null; then
        log_info "Scanning for security vulnerabilities..."

        local images=(
            "caddy:latest"
            "grafana/grafana:latest"
            "prom/prometheus:latest"
            "gcr.io/cadvisor/cadvisor:latest"
            "prom/node-exporter:latest"
        )

        for image in "${images[@]}"; do
            log_info "Scanning $image..."
            docker scan "$image" --format "{{.Database}}: {{.Vulnerabilities}}" || log_warn "Scan failed for $image"
        done
    else
        log_warn "Docker scan not available. Install with: docker scan"
    fi
}

check_system_updates() {
    echo -e "\n${BLUE}=== Checking System Updates ===${NC}"

    # Check Docker version
    local docker_version=$(docker version --format '{{.Server.Version}}')
    log_info "Docker version: $docker_version"

    # Check Docker Compose version
    local compose_version=$(docker compose version --short)
    log_info "Docker Compose version: $compose_version"

    # Check for system updates (Linux)
    if [ -f /etc/debian_version ]; then
        log_info "Checking Debian/Ubuntu system updates..."
        if command -v apt-get &> /dev/null; then
            apt-get update --quiet >/dev/null 2>&1
            local updates=$(apt-get upgrade -s | grep -c '^Inst')
            if [ "$updates" -gt 0 ]; then
                log_warn "$updates system updates available"
            else
                log_success "System is up to date"
            fi
        fi
    fi
}

check_configuration_changes() {
    echo -e "\n${BLUE}=== Checking Configuration Changes ===${NC}"

    local configs=(
        "docker-compose.yml"
        "Caddyfile"
        "prometheus.yml"
        ".env.example"
        "alerts/monitoring.rules.yml"
    )

    for config in "${configs[@]}"; do
        if [ -f "$config" ]; then
            local mtime=$(stat -c %y "$config" 2>/dev/null || stat -f %Sm "$config" 2>/dev/null)
            local days_ago=$(( ( $(date +%s) - $(date -d "$mtime" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$mtime" +%s) ) / 86400 ))

            if [ "$days_ago" -gt 30 ]; then
                log_warn "$config not modified in $days_ago days"
            else
                log_success "$config recently updated"
            fi
        else
            log_error "$config not found"
        fi
    done
}

generate_update_recommendations() {
    echo -e "\n${BLUE}=== Update Recommendations ===${NC}"

    echo -e "\n${YELLOW}Recommended Actions:${NC}"

    # Check if backups are recent
    if [ -d "backups" ]; then
        local latest_backup=$(find backups -type f -mtime -1 | wc -l)
        if [ "$latest_backup" -eq 0 ]; then
            echo "⚠️  No recent backups found. Consider creating backup before updates."
        else
            echo "✓ Recent backups found."
        fi
    else
        echo "⚠️  No backup directory found. Setup backups before updating."
    fi

    # Check if health check passes
    if [ -f "scripts/health-check.sh" ]; then
        echo "📋 Run './scripts/health-check.sh' before and after updates."
    fi

    # Check security documentation
    if [ -f "SECURITY.md" ]; then
        echo "📚 Review SECURITY.md before applying updates."
    fi

    # Check for rollback plan
    echo "🔄 Ensure rollback plan is ready before major updates."

    echo -e "\n${GREEN}Update Commands:${NC}"
    echo "  Minor updates: docker compose pull && docker compose up -d"
    echo "  Major updates: See UPDATES.md for detailed procedures"
}

print_summary() {
    echo -e "\n${BLUE}=== Update Check Summary ===${NC}"
    echo "Review recommendations above and plan updates accordingly."
    echo "For detailed update procedures, see UPDATES.md"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}Monitoring Stack Update Check${NC}"
    echo -e "${BLUE}================================${NC}"

    check_docker_updates
    check_security_vulnerabilities
    check_system_updates
    check_configuration_changes
    generate_update_recommendations
    print_summary
}

# Run main function
main "$@"