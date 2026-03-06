# Contributing to DevOps Agent Hub

## Getting Started

1. **Fork** the repository.
2. **Clone** your fork locally.
3. **Create** a feature branch: `git checkout -b feat/your-feature`.
4. **Make** your changes following existing patterns.
5. **Validate**: `npm run lint:json && npm run validate`
6. **Commit** using conventional commits.
7. **Push** and open a PR.

## Commit Convention

[Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add new Terraform skill for AWS VPC
fix: correct Kubernetes RBAC rule
docs: update README with new setup flow
chore: update validation workflow
```

## Adding a New Agent

1. Create `.claude/agents/your-agent-name.md`.
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

3. Reference the agent from relevant command files in `.claude/commands/`.

## Adding a New Skill

1. Create `.claude/skills/your-skill-name/SKILL.md`.
2. Include YAML frontmatter (`name`, `description`, `user-invocable`, `allowed-tools`).
3. Add practical, step-by-step instructions with examples.

## Adding a New Command

1. Create `.claude/commands/your-command.md`.
2. Include command frontmatter (`name`, `description`, `argument-hint`).
3. Use `$ARGUMENTS` in command body.
4. For destructive commands, set `disable-model-invocation: true`.

## Adding Rules

1. Choose the correct category (`common`, `terraform`, `kubernetes`, `docker`, `cicd`, `cloud`, `security`).
2. Add or update rule markdown under `.claude/rules/{category}/`.
3. Domain rules must have `paths` frontmatter for file-pattern scoping.

## Project Structure

All Claude Code components live under `.claude/`:

```
.claude/
├── agents/      # Subagent definitions
├── commands/    # Slash commands
├── skills/      # Domain knowledge packs
├── rules/       # Path-scoped guidelines
└── settings.json # Hooks configuration
```

## Code of Conduct

- Be respectful and constructive.
- Focus on the work, not the person.
- Document your changes clearly.
