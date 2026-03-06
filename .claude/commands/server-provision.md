---
name: server-provision
description: Provision and configure servers with security hardening
argument-hint: "[server type or provider]"
disable-model-invocation: true
---

# /server-provision — Server Provisioning

Provision server for $ARGUMENTS using the **infra-planner** agent with the **security-hardening** skill:

1. Provision server (cloud provider or bare metal)
2. Apply security hardening (SSH, firewall, fail2ban)
3. Install required software stack
4. Configure monitoring agent
5. Set up automated backups
6. Document access and credentials

## Usage
```
/server-provision "Ubuntu 22.04 on AWS with Nginx + PHP"
/server-provision "DigitalOcean droplet for PostgreSQL"
```
