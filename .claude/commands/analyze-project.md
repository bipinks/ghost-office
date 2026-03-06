---
name: analyze-project
description: Analyze the current project structure, architecture, dependencies, and health
argument-hint: "[focus area: architecture|security|performance|dependencies|all]"
---

## Analyze Project

Perform a comprehensive analysis of the current project. Focus area: $ARGUMENTS

### Agents Involved
- **architecture-agent** — Code structure and architecture review
- **security-agent** — Security posture check
- **performance-agent** — Performance baseline assessment
- **qa-agent** — Test coverage analysis

### Steps

1. **Scan Project Structure**
   - Map directory layout and file organization
   - Identify frameworks, languages, and patterns in use
   - Catalog external dependencies and their versions

2. **Architecture Review**
   - Identify architectural patterns (MVC, service layer, repository)
   - Map module boundaries and dependencies
   - Check for circular dependencies
   - Assess multi-tenancy implementation

3. **Code Quality Assessment**
   - Run static analysis (lint, type checks)
   - Check test coverage metrics
   - Identify code smells and technical debt
   - Review error handling patterns

4. **Security Scan**
   - Scan for hardcoded secrets
   - Check dependency vulnerabilities
   - Review authentication and authorization patterns
   - Verify encryption settings

5. **Performance Baseline**
   - Identify potentially slow queries (N+1, missing indexes)
   - Check caching implementation
   - Review API response patterns
   - Assess frontend bundle size

6. **Generate Report**
   - Save findings to `docs/architecture_report.md`
   - Prioritize issues by severity
   - Recommend next actions

### Output
A comprehensive project analysis report with findings categorized by severity and actionable recommendations.
