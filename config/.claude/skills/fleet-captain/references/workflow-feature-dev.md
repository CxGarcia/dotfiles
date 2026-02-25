# Feature Dev Workflow

Autonomous pipeline for building features. A single session advances through phases, producing artifacts at each step. The captain constructs the spawn prompt from the appropriate template below.

## State Machine

| Phase | Does | Produces | Next |
|-------|------|----------|------|
| brainstorm | `/workflows:brainstorm` — explores what to build | `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md` | plan, or work (shortcut) |
| plan | `/workflows:plan` — designs how to build it | `docs/plans/YYYY-MM-DD-<type>-<topic>-plan.md` | work |
| work | `/workflows:work` with swarm — implements | Code changes on branch | review |
| review | `/workflows:review` against plan/brainstorm — verifies correctness, quality, and cleanliness | Findings in `todos/`, auto-fixed divergences | resolve |
| resolve | Address all review findings using subagents | Fixed code | verify |
| verify | Run tests, typecheck, build — confirm resolve didn't break anything | Green suite | pr |
| pr | Commit, push, create PR, monitor CI | Merged PR | done |

### Shortcuts

| Shortcut | When |
|----------|------|
| brainstorm → work | Brainstorm reveals the fix is small, plan not needed |
| Entry at plan | Brainstorm already exists from a prior session |
| Entry at work | Plan already exists |
| `/slfg` mode | Direction is clear, skip brainstorm + plan entirely |
| Any → brainstorm | Assumptions prove wrong mid-work (bounce-back) |

## Prompt Templates

The captain selects the entry point based on context (see recognition table in SKILL.md), fills in placeholders, and passes the result as the spawn prompt.

### Entry: brainstorm (full pipeline)

Use when the user requests a new feature with no existing brainstorm or plan.

```
/workflows:brainstorm {{description}}

After the brainstorm doc is written, immediately proceed to planning. Since you are in an autonomous pipeline, skip all AskUserQuestion prompts and make decisions automatically:
/workflows:plan (reference the brainstorm doc you just wrote)

After the plan is written, immediately proceed to work. Make a Task list and launch an army of agent swarm subagents to build the plan. Use teams of agents to divide and conquer — parallelize as much as possible:
/workflows:work (reference the plan doc you just wrote)

After work is complete, do a deep review of the implementation:
/workflows:review — cross-reference the implementation vs the brainstorm and plan to make sure we are solving the issue properly, not missing any gaps, and following code conventions. Also review for code quality and cleanliness: established architecture (api > service > repo), reuse of existing functionality, naming, dead code. Have each review agent write their findings to todos/ so nothing is lost to context compaction.

After review, resolve all findings:
Address ALL review findings. Use subagents to divide and conquer — give each a proper slice of findings to handle. Auto-fix divergences from the plan. P1 findings must be fixed before proceeding. If a finding can't be resolved after 3 attempts, escalate to the captain for a design decision or bounce back to brainstorm.

After resolving, verify everything still works:
Run the full test suite, typecheck, and build. ALL must pass before proceeding. Do not trust that resolve kept things green — verify fresh.

After verification passes, ship it:
Commit all changes, push to branch worktree-{{name}}, and create a PR to main. After pushing, run `gh pr checks` to monitor CI and fix any failures.

RULES:
- Do NOT stop between phases — auto-advance through the full pipeline.
- If brainstorm reveals a small fix, skip plan and go straight to work.
- If assumptions prove wrong during work, bounce back to brainstorm.
- If a fix fails 3 times, STOP thrashing and rethink the approach architecturally.
- Before claiming any phase is complete, run verification (tests, build) and confirm the output.
```

### Entry: plan (brainstorm exists)

Use when the user references an existing brainstorm doc.

```
Since you are in an autonomous pipeline, skip all AskUserQuestion prompts and make decisions automatically:
/workflows:plan {{brainstorm_path}}

After the plan is written, immediately proceed to work. Make a Task list and launch an army of agent swarm subagents to build the plan. Use teams of agents to divide and conquer — parallelize as much as possible:
/workflows:work (reference the plan doc you just wrote)

After work is complete, do a deep review of the implementation:
/workflows:review — cross-reference the implementation vs the brainstorm and plan to make sure we are solving the issue properly, not missing any gaps, and following code conventions. Also review for code quality and cleanliness: established architecture (api > service > repo), reuse of existing functionality, naming, dead code. Have each review agent write their findings to todos/ so nothing is lost to context compaction.

After review, resolve all findings:
Address ALL review findings using subagents to divide and conquer. P1 findings must be fixed before proceeding. If a finding can't be resolved after 3 attempts, escalate to the captain for a design decision or bounce back to brainstorm.

After resolving, verify everything still works:
Run the full test suite, typecheck, and build. ALL must pass before proceeding.

After verification passes, ship it:
Commit all changes, push to branch worktree-{{name}}, and create a PR to main. After pushing, run `gh pr checks` to monitor CI and fix any failures.

RULES:
- Do NOT stop between phases.
- If a fix fails 3 times, STOP and rethink the approach.
- Before claiming any phase is complete, run verification and confirm the output.
```

### Entry: work (plan exists)

Use when the user references an existing plan doc.

```
Make a Task list and launch an army of agent swarm subagents to build the plan. Use teams of agents to divide and conquer — parallelize as much as possible:
/workflows:work {{plan_path}}

After work is complete, do a deep review of the implementation:
/workflows:review — cross-reference the implementation vs the plan and any linked brainstorm doc to make sure we are solving the issue properly, not missing any gaps, and following code conventions. Also review for code quality and cleanliness: established architecture (api > service > repo), reuse of existing functionality, naming, dead code. Have each review agent write their findings to todos/ so nothing is lost to context compaction.

After review, resolve all findings:
Address ALL review findings using subagents to divide and conquer. P1 findings must be fixed before proceeding. If a finding can't be resolved after 3 attempts, escalate to the captain for a design decision or bounce back to brainstorm.

After resolving, verify everything still works:
Run the full test suite, typecheck, and build. ALL must pass before proceeding.

After verification passes, ship it:
Commit all changes, push to branch worktree-{{name}}, and create a PR to main. After pushing, run `gh pr checks` to monitor CI and fix any failures.

RULES:
- Do NOT stop between phases.
- If a fix fails 3 times, STOP and rethink the approach.
- Before claiming any phase is complete, run verification and confirm the output.
```

### Entry: slfg (compressed)

Use when the user says "slfg", "lfg", or "just do it" with a clear description or plan reference.

```
/slfg {{description_or_plan_path}}
```

The `/slfg` skill handles the full pipeline internally: plan → deepen → work (swarm) → review + test-browser (parallel) → resolve todos → feature-video.

## Conventions

- Always spawn with `--worktree` — feature dev sessions must have isolated branches.
- Naming: kebab-case from the feature description (e.g., `sso-login`, `connector-icons`).
- Scope: leave as default (`any`) — the session manages its own phases.
- CI: sessions self-monitor after PR creation.

## Captain Guidance

| Signal | Meaning | Action |
|--------|---------|--------|
| `picker` during brainstorm | AskUserQuestion — session needs design input | Read via `fleet check`, decide or ask user, respond via `fleet pick` |
| `picker` during plan/work | AskUserQuestion — should be skipped in pipeline mode | If stuck, `fleet send` telling session to make the decision autonomously |
| `idle` after work phase | May have finished work but not started review | Check pane output. Nudge with `fleet send` if stuck |
| `context_warning` | Session compacting, may lose coherence | Watch for repeated actions. If degraded: kill, respawn at current phase with `--branch` |
| `idle` after PR created | Pipeline complete | Verify PR exists, bind with `fleet desc --pr`, then `fleet kill` |
| `idle` with failing CI | Session missed CI failure | `fleet pr <name> --once`, then `fleet send` with fix instruction |
| Session thrashing (3+ failed fixes) | Wrong approach, not wrong code | `fleet send` telling session to stop and rethink architecturally |
