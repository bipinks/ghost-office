# CLAUDE.md — DevOps Agent Hub

## Project Overview

A Claude Code native DevOps toolkit: 10 specialized agents, 21 skills, 16 slash commands, path-scoped rules, and infrastructure safety hooks for cloud operations, CI/CD, and deployment workflows.

## Architecture

All components live under `.claude/` for native auto-discovery:

- **Agents** (`.claude/agents/`): Subagents for specific DevOps tasks
- **Commands** (`.claude/commands/`): Slash commands for quick task execution
- **Skills** (`.claude/skills/`): Domain knowledge packs with step-by-step workflows
- **Rules** (`.claude/rules/`): Always-follow guidelines organized by domain
- **Settings** (`.claude/settings.json`): Hooks for infrastructure safety checks
- **MCP** (`.mcp.json`): External service connections (GitHub, AWS, Cloudflare, etc.)

## References

- Agent reference: @AGENTS.md
- Beginner setup: @BEGINNERS-GUIDE.md
- Contribution guide: @CONTRIBUTING.md

## Key Conventions

- Agents use frontmatter: name, description, tools, model
- Skills directories contain a `SKILL.md` as the main instruction
- Commands use `$ARGUMENTS` substitution
- Rules use `paths` frontmatter for file-pattern scoping
- All infrastructure changes require explicit confirmation
- Never store secrets in plain text or commit them
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`

## File Patterns

- Agent definitions: `.claude/agents/*.md`
- Slash commands: `.claude/commands/*.md`
- Skill instructions: `.claude/skills/*/SKILL.md`
- Rule files: `.claude/rules/{domain}/*.md`
- Hooks/settings: `.claude/settings.json`
- MCP config: `.mcp.json`

## Testing

- Validate JSON: `node -e "JSON.parse(require('fs').readFileSync('FILE','utf8'))"`
- Check structure: `find .claude -name "SKILL.md" -type f`
- Verify agents: `ls .claude/agents/`
- Verify commands: `ls .claude/commands/`

## Important

- This is a Claude Code native project — no plugin install required
- All content is markdown, JSON, and shell scripts
- Components auto-discover from `.claude/` at session start
