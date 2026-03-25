# Feature Work Workflow

> Captain's decision process for routing work requests. Determines whether to use a quick-fix track or a full feature pipeline, then constructs the spawn prompt accordingly.

## Decision Gate: Quick Fix or Feature?

Before spawning, classify the work:

| Signal | Track |
|--------|-------|
| < 3 files affected | Quick fix |
| Clear bug with obvious fix | Quick fix |
| Single function/method change | Quick fix |
| User says "just fix", "quick fix", "simple" | Quick fix |
| New functionality | Feature |
| Multiple components affected | Feature |
| Unclear solution requiring exploration | Feature |
| User says "build", "implement", "add feature" | Feature |
| Refactoring across multiple files | Feature |

- **Clearly quick fix:** proceed to Branch A.
- **Clearly feature work:** proceed to Branch B.
- **Ambiguous:** ask the user.

**Quick fixes can escalate.** A fix that looked simple may turn out to touch multiple components or reveal a deeper design issue. See "Escalation" below for how to handle this mid-session.

---

## Branch A — Quick Fix / Debug

Skip brainstorming and planning. Go straight to implementation.

### Step A1: Construct the Prompt

Use an objective-focused prompt:
- Describe the bug/issue and the desired outcome
- Point to affected code (file paths, error messages)
- Include any relevant context from previous sessions
- Direct the session to use `/ce:work`

**Do NOT include step-by-step instructions.** Describe the problem and goal — the agent figures out the approach.

### Step A2: Spawn the Session

Follow [[workflow-spawning]] — always `--worktree`, always background, include Forge + CI instructions.

### Step A3: Post-Completion Review

After the session pushes its fix:

1. Send a `/code-simplifier:code-simplifier` review instruction via `fleet send`:
   ```
   fleet send <name> "Run /code-simplifier:code-simplifier to review and clean up the changes you just made"
   ```
2. Wait for simplification to complete (session goes idle or reports done).

### Step A4: Submit and Monitor

1. Session submits PR through Forge (instructions were in the spawn prompt — see [[workflow-spawning]] Step 6).
2. Monitor with `/loop` or `fleet pr <name>` until merged.
3. On merge, follow [[workflow-killing]] to clean up.

**If Forge rejects:** see [[workflow-post-submission]] for resubmission.

---

## Branch B — Feature / Non-Trivial Work

Full pipeline: brainstorm → plan → work → review → simplify → submit → monitor.

### Step B1: Start with Brainstorming

Include `/ce:brainstorm` as the first phase in the spawn prompt. The session explores requirements, alternatives, and design before building.

### Step B2: Plan

After brainstorm, the session proceeds to `/ce:plan`. For high-risk or complex features, include `/deepen-plan` after the initial plan.

### Step B3: Implement

Session uses `/ce:work` with agent swarm for parallel implementation.

### Step B4: Code Review

After implementation, session runs `/ce:review` — cross-references implementation against the plan and brainstorm.

### Step B5: Simplify

After review findings are resolved, run `/code-simplifier:code-simplifier` for final cleanup.

### Step B6: Submit and Monitor

1. Session submits PR through Forge (instructions were in spawn prompt).
2. Monitor with `/loop` or `fleet pr <name>` until merged.
3. On merge, follow [[workflow-killing]] to clean up.

**If Forge rejects:** see [[workflow-post-submission]] for resubmission.

---

## Prompt Templates

### Quick Fix Spawn

```
Fix: {{description}}

Context: {{error_messages_or_context}}

Use /ce:work to implement the fix. After fixing, run tests to verify.

Then commit, push to branch worktree-{{name}}, and create a PR to main.

After the fix is pushed and PR created, run /code-simplifier:code-simplifier on your changes.

{{forge_submission_instructions}}
{{ci_ownership_instructions}}
```

### Feature Spawn

```
{{description}}

Since you are in an autonomous pipeline, skip all AskUserQuestion prompts and make decisions automatically.

/ce:brainstorm {{description}}

After brainstorm, proceed to planning:
/ce:plan (reference the brainstorm doc you just wrote)

After planning, implement using agent swarm — parallelize as much as possible:
/ce:work (reference the plan doc you just wrote)

After work is complete, review the implementation:
/ce:review — cross-reference against brainstorm and plan. Check for gaps, convention violations, code quality. Write findings to todos/.

After review, resolve all findings using subagents. P1 findings must be fixed before proceeding. If a finding can't be resolved after 3 attempts, escalate.

After resolving, verify: run the full test suite, typecheck, and build. Every check must pass.

After verification, run /code-simplifier:code-simplifier for final cleanup.

After cleanup, ship it: commit, push to branch worktree-{{name}}, and create a PR to main.

{{forge_submission_instructions}}
{{ci_ownership_instructions}}

Rules:
- Auto-advance through the full pipeline — do not stop between phases.
- If brainstorm reveals a small fix, skip plan and go straight to work.
- If assumptions prove wrong during work, bounce back to brainstorm.
- If a fix fails 3 times, stop thrashing and rethink architecturally.
```

## Escalation: Quick Fix → Feature

A quick fix can become a feature mid-session. Watch for these signals:

| Signal | What happened |
|--------|---------------|
| Session touches 5+ files | Scope grew beyond "quick fix" |
| Session bouncing between approaches | No obvious fix — needs brainstorming |
| Session has been working 3+ turns without converging | Problem is deeper than expected |
| Session asks captain for design decisions | Needs the brainstorm → plan pipeline |
| User says "this is getting complex" | User recognized the escalation |

When escalation is warranted:

### Step E1: Assess Existing Work

Run `fleet check <name>` to see what the session has done so far.

- **If useful progress exists (commits on branch):** don't throw it away.
- **If no commits yet:** the session can pivot in place.

### Step E2: Pivot or Respawn

- **Pivot in place:** Send the session a redirect via `fleet send`:
  ```
  fleet send <name> "This fix is more complex than expected. Stop the current approach. Start with /ce:brainstorm to explore the problem space, then /ce:plan before implementing."
  ```
- **Respawn fresh:** If the session has degraded (context-compacted, looping, or confused), kill it and spawn a new Branch B session. Reference the existing branch so work isn't lost:
  ```
  fleet spawn <new-name> <repo> "<feature prompt with Branch B template>" --worktree --branch <existing-branch>
  ```

- **Pivot in place if:** session is coherent and has useful context loaded.
- **Respawn if:** session has context-compacted, is looping, or has gone off track.

## Success Criteria

- [ ] Correct track selected (quick fix vs feature)
- [ ] Session spawned via [[workflow-spawning]]
- [ ] Post-work review completed (simplifier for quick fix, full review chain for feature)
- [ ] PR submitted through Forge
- [ ] Monitoring active until merged
