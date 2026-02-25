# Fleet Workflow Templates

**Date:** 2026-02-25
**Predecessor:** [[2026-02-23-fleet-modes-rethink-brainstorm]]

## What We're Building

Adding workflow awareness to the fleet captain — not as rigid runtime phases, but as knowledge the captain uses to construct better session prompts. Sessions receive a self-executing workflow in their initial prompt and run autonomously through phases. The captain monitors via existing signals (idle, picker, git events) and only intervenes on blockers.

Two workflows to start:
1. **Feature dev** — brainstorm → plan → work → simplify → review → PR
2. **Parallel audit** — fan-out N sessions for review/simplify/test across subsystems

## Why This Approach

The Feb 23 brainstorm correctly killed rigid modes and phase tracking. But the captain still constructs every spawn prompt from scratch. In practice, ~80% of spawns follow one of two patterns, and the captain reconstructs the same workflow instructions every time: "start with brainstorm, advance to plan, then work, then simplify via divide-and-conquer teams, then review against plan, then PR."

Workflow templates give the captain reusable prompt blueprints without reintroducing runtime phase state. The session prompt IS the workflow — no tracking infrastructure needed.

## Key Decisions

1. **Workflows are captain-side knowledge, not runtime state.** No new registry fields. No phase tracking. No events. The captain reads workflow reference docs to understand the patterns and constructs prompts accordingly.

2. **Everything stays prompt-driven.** No `--workflow` flag. The captain recognizes workflow patterns from natural language ("spawn a feature session for SSO login") and selects the appropriate template. The user can also be explicit ("use the feature workflow").

3. **Workflows are state machines with shortcuts, not linear pipelines.** The feature dev workflow has a canonical path (brainstorm → plan → work → simplify → review → PR) but allows shortcuts:
   - Brainstorm reveals small fix → skip plan, go straight to work
   - User says "just `/slfg` it" → compressed mode: work + simplify + review in one pass
   - Work reveals wrong assumptions → bounce back to brainstorm
   - Feature already has a plan doc → skip brainstorm, start at work

4. **Single session per feature.** The entire pipeline runs in one session that transitions through phases internally. No spawning separate sessions per phase. This preserves conversational context across the full lifecycle.

5. **Simplify uses divide-and-conquer teams within the session.** The session spawns team agents (via Task tool) for parallel simplification of different code areas, then advances to review after they finish. Not separate fleet sessions.

6. **Review matches implementation to plan/brainstorm.** The review phase cross-references the actual code changes against the original brainstorm doc and plan doc. Divergences are auto-fixed. The session is fully autonomous — the captain only intervenes on blockers.

7. **Feature dev always uses worktrees.** The captain always passes `--worktree` when spawning feature dev sessions.

8. **Separate reference files per workflow.** Each workflow lives in its own file under `references/` (e.g., `workflow-feature-dev.md`, `workflow-parallel-audit.md`). SKILL.md links to them via wikilinks. New workflows are added by creating new files.

9. **Captain infers progress from existing signals.** No new event types. The captain sees:
   - `idle` → phase likely completed, check status
   - `picker` / AskUserQuestion → session needs input, captain can relay or answer
   - `committed` / `pushed` → work is happening
   - `pr_created` → pipeline near completion

## Workflow Definitions

### Feature Dev

```
States: brainstorm | plan | work | simplify | review | pr | done

Canonical path:
  brainstorm → plan → work → simplify → review → pr → done

Allowed shortcuts:
  brainstorm → work       (small fix, plan not needed)
  plan → work             (brainstorm already done in prior session)
  work → simplify         (always — simplify is mandatory post-work)
  simplify → review       (always — review is mandatory post-simplify)
  [any] → brainstorm      (bounce-back when assumptions fail)

Compressed mode (/slfg):
  work → simplify → review → pr → done
  (skips brainstorm and plan, used when direction is already clear)

Entry points:
  - Natural: "build feature X" → starts at brainstorm
  - With plan: "implement docs/plans/..." → starts at work
  - Compressed: "/slfg" → starts at work
  - Bounce-back: mid-work realization → back to brainstorm
```

### Parallel Audit

```
Fan-out pattern:
  1. Captain determines subsystems to cover (from prompt or by asking)
  2. Spawns N parallel sessions, each scoped to one subsystem
  3. Each session runs autonomously (review/simplify/test depending on audit type)
  4. Each session creates its own PR with auto-merge
  5. Captain monitors for failures/blockers

Audit types:
  - review: deep code review, find and fix issues
  - simplify: code simplification loop
  - test: write tests for a subsystem

Naming: {audit-type}-{subsystem} (e.g., review-sync-engine, simplify-catalog)
```

## What the Reference Docs Contain

Each workflow reference doc (`references/workflow-*.md`) provides:

1. **State machine definition** — phases, allowed transitions, shortcuts
2. **Prompt template** — the actual text to embed in the session's initial prompt, with `{{description}}` placeholders. This is what makes the session self-executing.
3. **Phase instructions** — what each phase should do, what artifacts it produces, when to auto-advance
4. **Conventions** — artifact naming, worktree usage, PR creation, auto-merge rules
5. **Captain guidance** — what the captain should monitor for, when to intervene

## What Changes in SKILL.md

A new "Workflows" section is added with:
- Brief description of workflow awareness
- Wikilinks to each workflow reference doc
- Guidance on recognizing workflows from natural language prompts
- Guidance on when to use which workflow

## Resolved Questions

1. **Should the captain auto-advance or wait for approval?** Auto-advance. Sessions are maximally autonomous.
2. **Single session or separate sessions per phase?** Single session. Preserves context.
3. **How does simplify work in single-session model?** Session fans out team agents internally via Task tool.
4. **What happens on review divergence?** Auto-fix. Sessions are autonomous.
5. **How to trigger workflows?** Natural language prompts. No flags.
6. **Should sessions emit phase events?** No. Captain infers from idle/picker/git events.
7. **Where does workflow knowledge live?** Separate reference files per workflow, linked from SKILL.md via wikilinks.
