---
name: ansible
description: Run Ansible operations — playbooks, deployments, diagnostics, inventory management, and role development
argument-hint: "<operation description, e.g. 'deploy axiserp', 'check disk usage', 'create nginx role'>"
---

## Ansible Operations

Task: $ARGUMENTS

### Agent

- **ansible-agent** — Execute the requested Ansible operation

### Workflow

1. **ansible-agent**: Analyze the request
   - Read the `ansible-operations` skill for project context
   - Identify target hosts, playbooks, or roles involved
   - Determine if this is an existing playbook run or new playbook creation

2. **ansible-agent**: Plan and validate
   - For existing playbooks: identify the correct playbook and parameters
   - For new playbooks: design idempotent tasks following existing patterns
   - For destructive operations: require explicit user confirmation

3. **ansible-agent**: Execute
   - Run from `/Users/bipin/MyProjects/devops/ansible`
   - Use `--check` (dry run) first for production hosts
   - Execute with appropriate `--limit` and `--extra-vars`
   - Capture and report results

4. **ansible-agent**: Report
   - Hosts: reached / changed / failed / unreachable
   - Tasks: ok / changed / skipped / failed
   - Any errors or warnings with context
   - Recommended follow-up actions if applicable

### Output

Ansible operation completed with execution summary.
