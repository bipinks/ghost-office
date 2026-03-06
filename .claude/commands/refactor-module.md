---
name: refactor-module
description: Refactor an ERP module for improved code quality, performance, or architecture
argument-hint: "<module name and refactoring goal>"
---

## Refactor Module

Refactor the following module: $ARGUMENTS

### Agents Involved
- **architecture-agent** — Design the target architecture
- **backend-engineer** — Implement backend refactoring
- **frontend-engineer** — Implement frontend refactoring
- **database-engineer** — Schema optimization if needed
- **qa-agent** — Ensure no regressions
- **performance-agent** — Verify performance improvement

### Workflow

#### Phase 1: Analysis
1. **architecture-agent**: Assess current state
   - Map current code structure and dependencies
   - Identify code smells and technical debt
   - Design target architecture
   - Define refactoring strategy (incremental vs big-bang)

2. **performance-agent**: Baseline metrics
   - Measure current performance
   - Identify bottlenecks
   - Set improvement targets

#### Phase 2: Refactoring (Incremental)
3. **backend-engineer** / **frontend-engineer**: Implement changes
   - Follow the strangler fig pattern for large refactors
   - One logical change per commit
   - Run tests after each change
   - Keep backward compatibility during transition

4. **database-engineer**: Schema optimization
   - Add/optimize indexes
   - Denormalize if performance requires it
   - Migrate data if schema changes

#### Phase 3: Verification
5. **qa-agent**: Regression testing
   - Run full test suite
   - Compare behavior before/after
   - Verify all existing features still work

6. **performance-agent**: Measure improvement
   - Compare against baseline
   - Verify performance targets met
   - Document improvements

### Output
Module refactored with verified improvements, no regressions, documented changes.
