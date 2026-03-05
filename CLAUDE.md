# CLAUDE.md — DevOps Agent Hub

## Project Overview

This is a DevOps-focused AI agent harness — a plugin system providing specialized agents, skills, commands, rules, and hooks for infrastructure automation, CI/CD, cloud management, and deployment workflows.

## References

- Project overview: @README.md
- Plugin structure: @.claude-plugin/plugin.json
- Available agents: @AGENTS.md
- Contribution guide: @CONTRIBUTING.md
- Beginner setup: @BEGINNERS-GUIDE.md

## Architecture

- **Agents** (`agents/`): Markdown-defined subagents for specific DevOps tasks
- **Skills** (`skills/`): Domain knowledge packs with step-by-step workflows
- **Commands** (`commands/`): Slash commands for quick task execution
- **Rules** (`rules/`): Always-follow guidelines organized by domain
- **Hooks** (`hooks/`): Event-driven automations for safety and quality
- **Scripts** (`scripts/`): Cross-platform Node.js utilities
- **Contexts** (`contexts/`): Dynamic system prompt injection by mode

## Key Conventions

- All agents follow the frontmatter format: name, description, tools, model
- Skills directories contain a `SKILL.md` file as the main instruction
- Commands are slash commands (e.g., `/deploy`, `/infra-plan`) with `$ARGUMENTS` substitution
- Rules have common/ (universal) + domain-specific directories with `paths` frontmatter
- All infrastructure changes require explicit confirmation
- Never store secrets in plain text or commit them
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Destructive skills use `context: fork` for isolated subagent execution

## File Patterns

- Agent definitions: `agents/*.md`
- Skill instructions: `skills/*/SKILL.md`
- Skill supporting files: `skills/*/examples.md`, `skills/*/reference.md`
- Command definitions: `commands/*.md`
- Rule files: `rules/{domain}/*.md`
- Hook configs: `hooks/hooks.json`
- MCP configs: `mcp-configs/mcp-servers.json`

## Testing

- Validate JSON: `node -e "JSON.parse(require('fs').readFileSync('FILE','utf8'))"`
- Check structure: `find . -name "SKILL.md" -type f`
- Verify hooks: `node scripts/hooks/session-start.js --dry-run`
- Check $ARGUMENTS: `grep -L 'ARGUMENTS' commands/*.md`

## Important

- This is a plugin/configuration project — no compiled code
- All content is markdown, JSON, and shell scripts
- Follow the architecture and conventions documented in this repository
