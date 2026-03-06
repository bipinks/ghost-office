---
name: implement-feature
description: Implement a new ERP feature end-to-end with autonomous agent coordination
argument-hint: "<feature description>"
---

## Implement Feature

Implement the following feature using the full autonomous agent team: $ARGUMENTS

### Agents Involved
- **master-orchestrator** — Coordinates the entire workflow
- **erp-product-manager** — Writes feature spec and acceptance criteria
- **architecture-agent** — Reviews technical approach
- **backend-engineer** — Implements server-side code
- **frontend-engineer** — Implements UI components
- **database-engineer** — Designs schema and migrations
- **qa-agent** — Writes and runs tests
- **security-agent** — Reviews for security issues
- **documentation-agent** — Updates documentation

### Workflow

#### Phase 1: Planning (Sequential)
1. **erp-product-manager**: Write feature specification
   - User stories with acceptance criteria
   - Data model requirements
   - API endpoint definitions
   - UI/UX requirements
   - Permission requirements

2. **architecture-agent**: Review and approve technical approach
   - Evaluate proposed design
   - Identify risks and dependencies
   - Recommend implementation strategy

#### Phase 2: Implementation (Parallel where possible)
3. **database-engineer**: Create database migrations
   - Schema changes
   - Seed data if needed
   - Index optimization

4. **backend-engineer**: Implement backend (after migrations)
   - Models, services, controllers
   - API endpoints
   - Business logic
   - Validation rules

5. **frontend-engineer**: Implement frontend (parallel with backend)
   - Components and pages
   - API integration
   - Form validation
   - Responsive design

#### Phase 3: Quality (Sequential)
6. **qa-agent**: Write and run tests
   - Unit tests for backend services
   - Feature tests for API endpoints
   - Component tests for frontend
   - Multi-tenant isolation tests

7. **security-agent**: Security review
   - Code review for vulnerabilities
   - Permission enforcement verification
   - Input validation check

#### Phase 4: Documentation
8. **documentation-agent**: Update docs
   - API documentation
   - User guide for new feature
   - Changelog entry

### Output
Feature implemented with tests, security review, and documentation — ready for deployment.
