# DevOps Agent Hub — Agent Instructions

A **Claude Code native DevOps toolkit** with 11 specialized agents, 24 skills, 16 commands, and infrastructure safety hooks for CI/CD, cloud management, and deployment automation.

## Core Principles
1. **Agent-First** — Delegate to specialized agents for domain tasks
2. **Infrastructure-as-Code** — All infrastructure changes through code, never manual
3. **Security-First** — Never compromise on security; validate all configurations
4. **Immutable Infrastructure** — Replace, don't modify; use versioned artifacts
5. **Plan Before Apply** — Always review plans before applying infrastructure changes

## Available Agents
| Agent | Purpose | When to Use |
|-------|---------|-------------|
| infra-planner | Infrastructure architecture design | VPC layouts, capacity planning, multi-tier design |
| cicd-architect | CI/CD pipeline architecture | GitHub Actions, GitLab CI, Jenkins pipelines |
| cloud-reviewer | Infrastructure code review | Terraform, CloudFormation, Pulumi reviews |
| security-auditor | CIS benchmarks, OWASP | Security audits, compliance checks |
| incident-responder | Incident triage and RCA | Production incidents, on-call triage |
| cost-optimizer | Cloud cost analysis (FinOps) | Cost reviews, right-sizing, savings plans |
| deployment-manager | Deployment orchestration | Blue/green, canary, rolling deployments |
| monitoring-analyst | Observability and SLOs | Prometheus, Grafana, alerting setup |
| database-ops | Database operations | Migrations, backups, replication, tuning |
| container-reviewer | Docker/K8s review | Dockerfile, Compose, K8s manifest review |
| ms-it-admin | Microsoft 365 & Entra ID administration | User provisioning, licensing, Teams, Exchange, Intune, Conditional Access |

## Agent Orchestration
Use agents proactively without user prompt:
- Infrastructure design requests → **infra-planner**
- Terraform/IaC code written → **cloud-reviewer**
- Security-sensitive changes → **security-auditor**
- Deployment requests → **deployment-manager**
- Production issues → **incident-responder**
- Cost inquiries → **cost-optimizer**
- Container configuration → **container-reviewer**
- Database changes → **database-ops**
- Microsoft 365/Entra ID tasks → **ms-it-admin**

Use parallel execution for independent operations — launch multiple agents simultaneously.

## Security Guidelines
**Before ANY infrastructure change:**
- No hardcoded secrets (API keys, passwords, tokens, certificates)
- IAM follows least privilege principle
- Encryption at rest enabled for all storage
- Encryption in transit (TLS 1.2+) for all communication
- Security groups restrict ingress to minimum required
- No 0.0.0.0/0 ingress on sensitive ports (SSH, RDP, DB)
- Audit logging enabled (CloudTrail, flow logs, access logs)
- Container images scanned for vulnerabilities

**Secret management:** NEVER hardcode secrets. Use environment variables, secrets managers (Vault, AWS Secrets Manager), or sealed secrets. Rotate any exposed credentials immediately.

**If security issue found:** STOP → use security-auditor agent → fix CRITICAL issues → rotate exposed credentials → review infrastructure for similar issues.

## Coding Style
**Infrastructure-as-Code:**
- Use modules/roles for reusable components
- Add validation rules to all input variables
- Include descriptions for all variables and outputs
- Pin provider/tool versions explicitly
- Use consistent naming: `{project}-{environment}-{resource}` format

**File organization:**
- Separate state per environment and component
- Group by feature/domain, not by resource type
- Keep files focused and under 400 lines
- README.md for every module and role

**Error handling:**
- Validate inputs at module boundaries
- Provide clear error messages for failed validations
- Never silently ignore infrastructure issues
- Log detailed context for operations

## Testing Requirements
**Infrastructure testing (all required):**
1. **Static analysis** — `terraform validate`, `tflint`, `checkov`, `trivy`
2. **Unit tests** — Module-level tests with Terratest or pytest
3. **Integration tests** — Deploy to ephemeral environment, validate, destroy
4. **Compliance tests** — CIS benchmark checks, policy-as-code (OPA, Sentinel)

**Pipeline testing:**
- Run all checks on every PR
- Pin tool versions for reproducibility
- Use test environments that mirror production
- Clean up test resources after each run

## Development Workflow
1. **Plan** — Use infra-planner agent, identify requirements, design architecture
2. **Implement** — Write IaC with best practices, use skills for domain knowledge
3. **Review** — Use cloud-reviewer + security-auditor agents, address all findings
4. **Test** — Static analysis, unit tests, integration tests
5. **Deploy** — Use deployment-manager agent, monitor during and after
6. **Monitor** — Use monitoring-analyst agent, set up SLOs and alerting

## Git Workflow
**Commit format:** `<type>: <description>` — Types: feat, fix, refactor, docs, test, chore, ci, infra

**PR workflow:** Include terraform plan output → review with cloud-reviewer → require approval → merge to main → auto-deploy to staging → manual gate for production.

## Architecture Patterns
**Multi-tier design:** Public → Private → Data subnets across 3+ AZs.

**Deployment strategies:** Blue/green for major releases, canary for high-risk changes, rolling for standard releases.

**GitOps:** Git as single source of truth. ArgoCD/Flux for pull-based deployment. Kustomize overlays for environment-specific configuration.

**Observability:** Four golden signals (latency, traffic, errors, saturation). SLI/SLO/error budget framework. Runbook-linked alerts.

## Performance
**Context management:** Prioritize high-impact infrastructure changes. Use agents in parallel for independent reviews. Cache frequently used patterns from skills.

**Build troubleshooting:** Use container-reviewer for Docker issues → cloud-reviewer for IaC issues → monitoring-analyst for runtime issues.

## Project Structure
```
.claude/
  agents/        — 11 specialized DevOps subagents
  commands/      — 16 slash commands
  skills/        — 24 domain knowledge packs
  rules/         — 12 always-follow guidelines (7 categories)
  settings.json  — Infrastructure safety hooks
.mcp.json        — MCP server configurations (GitHub, AWS, Cloudflare, etc.)
scripts/         — Cross-platform Node.js utilities
contexts/        — 4 dynamic context modes
examples/        — 4 real-world CLAUDE.md templates
```

## Success Metrics
- All infrastructure changes go through code review
- No security vulnerabilities in deployed infrastructure
- Zero secrets exposed in code or logs
- SLOs met for all production services
- Deployment rollback available within 5 minutes
- Mean Time To Recovery (MTTR) under 30 minutes for SEV1
- Cloud costs tracked with FinOps practices
