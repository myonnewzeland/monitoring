#!/bin/bash
set -euo pipefail

# Authentication Setup Script for Monitoring Stack
# This script generates secure credentials for all services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to generate bcrypt hash
generate_bcrypt_hash() {
    local password=$1
    # Using python with bcrypt library
    python3 -c "import bcrypt; print(bcrypt.hashpw('$password'.encode(), bcrypt.gensalt()).decode())"
}

# Check if required tools are available
check_requirements() {
    log_info "Checking requirements..."

    if ! command -v openssl &> /dev/null; then
        log_error "openssl is required but not installed"
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        log_error "python3 is required but not installed"
        exit 1
    fi

    if ! python3 -c "import bcrypt" 2>/dev/null; then
        log_warn "bcrypt python module not found. Installing..."
        pip3 install bcrypt
    fi

    log_info "All requirements met"
}

# Generate credentials
generate_credentials() {
    log_info "Generating secure credentials..."

    # Grafana credentials
    GRAFANA_ADMIN_USER="admin"
    GRAFANA_ADMIN_PASSWORD=$(generate_password 32)
    log_info "✓ Generated Grafana admin password"

    # Prometheus credentials
    PROMETHEUS_BASIC_AUTH_USER="prometheus-admin"
    PROMETHEUS_PASSWORD=$(generate_password 32)
    PROMETHEUS_BASIC_AUTH_HASH=$(generate_bcrypt_hash "$PROMETHEUS_PASSWORD")
    log_info "✓ Generated Prometheus credentials"

    # cAdvisor credentials
    CADVISOR_BASIC_AUTH_USER="cadvisor-admin"
    CADVISOR_PASSWORD=$(generate_password 32)
    CADVISOR_BASIC_AUTH_HASH=$(generate_bcrypt_hash "$CADVISOR_PASSWORD")
    log_info "✓ Generated cAdvisor credentials"
}

# Save credentials to .env file
save_credentials() {
    log_info "Saving credentials to .env file..."

    cat > "$PROJECT_ROOT/.env" << EOF
# Grafana Credentials
GRAFANA_ADMIN_USER=$GRAFANA_ADMIN_USER
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD

# Prometheus Credentials
PROMETHEUS_BASIC_AUTH_USER=$PROMETHEUS_BASIC_AUTH_USER
PROMETHEUS_BASIC_AUTH_HASH=$PROMETHEUS_BASIC_AUTH_HASH

# cAdvisor Credentials
CADVISOR_BASIC_AUTH_USER=$CADVISOR_BASIC_AUTH_USER
CADVISOR_BASIC_AUTH_HASH=$CADVISOR_BASIC_AUTH_HASH

# Backup Configuration
BACKUP_INTERVAL_SECONDS=86400
BACKUP_RETENTION_DAYS=7

# Backup Encryption (optional)
# BACKUP_GPG_RECIPIENT=your-email@example.com
EOF

    log_info "✓ Credentials saved to $PROJECT_ROOT/.env"
}

# Save credentials to secure file
save_secure_backup() {
    local backup_file="$PROJECT_ROOT/credentials-backup-$(date +%Y%m%d-%H%M%S).txt"
    log_info "Creating credential backup..."

    cat > "$backup_file" << EOF
# Monitoring Stack Credentials - $(date)
# KEEP THIS FILE SECURE! Delete after storing in password manager.

GRAFANA_USERNAME: $GRAFANA_ADMIN_USER
GRAFANA_PASSWORD: $GRAFANA_ADMIN_PASSWORD
GRAFANA_URL: https://grafana.luam.us.kg

PROMETHEUS_USERNAME: $PROMETHEUS_BASIC_AUTH_USER
PROMETHEUS_PASSWORD: $PROMETHEUS_PASSWORD
PROMETHEUS_URL: https://prometheus.luam.us.kg

CADVISOR_USERNAME: $CADVISOR_BASIC_AUTH_USER
CADVISOR_PASSWORD: $CADVISOR_PASSWORD
CADVISOR_URL: https://cadvisor.luam.us.kg

Generated: $(date)
EOF

    chmod 600 "$backup_file"
    log_info "✓ Credential backup saved to $backup_file"
    log_warn "Store these credentials securely and delete this file after!"
}

# Update .env.example with placeholders
update_example_file() {
    log_info "Updating .env.example with placeholders..."

    cat > "$PROJECT_ROOT/.env.example" << EOF
# Grafana Credentials
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=REPLACE_WITH_SECURE_PASSWORD

# Prometheus Credentials
PROMETHEUS_BASIC_AUTH_USER=prometheus-admin
PROMETHEUS_BASIC_AUTH_HASH=REPLACE_WITH_BCRYPT_HASH

# cAdvisor Credentials
CADVISOR_BASIC_AUTH_USER=cadvisor-admin
CADVISOR_BASIC_AUTH_HASH=REPLACE_WITH_BCRYPT_HASH

# Backup Configuration
BACKUP_INTERVAL_SECONDS=86400
BACKUP_RETENTION_DAYS=7

# Backup Encryption (optional)
# BACKUP_GPG_RECIPIENT=your-email@example.com

# Generate credentials using: ./scripts/setup-auth.sh
EOF

    log_info "✓ .env.example updated"
}

# Display summary
display_summary() {
    log_info "==================================="
    log_info "  Credential Generation Complete"
    log_info "==================================="
    echo ""
    log_info "Generated credentials:"
    echo "  • Grafana: $GRAFANA_ADMIN_USER"
    echo "  • Prometheus: $PROMETHEUS_BASIC_AUTH_USER"
    echo "  • cAdvisor: $CADVISOR_BASIC_AUTH_USER"
    echo ""
    log_warn "IMPORTANT SECURITY NOTES:"
    echo "  1. Store the credential backup file securely"
    echo "  2. Add credentials to your password manager"
    echo "  3. Delete the backup file after storing"
    echo "  4. Never commit .env to version control"
    echo "  5. Rotate credentials quarterly"
    echo ""
    log_info "Next steps:"
    echo "  1. Review generated credentials in: $backup_file"
    echo "  2. Start services: docker compose up -d"
    echo "  3. Test authentication for all services"
    echo "  4. Configure backup encryption if needed"
    echo ""
}

# Main execution
main() {
    log_info "Starting authentication setup..."

    check_requirements
    generate_credentials
    save_credentials
    save_secure_backup
    update_example_file
    display_summary

    log_info "Setup complete! 🎉"
}

# Run main function
main "$@"