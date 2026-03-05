---
name: security-hardening
description: Use when hardening servers or cloud environments. Covers CIS benchmark implementation, OS-level hardening (SSH, firewall, fail2ban), cloud security posture, audit logging, compliance checks, and vulnerability scanning workflows.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Security Hardening

## SSH Hardening
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
AllowUsers deploy admin
Protocol 2
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```

## Firewall (iptables/nftables)
```bash
# UFW setup
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw enable
```

## OS Hardening Checklist
- [ ] Disable root login
- [ ] SSH key-only authentication
- [ ] Automatic security updates (`unattended-upgrades`)
- [ ] Remove unnecessary packages and services
- [ ] Configure fail2ban for brute force protection
- [ ] Set up audit logging (auditd)
- [ ] Restrict cron access
- [ ] Set proper file permissions
- [ ] Configure log rotation
- [ ] Enable and configure AppArmor/SELinux

## Best Practices
1. **Patch regularly** — Enable auto security updates
2. **Minimal attack surface** — Remove unneeded packages/services
3. **Audit logging** — Log all privileged actions
4. **Network segmentation** — Isolate by function and sensitivity
5. **MFA everywhere** — SSH, cloud console, VPN access
6. **Vulnerability scanning** — Regular scans with OpenVAS, Nessus, or Qualys
7. **Compliance checks** — CIS benchmark scanning with tools like Lynis
8. **Incident response** — Documented and tested IR procedures
