# Autonomous AI Software Company — Agent Instructions

18 agents (7 departments), 54 skills, 23 commands, 6 workflows, 12 hooks, 7 domain templates.

## Principles

1. **Agent-First** — Delegate to specialized agents for domain tasks
2. **Parallel Execution** — Independent tasks run simultaneously
3. **Quality Gates** — Tests, security review, approval before deployment
4. **Knowledge-Driven** — Agents reference `.claude/memory/` for consistency
5. **Audit Everything** — Log all actions and decisions
6. **Security-First** — Never compromise; validate all changes

## Agent Roster

| Agent | Dept | When to Use |
|-------|------|-------------|
| master-orchestrator | All | Plans, assigns, tracks, delivers (every task) |
| product-manager | Product | Feature planning, user stories, acceptance criteria |
| ui-ux-designer | Product | UI design, wireframes, design systems |
| architecture-agent | Engineering | New features, refactors, architecture reviews |
| backend-engineer | Engineering | Backend features, APIs, integrations |
| frontend-engineer | Engineering | Frontend features, UI bugs, responsive design |
| database-engineer | Engineering | DB changes, migrations, query optimization |
| prompt-engineer | Engineering | Prompt design, chatbots, AI features |
| qa-agent | Quality | Test writing, bug verification, regression testing |
| security-agent | Quality | Security reviews, pen testing, compliance |
| devops-engineer | Operations | Pipeline setup, server config, deployments |
| monitoring-agent | Operations | Monitoring, incident triage, RCA |
| performance-agent | Operations | Performance issues, optimization, cost analysis |
| content-strategist | Marketing | Content planning, copywriting, SEO audits |
| social-media-manager | Marketing | Social campaigns, community management |
| support-agent | Support | Bug reports, client setup, admin tasks |
| documentation-agent | Support | Documentation, changelogs, ADRs |
| ms-it-admin | IT | Microsoft 365, Entra ID, Teams, Exchange |

## Orchestration

**Auto-routing**: Feature → product-manager → architecture → engineers → qa. Bug → support → engineer → qa. Deploy → devops → monitoring. Security → security-agent (immediate). Incident → monitoring → devops → engineers.

**Parallel execution**: Backend + frontend (after design). Security + architecture review (post-implementation). Docs + deployment prep.

## Workflows

| Workflow | Phases |
|----------|--------|
| Feature Development | Requirements → Design → Implement → Test → Review → Deploy |
| Bug Fix | Triage → Investigate → Fix → Test → Deploy |
| Release Process | Freeze → QA → Security → Staging → Approval → Production |
| Production Incident | Detect → Triage → Investigate → Mitigate → Resolve → Post-mortem |
| Client Deployment | Requirements → Tenant → Config → Data → Deploy → Verify |
| Content Campaign | Strategy → Create → Optimize → Publish → Analyze |

## Quality Requirements

- [ ] Code follows `.claude/memory/coding-standards.md`
- [ ] Tests written and passing (80%+ coverage)
- [ ] Security review passed
- [ ] Multi-tenant isolation verified (branch_id)
- [ ] Documentation updated
- [ ] Database migrations reversible
- [ ] No breaking API changes

## Security

Before any change: no hardcoded secrets, least-privilege IAM, encryption at rest + in transit, multi-tenant isolation verified, audit logging enabled. If security issue found: STOP → security-agent → fix → rotate credentials → review for similar issues.

## Project Structure

```
.claude/
  agents/    — 18 agents (7 departments)
  commands/  — 23 slash commands
  workflows/ — 6 workflow definitions
  memory/    — 6 knowledge docs + 7 domain templates
  skills/    — 54 domain knowledge packs
  rules/     — 12 guidelines (7 categories)
  hooks/     — 12 safety/audit hooks
  tools/     — 4 tool references
  settings.json
```
