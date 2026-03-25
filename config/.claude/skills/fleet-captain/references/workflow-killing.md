# Killing Workflow

> Captain procedure for killing sessions. Always background, always confirm with user first.

## Hard Rules

- **ALWAYS run `fleet kill` in background** (`run_in_background: true`). Worktree cleanup is slow.
- **ALWAYS use `-y` flag** to skip the CLI's interactive confirmation prompt.
- **Captain MUST ask the user before killing.** The `-y` bypasses the CLI prompt, not the user — that's the captain's responsibility.

## Procedure

### Step 1: Identify Kill Candidates

Determine which sessions to kill. Sources:

- **User explicitly names sessions:** "kill auth-sso"
- **User describes a category:** "kill the idle ones", "clean up finished sessions"
- **Captain observes done sessions:** PR merged, task complete, session gone/crashed

### Step 2: Verify Each Candidate

For each candidate, run `fleet check <name>` and assess:

| Check | How to verify |
|-------|---------------|
| Work saved? | Branch has commits, PR exists, or no file changes made |
| Task complete? | Full prompted task is done — "PR merged" alone isn't enough if post-merge work was in the prompt |
| Uncommitted changes? | Worktree has unstaged/staged changes |

**If uncommitted work exists:** warn the user before proceeding. Do not kill silently.

### Step 3: Present Candidates to User

Show the user a summary:

```
Kill candidates:
- auth-sso: PR #42 merged, task complete, worktree clean
- cart-api: idle for 5 turns, no commits, no PR
- old-debug: session gone/crashed, branch has 3 commits
```

**Wait for explicit user approval.** Do not proceed without it.

- **User approves all:** proceed to Step 4.
- **User approves some:** kill only the approved sessions.
- **User says no:** stop.

### Gate: User Approval

Before running `fleet kill`:
- [ ] User has explicitly approved killing the named sessions
- [ ] All candidates verified for saved work
- [ ] Uncommitted work warnings delivered (if any)

**If any check fails:** do not kill. Present the blocker to the user.

### Step 4: Execute the Kill

Run `fleet kill` with `-y` in background:

```bash
fleet kill <name1> [name2...] -y
```

Use `run_in_background: true` on the Bash tool call.

- **Bulk cleanup:** `fleet kill --gone -y` for crashed/exited sessions (still requires user approval first).
- **Kill all:** `fleet kill --all -y` — only on explicit user request.

**If kill fails:**
- **Session already gone:** `fleet kill --gone -y` to clean the registry.
- **Worktree locked:** inform the user — manual cleanup may be needed.

### Step 5: Verify Cleanup

After the background kill completes, run `fleet status` to confirm sessions are removed.

**If sessions persist:** report to user. May need `fleet recover` to reconcile state.

## Decision Table

| Situation | Safe to kill? | Action |
|-----------|---------------|--------|
| PR merged, full task complete | Yes | Suggest killing, wait for approval |
| PR merged, post-merge work pending | No | Inform user of remaining work |
| Session idle | Maybe | Ask user — idle is normal |
| Session completed task, pushed all work | Yes | Suggest killing, wait for approval |
| Session crashed/gone | Safe to clean up | Still confirm with user |
| Session has uncommitted changes | Risky | Warn user explicitly |

## Success Criteria

- [ ] User approved every kill
- [ ] No uncommitted work lost without warning
- [ ] `fleet status` confirms sessions removed
- [ ] Worktrees cleaned up
