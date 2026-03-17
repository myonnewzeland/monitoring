# Contributing to Enterprise Monitoring Stack

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

---

## 🤝 How to Contribute

### Reporting Bugs

**Before creating bug reports:**
- Search existing issues
- Verify bug still exists in latest version
- Check if security issue (don't post publicly)

**Bug Report Template:**
```yaml
Title: [Bug] Brief description
Version: Version where bug occurs
Environment:
  - OS: [e.g., Ubuntu 22.04]
  - Docker: [version]
  - Browser: [if applicable]

Steps to Reproduce:
1. Step one
2. Step two
3. Expected behavior
4. Actual behavior

Relevant Logs:
[paste logs here]

Screenshots:
[if applicable]
```

### Suggesting Enhancements

**Enhancement Proposal Template:**
```yaml
Title: [Feature] Brief description
Problem: What problem does this solve?
Proposed Solution: How should it work?
Alternatives: What other approaches considered?
Benefits: Value and impact
```

---

## 🛠️ Development Setup

### Prerequisites

- Docker Engine 24.0+
- Docker Compose Plugin 2.20+
- Make (build tool)
- Git 2.30+

### Getting Started

```bash
# 1. Fork and clone
git clone https://github.com/yourusername/monitoring-stack.git
cd monitoring-stack

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes
# Edit files, add features, etc.

# 4. Test changes
./scripts/health-check.sh

# 5. Commit changes
git commit -m "Add my feature"

# 6. Push branch
git push origin feature/my-feature
```

---

## 📝 Code Standards

### Configuration Files

**Docker Compose:**
- Use 2-space indentation
- Long lines broken at 80 characters
- Comments for complex configurations
- Environment variables for secrets

**Caddyfile:**
- Follow Caddyfile best practices
- Group related directives
- Use snippets for common patterns
- Comment complex routing logic

**Shell Scripts:**
- Use ShellCheck for validation
- Set `set -euo pipefail`
- Add error handling
- Document with comments

### Documentation

**Markdown Standards:**
- Use proper markdown formatting
- Add table of contents for long docs
- Include code examples with syntax highlighting
- Add diagrams for architecture

**Comments:**
- Explain WHY, not just WHAT
- Keep comments up-to-date
- Use English for international audience

---

## 🧪 Testing

### Pre-Commit Checklist

- [ ] Code follows style guidelines
- [ ] All scripts are executable (`chmod +x`)
- [ ] Configuration files validated
- [ ] Documentation updated
- [ ] Tests pass (`./scripts/health-check.sh`)

### Testing Procedures

```bash
# Validate configurations
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Test health
./scripts/health-check.sh

# Test backup system
docker compose run --rm backup
```

---

## 📥 Pull Request Process

### Before Submitting

1. **Search existing PRs**: Avoid duplicate work
2. **Update documentation**: Include relevant docs
3. **Test thoroughly**: Ensure nothing breaks
4. **Keep it focused**: One PR per feature/fix
5. **Follow conventions**: Match existing code style

### PR Template

```yaml
## Description
[Brief description of changes]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested locally
- [ ] Added tests (if applicable)
- [ ] Updated documentation

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review performed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Adds tests for bug fixes
- [ ] Documentation updated
```

---

## 🎯 Priority Areas

### High Priority Contributions
1. **Security improvements**: Hardening, encryption
2. **Documentation**: Enhancing guides, fixing errors
3. **Automation**: Scripts for operational tasks
4. **Testing**: Test coverage, validation tools

### Medium Priority Contributions
1. **Dashboards**: Grafana dashboard templates
2. **Alert rules**: Additional monitoring alerts
3. **Integrations**: Third-party service integrations
4. **Performance**: Optimization improvements

### Low Priority Contributions
1. **Cosmetic**: Minor styling changes
2. **Opinionated**: Architectural preferences
3. **Experimental**: Cutting-edge features

---

## 🏆 Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes for significant contributions
- Project website (when available)

---

## 📜 Project Standards

### Code of Conduct

**Be Respectful:**
- Use inclusive language
- Accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

**Be Collaborative:**
- Welcome newcomers and help them get started
- Actively seek diverse perspectives
- Listen effectively and disagree respectfully

**Be Professional:**
- Accept responsibility and apologize to those affected
- Focus on what is best for the community
- Build trust through reliability and consistency

### Licensing

All contributions are licensed under the MIT License. See LICENSE file for details.

---

## 🚀 Release Process

### Version Management

- Follow Semantic Versioning: `MAJOR.MINOR.PATCH`
- Document breaking changes
- Maintain CHANGELOG.md

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] Security review complete
- [ ] Performance validated
- [ ] Breaking changes documented
- [ ] Release notes prepared

---

## 💬 Getting Help

### Communication Channels

- **Issues**: GitHub Issues for bugs and features
- **Discussions**: GitHub Discussions for questions
- **Security**: Private issues for security reports

### Resources

- [Documentation](docs/)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)
- [Troubleshooting](OPERATIONS.md#troubleshooting)

---

## 🎓 Learning Resources

### Recommended Reading

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Administration](https://grafana.com/docs/grafana/latest/administration/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Caddy Security](https://caddyserver.com/docs/security)

---

## ⭐ Becoming a Maintainer

After consistent, high-quality contributions, you may be invited to become a project maintainer with:

- Write access to repository
- Merge permissions for PRs
- Release management responsibilities
- Project direction influence

---

**Thank you for contributing!** 🙏

Your contributions make this monitoring stack better for everyone.

---

*For questions about contributing, open an issue or discussion.*