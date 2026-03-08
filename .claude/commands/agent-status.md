---
name: agent-status
description: Show current status of all agents and their task progress in this session
argument-hint: "[agent-name|running|completed|all]"
---

Check the current agent session status by reading `.claude/status/agents.json` and `.claude/status/todos/*.json`.

**Filter**: $ARGUMENTS (default: show all active and completed agents)

## Instructions

1. Read `.claude/status/agents.json` to get the current session's agent statuses
2. For each agent with status data, read `.claude/status/todos/{agent-name}.json` if it exists
3. Display results grouped by department in this order: Product, Engineering, Quality, Operations, Marketing, Support, IT

### Display Format

For each active/completed agent show:
- **Status**: Running (with duration) or Completed (with total time)
- **Tasks**: Todo items with completion indicators (✓ done, ● in progress, ○ pending)
- **Progress**: X/Y tasks completed

If a specific agent name is provided as argument, show detailed view for that agent only.
If "running" is provided, show only currently running agents.
If "completed" is provided, show only completed agents.

### No Data

If no status file exists, inform the user:
- "No active agent session found. Agent status is tracked automatically when you run multi-agent tasks like `/implement-feature` or `/fix-bug`."

### Live Dashboard

After displaying the status, suggest: "For a live auto-refreshing dashboard, run in another terminal: `./scripts/agent-dashboard.sh`"
