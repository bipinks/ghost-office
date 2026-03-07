---
paths:
  - .claude/agents/**
  - .claude/skills/**
  - .claude/commands/**
  - .claude/workflows/**
  - .claude/hooks/**
  - .claude/rules/**
---

# Documentation Sync — Mandatory Updates

## Rule

When adding, removing, or renaming any agent, skill, command, workflow, hook, or rule, you MUST update the documentation files that reference counts or listings for that component type.

## Files to Update

| Component Changed | Update These Files |
|-------------------|--------------------|
| Agent added/removed | `CLAUDE.md`, `AGENTS.md`, `README.md`, `BEGINNERS-GUIDE.md`, `docs/architecture_report.md` |
| Skill added/removed | `CLAUDE.md`, `AGENTS.md`, `README.md`, `BEGINNERS-GUIDE.md`, `docs/architecture_report.md` |
| Command added/removed | `CLAUDE.md`, `AGENTS.md`, `README.md`, `BEGINNERS-GUIDE.md` |
| Workflow added/removed | `CLAUDE.md`, `AGENTS.md` |
| Hook added/removed | `CLAUDE.md`, `docs/architecture_report.md` |
| Rule added/removed | `CLAUDE.md` |

## What to Update

1. **Counts** — Update all numeric counts (e.g., "38 domain knowledge packs" → "39 domain knowledge packs")
2. **Listings** — If the file lists items by name, add/remove the entry
3. **Structure trees** — Update directory structure diagrams that show counts
4. **Routing tables** — If a new command/agent is added, update the "Which Agent" routing table in `README.md`

## How to Find Counts

Search for the current count number in each file. Counts appear in:
- Inline text (e.g., "14 specialized agents, 38 skills")
- Structure tree comments (e.g., `├── skills/ — 38 domain knowledge packs`)
- Diagram labels (e.g., `│ SKILLS (38 knowledge packs) │`)

## Commit Convention

Include documentation updates in the same commit as the component change, or as a follow-up `docs:` commit:
```
feat: add new-skill-name skill for X domain
docs: update counts for new-skill-name skill addition
```
