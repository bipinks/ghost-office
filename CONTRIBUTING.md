# Contributing to DevOps Agent Hub

Thank you for your interest in contributing. This project supports both Claude and Codex workflows.

## Getting Started

1. **Fork** the repository.
2. **Clone** your fork locally.
3. **Create** a feature branch: `git checkout -b feat/your-feature`.
4. **Make** your changes.
5. **Validate** locally:
   - `npm run lint:json`
   - `npm run validate`
   - `npm test`
6. **Commit** using conventional commits.
7. **Push** and open a PR.

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add new Terraform skill for AWS VPC
fix: correct Kubernetes RBAC rule
docs: update README with new setup flow
chore: update validation workflow
```

## Claude + Codex Compatibility Rules

- Keep shared knowledge in `skills/`.
- Do not duplicate skills for Codex; `.agents/skills` is a symlink to `skills/`.
- Keep plugin metadata valid:
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
- Keep Codex project config valid:
  - `.codex/config.toml`
- If you add MCP servers, update both:
  - `mcp-configs/mcp-servers.json` (Claude/plugin side)
  - `.codex/config.toml` (`[mcp_servers.*]` blocks)

## Adding a New Agent (Claude)

1. Create `agents/your-agent-name.md`.
2. Follow the frontmatter format:

```markdown
---
name: your-agent-name
description: What this agent does
tools: ["Read", "Grep", "Glob", "Bash"]
model: sonnet
---

You are a specialized DevOps agent for...
```

3. Reference the new agent from relevant command files in `commands/`.
4. Run `npm run validate` and `npm test`.

## Adding a New Skill (Shared)

1. Create `skills/your-skill-name/SKILL.md`.
2. Include YAML frontmatter (`name`, `description`, `user-invocable`, `allowed-tools`).
3. Add practical, step-by-step instructions with realistic examples.
4. If needed, add supporting docs in the same skill directory.
5. Run `npm run validate` and `npm test`.

## Adding a New Command

1. Create `commands/your-command.md`.
2. Include command frontmatter (`name`, `description`, `argument-hint`).
3. Use `$ARGUMENTS` in command body.
4. For sensitive/destructive commands, set `disable-model-invocation: true`.
5. Run `npm run validate` and `npm test`.

## Adding Rules

1. Choose the correct category (`common`, `terraform`, `kubernetes`, `docker`, `cicd`, `cloud`, `security`).
2. Add or update rule markdown under `rules/{category}/`.
3. Domain `best-practices.md` files must keep `paths` frontmatter.
4. Keep rules actionable, specific, and security-first.

## Quality Gate Before PR

- `npm run lint:json`
- `npm run validate`
- `npm test`
- `claude plugin validate .claude-plugin/plugin.json`
- `claude plugin validate .claude-plugin/marketplace.json`

## Code of Conduct

- Be respectful and constructive.
- Focus on the work, not the person.
- Help newcomers get started.
- Document your changes clearly.
