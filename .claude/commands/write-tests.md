---
name: write-tests
description: Write comprehensive tests for a module, feature, or bug fix
argument-hint: "<module or feature to test>"
---

## Write Tests

Write comprehensive tests for: $ARGUMENTS

### Agents Involved
- **qa-agent** — Test strategy and implementation
- **backend-engineer** — Backend test assistance
- **frontend-engineer** — Frontend test assistance

### Workflow

1. **qa-agent**: Define test strategy
   - Identify what needs testing (models, services, APIs, UI)
   - Determine test types needed (unit, integration, e2e)
   - Map edge cases and boundary conditions
   - Define coverage targets

2. **qa-agent** + **backend-engineer**: Write backend tests
   - Unit tests for service layer business logic
   - Feature tests for API endpoints (CRUD, validation, auth)
   - Multi-tenant isolation tests
   - Database constraint tests
   - Edge case and error handling tests

3. **qa-agent** + **frontend-engineer**: Write frontend tests
   - Component unit tests
   - Form validation tests
   - State management tests
   - E2E tests for critical user flows

4. **qa-agent**: Run and verify
   - Execute all tests
   - Check coverage metrics
   - Verify all tests are deterministic
   - Ensure tests are independent (no shared state)

### Test Categories
- **Happy path**: Normal successful operations
- **Validation**: Invalid input handling
- **Authorization**: Permission enforcement
- **Multi-tenant**: Branch isolation
- **Edge cases**: Empty data, max values, concurrent operations
- **Error handling**: Service failures, network errors

### Output
Comprehensive test suite with coverage report and all tests passing.
