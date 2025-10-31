---
id: last-review
name: one last review
category: code-review
tags: [review, quality, pre-merge, best-practices]
is_default: false
created_at: 2025-10-30T00:00:00Z
updated_at: 2025-10-30T23:10:00Z
usage: Use this before merging PRs or committing significant changes
---

Before merging, ensure quality standards:

## Compliance Checklist

```bash
make fmt && make lint && make build && make test
```

All must pass. No exceptions.

## Code Quality

- Clean, readable, well-organized
- Clear and consistent naming
- No commented-out code or debug statements
- Proper error handling with context

## Testing

- Tests pass locally
- Edge cases considered and handled
- No breaking changes without migration path

## Final Check

- Would I be comfortable maintaining this code in 6 months?
- Any opportunities for simplification?
- Does it follow existing codebase patterns?
