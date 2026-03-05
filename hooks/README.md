# Hooks — DevOps Safety & Automation

## Overview
Hooks are event-driven automations that fire on tool use events. They enforce safety checks, best practices, and quality standards automatically.

## Available Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `infra-safety-check` | PreToolUse (Bash) | Warns before destructive infrastructure operations (terraform apply/destroy, kubectl delete) |
| `secret-leak-prevention` | PostToolUse (Write/Edit) | Scans written files for potential hardcoded secrets |
| `dockerfile-best-practices` | PostToolUse (Write) | Checks Dockerfiles for common issues (:latest, root user, no HEALTHCHECK) |
| `terraform-plan-reminder` | PreToolUse (Bash) | Reminds to review plan output, warns about -auto-approve |
| `yaml-lint-check` | PostToolUse (Write/Edit) | Lints YAML files after editing |

## Customization

### Disabling a Hook
Remove or comment out the hook entry in `hooks.json`.

### Adding a Custom Hook
```json
{
  "name": "my-custom-hook",
  "type": "PostToolUse",
  "matcher": "tool == \"Write\" && tool_input.file_path matches \"pattern\"",
  "hooks": [{
    "type": "command",
    "command": "#!/bin/bash\n# Your custom check here"
  }]
}
```

### Hook Types
- **PreToolUse** — Runs before the tool executes (can warn/prevent)
- **PostToolUse** — Runs after the tool completes (can validate output)
- **Stop** — Runs when the agent session ends
