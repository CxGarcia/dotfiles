---
id: debug-trace
name: debug trace
category: debugging
tags: [debug, troubleshooting, bug-fix, investigation]
is_default: false
created_at: 2025-10-30T12:00:00Z
updated_at: 2025-10-30T23:10:00Z
usage: Use when investigating bugs or unexpected behavior
---

Debug systematically:

## Process

1. **Understand the problem** - Expected vs actual behavior? Reproducible? Recent changes?
2. **Gather context** - Check logs, stack traces, recent commits, dependencies
3. **Isolate** - Narrow to smallest reproducible case, binary search, add logging
4. **Fix root cause** - Not just symptoms. Add test to prevent regression
5. **Verify** - Check fix works in all scenarios, look for similar bugs elsewhere

## Common Culprits (Go)

- Nil pointers - check before dereferencing
- Goroutine leaks - use `runtime.NumGoroutine()` to check
- Race conditions - run tests with `-race` flag
- Type mismatches at boundaries
- Off-by-one errors in loops/slices

## After Fixing

```bash
# Add regression test
# Run full test suite
make test

# Verify no race conditions
go test -race ./...
```
