---
id: test-coverage
name: test coverage
category: testing
tags: [testing, quality, tdd, coverage, validation]
is_default: false
created_at: 2025-10-30T12:00:00Z
updated_at: 2025-10-30T23:10:00Z
usage: Use when writing tests or improving test coverage
---

Write meaningful tests that catch real bugs:

## What to Test

- Public APIs and interfaces
- Business logic and critical paths
- Error handling and edge cases
- Integration points between components

## What NOT to Test

- Private implementation details (tests should survive refactors)
- Third-party libraries
- Simple getters/setters with no logic

## Good Test Characteristics

- **Fast** - Milliseconds, not seconds
- **Isolated** - No dependencies on other tests
- **Repeatable** - Same result every time
- **Clear** - Test name explains what it verifies
- **Focused** - One concept per test

## Test Structure (AAA)

1. **Arrange** - Set up test data
2. **Act** - Execute the code
3. **Assert** - Verify expected outcome

## Go-Specific Tips

- Use table-driven tests for multiple scenarios
- Use `testutils/fixtures` for workflow tests
- Use subtests with `t.Run()` for organization
- Good naming: `TestWorkflow_WhenStepFails_ShouldReturnError`

## Remember

- 100% coverage ≠ bug-free code
- If code is hard to test, it's probably hard to use
- Missing coverage often reveals design issues
