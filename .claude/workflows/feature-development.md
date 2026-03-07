# Feature Development Workflow

## Overview
End-to-end workflow for developing new features, from requirements to deployment.

## Trigger
- User requests a new feature
- Product manager creates a feature specification
- Command: `/implement-feature`

## Workflow Diagram
```
[Requirements]──→[Design]──→[Implementation]──→[Testing]──→[Review]──→[Deploy]
     │               │          ┌────┴────┐        │          │          │
  Product Mgr    Architect    Backend  Frontend    QA      Security   DevOps
                              Engineer  Engineer   Agent    Agent     Engineer
```

## Phases

### Phase 1: Requirements (Sequential)
**Agent**: product-manager
**Actions**:
1. Analyze the feature request
2. Write user stories with acceptance criteria
3. Define data model requirements
4. Specify API contracts
5. Define UI/UX requirements
6. Identify permissions and multi-tenant requirements
**Output**: Feature specification document

### Phase 2: Architecture Design (Sequential)
**Agent**: architecture-agent
**Actions**:
1. Review feature specification
2. Evaluate technical approaches
3. Design component architecture
4. Define API contracts
5. Review data model with database-engineer
6. Document architecture decision
**Output**: Technical design document with ADR
**Gate**: Architecture approval required before implementation

### Phase 3: Database Setup (Sequential)
**Agent**: database-engineer
**Actions**:
1. Create migration files for schema changes
2. Add indexes for new queries
3. Create seed data for testing
4. Verify multi-tenant column (branch_id) on all tables
**Output**: Migration files ready to run

### Phase 4: Implementation (Parallel)
**Agents**: backend-engineer, frontend-engineer (run in parallel)

#### Backend Track
1. Create/update Eloquent models
2. Implement service layer business logic
3. Build API controllers and routes
4. Add form request validation
5. Create API resource transformers
6. Implement event dispatching for audit trail

#### Frontend Track
1. Create UI components
2. Build page layouts and forms
3. Integrate with API endpoints
4. Implement client-side validation
5. Add loading, error, and empty states
6. Ensure responsive design

**Output**: Feature code implemented on both frontend and backend

### Phase 5: Testing (Sequential after implementation)
**Agent**: qa-agent
**Actions**:
1. Write unit tests for backend services
2. Write feature tests for API endpoints
3. Write component tests for frontend
4. Write multi-tenant isolation tests
5. Run full test suite
6. Check coverage meets threshold (80%+)
**Output**: All tests passing with coverage report
**Gate**: Tests must pass before review

### Phase 6: Review (Parallel)
**Agents**: security-agent, architecture-agent (run in parallel)

#### Security Review
1. Check for OWASP Top 10 vulnerabilities
2. Verify authorization enforcement
3. Scan for hardcoded secrets
4. Validate input sanitization

#### Architecture Review
1. Verify implementation matches design
2. Check coding standards compliance
3. Review error handling
4. Verify multi-tenant isolation

**Output**: Review reports with any required fixes
**Gate**: No critical/high security findings

### Phase 7: Documentation (Parallel with deployment prep)
**Agent**: documentation-agent
**Actions**:
1. Write API documentation for new endpoints
2. Update user guide for the module
3. Add changelog entry
4. Update architecture docs if needed
**Output**: Documentation updated

### Phase 8: Deployment
**Agent**: devops-engineer
**Actions**:
1. Deploy to staging environment
2. Run smoke tests on staging
3. Await user approval for production
4. Deploy to production
5. Monitor for 15 minutes post-deploy
**Output**: Feature deployed and verified

## Error Handling

| Error | Recovery |
|-------|----------|
| Architecture review finds issues | Return to Phase 2, revise design |
| Tests fail | Return to Phase 4, fix code |
| Security review finds critical issue | Block deployment, fix immediately |
| Deployment fails | Rollback, investigate, fix, retry |

## Logging
Every phase logs:
- Agent name and action
- Start and end time
- Files created/modified
- Test results
- Review findings
