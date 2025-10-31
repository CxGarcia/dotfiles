---
id: focus-on-simplicity
name: focus on simplicity
category: architecture
tags: [simplicity, design, clarity, yagni, kiss]
is_default: false
created_at: 2025-10-30T12:00:00Z
updated_at: 2025-10-30T23:10:00Z
usage: Use when designing new features or refactoring existing code
---

Keep the implementation simple and clear:

## Core Principles

- Solve the immediate problem, not imaginary future ones (YAGNI)
- Prefer straightforward over clever
- Question every abstraction - does it earn its weight?
- If it's hard to explain, it's too complex

## Practical Guidelines

- Three uses before abstracting - resist premature generalization
- Prefer duplication over the wrong abstraction
- Choose boring, proven solutions over shiny new patterns
- Use `switch` over nested `if-else` chains

## Red Flags to Avoid

- "We might need this later" - You Aren't Gonna Need It
- "This is more flexible" - Flexibility has a cost
- "This is more elegant" - Elegance serves users, not egos
- Multiple layers of indirection without clear benefit

**Test**: Can a developer understand this in 3 months? If not, simplify.
