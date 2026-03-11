---
name: ansible-operations
description: Project-specific Ansible operations template — customize with your inventory, playbook catalog, deployment workflows, and host group details
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# Ansible Operations — Project Configuration

Customize this skill with your infrastructure details. The ansible-agent reads this before every task.

## Project Location

```bash
Path: /path/to/your/ansible-project
Config: ansible.cfg
```

## Inventory

### Host Groups

**web_servers** — Web/application servers

- User: `deploy`
- SSH key: `~/.ssh/deploy_key.pem`
- Hosts: web01, web02, web03

**db_servers** — Database servers

- User: `deploy`
- SSH key: `~/.ssh/deploy_key.pem`
- Hosts: db01, db02

**app_servers** — Application servers

- User: `ubuntu`
- SSH key: `~/.ssh/app_key.pem`
- Hosts: app01.example.com, app02.example.com

## Playbook Catalog

### Diagnostics

| Playbook | Target | Purpose |
|----------|--------|---------|
| `playbooks/ping_all.yml` | all | Test SSH connectivity |
| `playbooks/disk_usage.yml` | all | Check disk space |

### Deployments

| Playbook | Target | Purpose |
|----------|--------|---------|
| `playbooks/deploy_app.yml` | app_servers | Deploy application |
| `playbooks/deploy_all.yml` | all | Full deployment |

### Installations

| Playbook | Target | Purpose |
|----------|--------|---------|
| `playbooks/install_nginx.yml` | web_servers | Install Nginx |
| `playbooks/install_redis.yml` | `--extra-vars` | Install Redis |

### Administration

| Playbook | Target | Purpose |
|----------|--------|---------|
| `playbooks/update_credentials.yml` | all | Rotate credentials |
| `playbooks/backup_db.yml` | db_servers | Database backup |

## Deployment Workflows

### Application Deploy

```bash
# 1. Pre-check
ansible-playbook playbooks/ping_all.yml --limit app_servers

# 2. Deploy
ansible-playbook playbooks/deploy_app.yml

# 3. Verify
ansible-playbook playbooks/health_check.yml --limit app_servers
```

## Common Patterns

### Running Against Specific Hosts

```bash
# Single host
ansible-playbook playbooks/deploy_app.yml --limit app01.example.com

# Group
ansible-playbook playbooks/deploy_app.yml --limit app_servers

# Multiple hosts
ansible-playbook playbooks/deploy_app.yml --limit "app01.example.com,app02.example.com"
```

### Dry Run

```bash
ansible-playbook playbooks/deploy_app.yml --check
```

### Ad-hoc Commands

```bash
# Check uptime
ansible web_servers -m command -a "uptime"

# Restart a service
ansible app_servers -m systemd -a "name=nginx state=restarted" --become
```

## Security Notes

- Use `ansible-vault encrypt_string` for inline secrets
- Use `vars_files` with vault-encrypted files for bulk secrets
- Never echo or debug secret variables
- Use `no_log: true` on tasks that handle credentials
