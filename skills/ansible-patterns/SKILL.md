---
name: ansible-patterns
description: Use when writing Ansible playbooks, roles, or automating server configuration. Covers role directory structure, inventory management, variable precedence, handlers, Galaxy integration, and idempotent task design.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Ansible Patterns

## Role Structure
```
roles/
└── webserver/
    ├── defaults/main.yml     # Default variables (lowest priority)
    ├── vars/main.yml         # Role variables
    ├── tasks/main.yml        # Main task list
    ├── handlers/main.yml     # Handler definitions
    ├── templates/             # Jinja2 templates
    │   └── nginx.conf.j2
    ├── files/                 # Static files
    ├── meta/main.yml         # Role metadata and dependencies
    └── molecule/             # Testing with Molecule
        └── default/
            ├── molecule.yml
            └── verify.yml
```

## Production Playbook
```yaml
---
- name: Configure web servers
  hosts: webservers
  become: true
  vars_files:
    - vars/{{ env }}.yml
    - vars/secrets.yml

  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: true
        cache_valid_time: 3600

  roles:
    - role: common
      tags: [common]
    - role: security
      tags: [security]
    - role: webserver
      tags: [webserver]
    - role: monitoring
      tags: [monitoring]

  post_tasks:
    - name: Verify services
      uri:
        url: "http://localhost:{{ app_port }}/healthz"
        status_code: 200
      retries: 5
      delay: 10
```

## Inventory
```ini
# inventory/production/hosts
[webservers]
web01 ansible_host=10.0.1.10
web02 ansible_host=10.0.1.11
web03 ansible_host=10.0.1.12

[databases]
db01 ansible_host=10.0.2.10 role=primary
db02 ansible_host=10.0.2.11 role=replica

[all:vars]
ansible_user=deploy
ansible_python_interpreter=/usr/bin/python3
env=production
```

## Best Practices
1. **Idempotency** — All tasks must be safe to run multiple times
2. **Variables** — Use `defaults/` for overridable values, `vars/` for fixed values
3. **Vault** — Encrypt sensitive data with `ansible-vault`
4. **Handlers** — Use handlers for service restarts (only when changed)
5. **Tags** — Tag roles and tasks for selective execution
6. **Testing** — Use Molecule for role testing
7. **Lint** — Use `ansible-lint` to enforce best practices
8. **Inventory** — Separate inventory per environment
