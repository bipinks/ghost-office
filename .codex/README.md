# Codex Compatibility

This repository is configured to run with Codex and Claude side by side.

## What was added
- Project-level Codex config: `.codex/config.toml`
- Codex skills bridge: `.agents/skills -> ../skills` (symlink)

## Run with Codex
```bash
# Start Codex in this project
codex -C /Users/bipin/MyProjects/devops/claud-code-project

# Use strict profile for sensitive infra tasks
codex -C /Users/bipin/MyProjects/devops/claud-code-project -p devops_strict
```

## Install MCP servers into global Codex config (optional)
Project-local `mcp_servers` entries are in `.codex/config.toml`.
If you prefer global config, run these commands once:

```bash
codex mcp add github --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" -- npx -y @modelcontextprotocol/server-github
codex mcp add aws --env AWS_PROFILE="$AWS_PROFILE" --env AWS_REGION="$AWS_REGION" -- npx -y @modelcontextprotocol/server-aws
codex mcp add docker -- npx -y @modelcontextprotocol/server-docker
```

## Notes
- Claude plugin files remain under `.claude-plugin/` and are unchanged in behavior.
- Codex reads `AGENTS.md` and project docs directly.
