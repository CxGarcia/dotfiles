---
id: feature-scaffold
name: feature scaffold
category: code-generation
tags: [feature, scaffold, implementation, structure]
is_default: false
created_at: 2025-10-30T12:00:00Z
updated_at: 2025-10-30T23:10:00Z
usage: Use when implementing new features from scratch
---

Build features with solid foundations:

## Before Writing Code

- Understand the requirement - what problem does this solve?
- Check for similar patterns in the codebase
- List dependencies and integrations needed

## Implementation Order

1. **Data model/types first** - Define structs, interfaces
2. **Core logic** - Business logic, keep it testable
3. **Integration** - Wire it into the application
4. **Tests** - Use `testutils/fixtures` for workflows

## Key Questions

- **Error handling**: What can go wrong? How do we handle it?
- **Validation**: What input validation is needed?
- **Backwards compatibility**: Does this break existing functionality?

## Keep It Minimal

- Ship the smallest useful version first
- Focus on happy path, then edge cases
- Don't build for hypothetical future needs (YAGNI)

## Quality Check

```bash
make fmt && make lint && make build && make test
```
