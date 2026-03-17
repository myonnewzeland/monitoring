# Security Guide

**⚠️ CRITICAL: Review and implement all security measures before production deployment.**

## 🚨 Critical Security Issues

### 1. Credential Management

**Status**: ⚠️ **REQUIRES IMMEDIATE ATTENTION**

**Problems:**
- Default passwords exposed in `.env.example`
- No credential rotation policy
- Bcrypt hashes visible in version control

**Solutions:**
```bash
# Generate secure passwords
openssl rand -base64 32

# Generate bcrypt hashes
htpasswd -nbB user "password"
```

**Implementation:**
1. Run `./scripts/setup-auth.sh` to generate credentials
2. Implement quarterly credential rotation
3. Never commit `.env` to version control

### 2. Prometheus Security

**Status**: 🔴 **HIGH PRIORITY**

**Problems:**
- `--web.enable-lifecycle` removed (✅ FIXED)
- No additional API authentication
- Administrative functions exposed

**Current Status:**
```yaml
# REMOVED: --web.enable-lifecycle
# ADDED: Security options
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
read_only: true
```

### 3. Container Hardening

**Status**: ✅ **IMPLEMENTED**

**Applied Hardening:**
```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
cap_add:
  - CHOWN, SETGID, SETUID (selective)
read_only: true
tmpfs:
  - /tmp
```

### 4. Rate Limiting

**Status**: ✅ **IMPLEMENTED**

**Configuration:**
```caddyfile
rate_limit {
    zone common_limits {
        key {remote_host}
        events 100
        window 1m
    }
}
```

### 5. Backup Encryption

**Status**: ✅ **AVAILABLE**

**Implementation:**
```bash
# Enable encryption in .env
BACKUP_ENCRYPT=true
BACKUP_GPG_RECIPIENT=your@email.com
```

---

## 🔒 Security Checklist

### Pre-Deployment
- [ ] Generate unique strong passwords
- [ ] Replace all bcrypt hashes in `.env`
- [ ] Configure HTTPS with valid certificates
- [ ] Enable security headers in Caddy
- [ ] Test authentication for all endpoints
- [ ] Implement rate limiting
- [ ] Configure security alerts

### Post-Deployment
- [ ] Implement log aggregation
- [ ] Configure security alerts
- [ ] Test backup restoration
- [ ] Document credential rotation
- [ ] Implement intrusion detection
- [ ] Configure security monitoring

### Maintenance
- [ ] Quarterly credential rotation
- [ ] Monthly security updates
- [ ] Weekly backup verification
- [ ] Annual security audit

---

## 🛡️ Network Security

### Firewall Configuration
```bash
# Allow only HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### Docker Network Security
```yaml
networks:
  monitoring:
    driver: bridge
    internal: false
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

---

## 📊 Security Monitoring

### Prometheus Security Alerts

**Security Rules:**
- Excessive failed authentication attempts
- Unauthorized access attempts
- Container restart anomalies
- Disk space exhaustion (DoS)
- Unusual network activity

**Alert Configuration:** See `alerts/security.rules.yml`

---

## 🔄 Incident Response

### Security Incident Checklist

1. **Identify**: Check logs for suspicious activity
2. **Contain**: Isolate affected services
3. **Eradicate**: Remove threats, patch vulnerabilities
4. **Recover**: Restore from clean backups
5. **Lessons Learned**: Document and improve procedures

### Emergency Contacts

- Security Team: [EMAIL]
- Infrastructure Lead: [EMAIL]
- On-Call Engineer: [PHONE]

---

## 📚 Additional Resources

- [Caddy Security](https://caddyserver.com/docs/security)
- [Prometheus Security](https://prometheus.io/docs/operating/security/)
- [Grafana Security](https://grafana.com/docs/grafana/latest/security/)
- [Docker Security](https://docs.docker.com/engine/security/)

---

**Last Updated**: 2026-03-17
**Next Review**: 2026-06-17