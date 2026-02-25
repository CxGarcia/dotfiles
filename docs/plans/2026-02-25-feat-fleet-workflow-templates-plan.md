---
title: "feat: Fleet Workflow Templates"
type: feat
status: active
date: 2026-02-25
origin: docs/brainstorms/2026-02-25-fleet-workflow-templates-brainstorm.md
---

# Fleet Workflow Templates

## Overview

Add workflow awareness to the fleet captain via reference docs that encode two reusable patterns: **feature dev** and **parallel audit**. The captain uses these to construct better session prompts. No new CLI flags, no runtime phase tracking, no new event types — just knowledge that produces better prompts.

(see brainstorm: docs/brainstorms/2026-02-25-fleet-workflow-templates-brainstorm.md)

## Problem Statement

The captain constructs every spawn prompt from scratch. ~80% of spawns follow one of two patterns, and the captain reconstructs the same multi-phase instructions every time. This leads to inconsistency (sometimes the simplifier loop is forgotten, sometimes review doesn't cross-reference the plan) and forces the user to type long prompts that encode workflow knowledge that should be baked in.

## Proposed Solution

Three file changes — two new reference docs and one SKILL.md edit:

```
config/.claude/skills/fleet-captain/
├── SKILL.md                              (modify: add Workflows section)
└── references/
    ├── state-schema.md                   (existing, unchanged)
    ├── tmux-reference.md                 (existing, unchanged)
    ├── workflow-feature-dev.md           (new)
    └── workflow-parallel-audit.md        (new)
```

## Implementation

### Phase 1: Create `references/workflow-feature-dev.md`

The feature dev workflow reference doc. Follows existing reference doc conventions: H1 title, one-line purpose sentence, H2 sections, tables for state machine, fenced blocks for prompt template.

**Sections:**

#### 1.1 State Machine

Table defining phases, what each does, what artifact it produces, and allowed transitions:

| Phase | Does | Produces | Next |
|-------|------|----------|------|
| brainstorm | Explores what to build via `/workflows:brainstorm` | `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md` | plan, work (shortcut) |
| plan | Designs how to build via `/workflows:plan` | `docs/plans/YYYY-MM-DD-<type>-<topic>-plan.md` | work |
| work | Implements via `/workflows:work` with agent teams | Code changes on branch | simplify |
| simplify | Divide-and-conquer cleanup | Cleaned code | review |
| review | Cross-references impl against plan/brainstorm | Auto-fixed divergences | pr |
| pr | Commit, push, create PR, monitor CI | Merged PR | done |

Allowed shortcuts:
- brainstorm → work (small fix, plan not needed)
- Entry at plan (brainstorm done in prior session)
- Entry at work (plan already exists)
- `/slfg` mode: work → simplify → review → pr (skips brainstorm + plan)
- Any phase → brainstorm (bounce-back when assumptions fail)

#### 1.2 Prompt Template

The actual prompt text the captain embeds in the session's first message. Uses `{{description}}` placeholder. The prompt instructs the session to:

1. Start with `/workflows:brainstorm {{description}}`
2. After brainstorm doc is written, auto-invoke `/workflows:plan` referencing the brainstorm doc path
3. After plan doc is written, auto-invoke `/workflows:work` referencing the plan doc path, using agent teams to parallelize
4. After work completes, run the simplifier ritual: "Establish boundaries and have teams of simplifier agents running in a loop on all changes. They need to run until there's nothing else to simplify in their respective domain."
5. After simplification, cross-reference all code changes against the brainstorm and plan docs. Auto-fix any divergences.
6. Commit, push to branch `worktree-{{name}}`, create PR. Run `gh pr checks` to monitor CI and fix failures.

The template also encodes:
- "Do NOT stop between phases" — sessions auto-advance
- "If brainstorm reveals a small fix, skip plan and go straight to work"
- "If assumptions prove wrong during work, bounce back to brainstorm"

**Entry point variants** — the captain selects the right variant based on context:

| Context | Entry | Template starts at |
|---------|-------|--------------------|
| Natural language feature request | brainstorm | Phase 1 (brainstorm) |
| Existing brainstorm doc referenced | plan | Phase 2 (plan), with brainstorm path |
| Existing plan doc referenced | work | Phase 3 (work), with plan path |
| User says "slfg" or "just do it" | slfg | Phase 3 (work) compressed, no brainstorm/plan |

#### 1.3 Conventions

- Feature dev sessions always use `--worktree`
- Naming: kebab-case from the feature description (e.g., `sso-login`, `connector-icons`)
- Scope: not set (default `any`) — the session manages its own phases
- CI: sessions self-monitor after PR creation
- Auto-merge: only when the user explicitly requests it

#### 1.4 Captain Guidance

What the captain watches for during a feature dev workflow:

- **Pickers during brainstorm/plan** — these are AskUserQuestion prompts. The captain reads them via `fleet check`, decides or asks the user, responds via `fleet pick`.
- **Context warnings** — if the session compacts during work phase, the captain checks coherence. If degraded, kill and respawn at the work phase with `--branch` to continue from existing commits.
- **Idle after work** — session may have finished work but not started simplify. Check and send a nudge if needed.
- **PR CI failures** — session should self-monitor, but if it goes idle with failing CI, send a correction.

### Phase 2: Create `references/workflow-parallel-audit.md`

The parallel audit workflow reference doc. Same format conventions.

**Sections:**

#### 2.1 Pattern

Fan-out N parallel sessions across subsystems. Each session runs autonomously with a scoped task (review, simplify, or test). Each creates its own PR.

#### 2.2 Audit Types

| Type | Skill | Session prompt includes | Auto-merge |
|------|-------|------------------------|------------|
| review | Deep code review | "Find and fix: redundant code, dead code, untested code, convention violations" | No |
| simplify | `/code-simplifier:code-simplifier` | "Run in a loop until nothing else to simplify" | Yes |
| test | Write tests | "Write deep integration tests covering the full surface" | No |

#### 2.3 Prompt Template

Template for each parallel session. Uses `{{subsystem}}`, `{{audit_type}}`, `{{scope_paths}}` placeholders.

The captain constructs N instances, one per subsystem, with the same audit type.

#### 2.4 Fan-out Procedure

1. Captain determines subsystems (from user prompt, or by asking)
2. Spawns N sessions: `fleet spawn {audit_type}-{subsystem} {repo} "{prompt}" --worktree`
3. Naming: `{audit_type}-{subsystem}` (e.g., `review-sync-engine`, `simplify-catalog`)
4. Each session runs autonomously → commits → pushes → creates PR
5. For simplify audits, enable auto-merge in the prompt: `gh pr merge --auto --squash`

#### 2.5 Captain Guidance

- Monitor all sessions in parallel via `fleet status --tag audit` (tag all audit sessions)
- Handle pickers/blockers across all sessions
- If a session hits context warning, kill and respawn with `--branch` to continue
- Report completion status: "5/7 audit sessions have PRs, 2 still working"

### Phase 3: Modify SKILL.md

Add a `## Workflows` section between `## Spawning` and `## Branching Strategy`.

**Insert after line 109** (the current last line of Spawning: `To invoke a workflow...`).

Replace that one-liner with the full Workflows section:

```markdown
## Workflows

The captain recognizes common workflow patterns and constructs appropriate session prompts. Workflows are not rigid pipelines — they are state machines with shortcuts. The session prompt IS the workflow; sessions self-execute through phases autonomously.

Two workflows are defined:

- [[workflow-feature-dev]] — brainstorm → plan → work → simplify → review → PR. For building new features, refactoring, or complex fixes. Always uses `--worktree`.
- [[workflow-parallel-audit]] — fan-out N sessions for review/simplify/test across subsystems. For codebase-wide sweeps.

### Recognizing workflows

The captain infers the workflow from the user's natural language:

| User says | Workflow | Entry point |
|-----------|----------|-------------|
| "build feature X", "add X", "implement X" | feature-dev | brainstorm |
| "here's a brainstorm, plan and build it" | feature-dev | plan |
| "implement this plan: docs/plans/..." | feature-dev | work |
| "slfg", "just do it", "lfg" | feature-dev (compressed) | work (skip brainstorm/plan) |
| "review the codebase", "audit X" | parallel-audit | fan-out |
| "simplify all the code in X" | parallel-audit (simplify) | fan-out |
| "write tests for all of X" | parallel-audit (test) | fan-out |

When in doubt, ask the user. When clear, just do it.

### Constructing the prompt

1. Select the workflow and entry point from the table above
2. Read the workflow reference doc for the prompt template
3. Fill in placeholders ({{description}}, {{name}}, etc.)
4. Spawn with appropriate flags (feature-dev always gets `--worktree`)
```

Also remove the old one-liner at line 109 since it's now superseded by the Workflows section.

## Acceptance Criteria

- [x] `references/workflow-feature-dev.md` exists with state machine, prompt template, conventions, captain guidance
- [x] `references/workflow-parallel-audit.md` exists with fan-out pattern, audit types, prompt template, captain guidance
- [x] `SKILL.md` has a `## Workflows` section between Spawning and Branching Strategy
- [x] `SKILL.md` Workflows section contains wikilinks to both workflow docs
- [x] `SKILL.md` Workflows section has recognition table (natural language → workflow → entry point)
- [x] The feature dev prompt template includes all 6 phases: brainstorm → plan → work → simplify → review → pr
- [x] The feature dev prompt template supports shortcuts (skip plan, slfg mode, bounce-back)
- [x] The parallel audit prompt template supports all 3 audit types (review, simplify, test)
- [x] All new docs follow existing reference doc conventions (H1 title, tables, fenced blocks, ~50-80 lines)
- [x] No new CLI flags, registry fields, or event types are introduced

## Sources

- **Origin brainstorm:** [docs/brainstorms/2026-02-25-fleet-workflow-templates-brainstorm.md](docs/brainstorms/2026-02-25-fleet-workflow-templates-brainstorm.md) — Key decisions: workflows as captain-side knowledge, prompt-driven triggers, state machines with shortcuts, single session per feature, divide-and-conquer simplify, auto-fix review divergence
- **Predecessor brainstorm:** [docs/brainstorms/2026-02-23-fleet-modes-rethink-brainstorm.md](docs/brainstorms/2026-02-23-fleet-modes-rethink-brainstorm.md) — Dropped rigid modes/phases, established prompt-only spawning
- Existing reference docs: `references/state-schema.md`, `references/tmux-reference.md` — format conventions
- User prompt patterns from `~/.claude/history.jsonl` — actual invocation phrases for brainstorm, work, simplify, review, slfg
