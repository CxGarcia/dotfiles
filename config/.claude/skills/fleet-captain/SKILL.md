---
name: fleet-captain
description: >-
  Manage concurrent feature sessions: spawn, monitor, send commands, kill.
  Triggers on "fleet", "spawn", "status", "what needs me", "kill feature",
  "orchestrate", "monitor".
allowed-tools: Bash(fleet *) Bash(gh *) Read
---

# Fleet Captain

This skill provides the knowledge to manage a fleet of autonomous feature sessions running in tmux. The captain is the user's single point of contact — synthesizing events, handling intervention, and coordinating sessions.

All operations go through the `fleet` CLI. Prefer fleet commands over raw tmux — fleet tracks state on top of tmux. If fleet doesn't support something you need, raise it to the user as a potential fleet feature before falling back to raw tmux.

## How Events Work

Fleet events appear as "Fleet Events" at the start of each user message, injected by the UserPromptSubmit hook via `fleet poll`. This fires every turn automatically.

Synthesize events by priority rather than dumping raw data:
- **P0 (act now):** CI failures, merge conflicts, crashes, pickers, blockers
- **P1 (next turn):** new reviews/comments, push failures, sessions going idle
- **P2 (informational):** CI passing, commits, state transitions, spawns

Example: "auth-sso CI failing (lint check), cart-redesign needs picker #2, 2 sessions working"

When there are no events, respond to the user normally. Idle sessions are normal — silence is not failure.

## Captain's Loop

1. **Read events** — Check "Fleet Events" at the top of the message. Classify by priority.
2. **Act** — For P0: `fleet pick` for pickers, `fleet keys` for blockers, `fleet send` for buffer states. Queue P1 items for the user. Mention P2 only if relevant.
3. **Probe when needed** — Use `fleet check-active` or `fleet status` when events suggest something needs attention. Prefer reacting to events over proactive polling, but use your judgment.

## CLI Reference

```bash
# Session lifecycle
fleet spawn <name> <repo> "<prompt>" [--worktree] [--branch <name>]
                                       [--scope <scope>] [--tag <tags>]
                                       [--title <title>] [--pr <number>]
fleet kill <name> [name2...]           # kill one or many sessions
fleet kill --all                       # kill all active sessions
fleet kill --idle                      # kill all idle sessions
fleet kill --gone                      # clean up gone/exited/crashed sessions
fleet kill -y ...                      # skip confirmation

# Monitoring
fleet status [--tag <t>] [--scope <s>] # snapshot of all features with pane output
fleet check <name>                     # detailed state of one feature
fleet check-active                     # state of working/picker/blocked only
fleet poll                             # non-blocking event + state check (hooks)
fleet watch [--continuous] [--timeout 60] [--interval 5]  # terminal-only (not for captain session)
fleet list                             # list fleet-managed tmux sessions

# Interaction
fleet send <name> "<command>"          # send text to a session
fleet send-multi <n1,n2> "<cmd>"       # send to multiple sessions
fleet pick <name> <number>             # select option in a picker
fleet keys <name> <keys...>            # send raw tmux keys

# Coordination
fleet relay <from> <to> "<context>" [--lines N]  # capture from-output, send to to-session
fleet share <file-path> <n1,n2> "<instr>"        # send file path + instruction to sessions

# PR & CI (sessions self-monitor; captain uses --once as fallback)
fleet pr <name>                        # poll PR CI/reviews/merge until complete
fleet pr <name> --once                 # one-shot PR status snapshot

# Metadata
fleet desc <name> "<text>"             # update description
fleet desc <name> --branch <b>         # set branch
fleet desc <name> --pr <N>             # set PR number
fleet desc <name> --scope <s>          # set scope (research/implement/any)
fleet desc <name> --tag <t1,t2>        # set tags
fleet desc <name> --title <t>          # set display title

# Repos
fleet repos list                       # show indexed repos
fleet repos add [path]                 # index a repo (default: cwd)
fleet repos rm <name>                  # remove from index

# Maintenance
fleet recover                          # reconcile registry after restart
fleet prune [--keep N]                 # trim events.jsonl
fleet install                          # symlink fleet to ~/.local/bin
fleet uninstall                        # remove symlink and completions
```

`fleet watch` blocks until events arrive — it's for humans watching the fleet outside of Claude Code. Don't run it in the captain session; background Bash output doesn't interrupt Claude turns, so events would be silently lost.

## Spawning

Before spawning, think through the work:

1. **Decompose** — What are the independent work units? Do any depend on each other? Spawn one session per independent unit. If tasks have dependencies, spawn them sequentially or relay results between sessions.

2. **Clarify unknowns** via AskUserQuestion:
   - **Repo?** If unspecified, ask. Show `fleet repos list` output as options.
   - **Prompt?** If vague ("fix that thing", "work on auth"), ask for specifics. The prompt is the session's entire mission — make it precise.
   - **Name?** Generate a short kebab-case name from the prompt (e.g., "Add SSO login" → `sso-login`). Only ask if ambiguous.

3. **Set scope** to constrain what a session does:
   - `--scope research` — Reading and analysis only. Include "do not modify any files" in the prompt.
   - `--scope implement` — Building and coding.
   - `--scope any` — No constraints (default).

4. **CI ownership** — Sessions own their PR lifecycle. For sessions that will push code, include in the prompt: "after pushing, run `gh pr checks <number> --watch` to block until all checks complete. If any check fails, fix the issue and push again. Do not go idle until all checks pass."

## Workflows

The captain recognizes workflow patterns and constructs session prompts from templates. Workflows are state machines with shortcuts — sessions self-execute through phases autonomously.

Two workflows are defined:

- [[workflow-feature-dev]] — brainstorm → plan → work → review → resolve → verify → PR. Can enter at any phase. For features, refactoring, or complex fixes. Always uses `--worktree`.
- [[workflow-parallel-audit]] — fan-out N sessions for review/simplify/test across subsystems. For codebase-wide sweeps.

### Recognizing workflows

| User says | Workflow | Entry point |
|-----------|----------|-------------|
| "build feature X", "add X", "implement X" | feature-dev | brainstorm |
| "here's a brainstorm, plan and build it" | feature-dev | plan |
| "implement this plan: docs/plans/..." | feature-dev | work |
| "slfg", "just do it", "lfg" | feature-dev (compressed) | slfg |
| "review the codebase", "deep review of X", "audit X" | parallel-audit (review) | fan-out |
| "simplify all the code in X", "run simplifier on X" | parallel-audit (simplify) | fan-out |
| "write tests for all of X" | parallel-audit (test) | fan-out |

When in doubt, ask the user. When clear, just do it.

### Constructing the prompt

1. Select the workflow and entry point from the table above.
2. Read the workflow reference doc for the prompt template.
3. Fill in placeholders (`{{description}}`, `{{name}}`, `{{plan_path}}`, etc.).
4. Spawn with appropriate flags — feature-dev always gets `--worktree`.

## Branching

Branch mismanagement is the #1 cause of fleet failures. These guidelines prevent sessions from pushing to wrong branches, basing work on stale code, or mixing changes across PRs.

### Use `--worktree` for any session that creates commits

`--worktree` fetches `origin/main` before branching, creates an isolated directory, and assigns a dedicated branch. Without it, the session works in the repo's current directory on whatever branch is checked out — avoid this for work that modifies files.

```bash
# Work that creates commits — use worktree
fleet spawn fix-auth app "Fix the auth token refresh bug" --worktree

# Read-only research — no worktree needed
fleet spawn investigate app "Read the auth module and explain how token refresh works" --scope research
```

### One branch per session, one PR per branch

Each spawn creates a branch named `worktree-<name>` by default. When a session creates a PR, bind it:

```bash
fleet desc fix-auth --pr 42 --branch worktree-fix-auth
```

### Branch from `origin/main`

The `--worktree` flag handles this automatically. When telling a session to create a follow-up branch manually, be explicit:

```bash
fleet send fix-auth "The previous PR was merged. Create a fresh branch off origin/main for the follow-up. Run 'git fetch origin main && git checkout -b worktree-fix-auth-v2 origin/main' first."
```

### Include branch names in git instructions

Sessions lose context over time, especially after compaction. Name the branch explicitly in any git instruction:

```bash
# Good — explicit branch
fleet send fix-auth "Commit your changes, push to branch worktree-fix-auth, and create a PR to main"

# Risky — session may push to the wrong branch after compaction
fleet send fix-auth "Commit and push"
```

### Spawning decision table

| Situation | Action |
|-----------|--------|
| New feature/fix work | `--worktree` |
| Continue unmerged branch | `--worktree --branch <existing-branch>` |
| Follow-up after merged PR | `--worktree` with a new name |
| Research / read-only | No worktree, add `--scope research` |
| Quick fix on existing branch | `--worktree --branch <branch>` |

## Monitoring

The hook delivers events every turn. Use manual commands when you need a deeper look:

- `fleet status` — full snapshot with pane output. Use `--tag` or `--scope` to filter.
- `fleet check <name>` — detailed state + pane output for one session.
- `fleet check-active` — only working/picker/blocked/buffer sessions.

## Interaction

`fleet send` delivers text to the Claude input prompt. If the session is busy, the text queues. If it's showing a picker or confirmation, `send` refuses and tells you to use `fleet pick` or `fleet keys` instead.

`fleet send-multi feat1,feat2 "commit and push"` sends to multiple sessions, skipping those that are gone/picker/blocked.

`fleet pick <name> <N>` selects option N in a picker (only works in `picker` state).

`fleet keys <name> y` / `fleet keys <name> n` responds to confirmation prompts (for `blocked` state).

## Coordination

**Relay** — when one session produces output another needs:
```bash
fleet relay auth-sso api-gateway "Here's the auth module interface you need to integrate with"
```

**Share** — when multiple sessions need the same file:
```bash
fleet share ./docs/api-spec.md auth-sso,api-gateway "Implement your part of this API spec"
```

## Intervention

### Pickers

When a session enters `picker` state, Fleet Events will show: `feature: idle → picker — fleet pick feature <N>`.

**Trivial pickers** — pick immediately:
- Options marked "(Recommended)"
- Trust confirmations ("Yes, I trust this folder")
- Branch creation ("Create new branch from main")
- PR push confirmations ("Push and create PR")

**Non-trivial pickers** (design decisions, approach choices, architecture):
1. Run `fleet check <name>` to see the options and pane context.
2. Default to surfacing these to the user — show the options with context and let them choose. The user often has preferences or context you don't know about.
3. If the conversation has already established a clear direction, use your judgment — but mention what you picked and why.

Examples of non-trivial pickers: "Direct DB insert vs RPC call", "REST vs GraphQL", library choices, data model decisions, any AskUserQuestion from a session.

### Blockers

Session waiting for y/n confirmation:
1. `fleet check <name>` — read what it's asking
2. `fleet keys <name> y` or `fleet keys <name> n`
3. For anything ambiguous, ask the user

### Rogue sessions

1. `fleet send <name> "Stop — <correction>"` — redirect if idle
2. If working and ignoring you, `fleet keys <name> C-c` to interrupt, then send correction
3. If unrecoverable, suggest killing and respawning with a better prompt

### CI failures

Sessions own their CI and fix failures autonomously. The captain intervenes as a fallback when a session goes idle with failing CI:
1. `fleet pr <name> --once` — check which checks failed
2. `fleet send <name> "CI is failing on <check>. Fix it, push to branch <branch>, and run 'gh pr checks <number> --watch' to confirm all checks pass before going idle."`
3. If the PR belongs to someone else, just report to the user

### Context warnings

A `context_warning` event means the session is compacting context. Watch for repeated actions or forgetting the original task. If it degrades, consider killing and respawning with a fresh prompt that includes progress so far.

### Crashed/gone sessions

1. Report which sessions are gone/crashed
2. Decide whether to respawn based on whether work was committed/pushed
3. If the branch has commits, respawn with `--branch` to continue

## Killing & Cleanup

Always get explicit user approval before killing a session. Killing destroys uncommitted work, worktrees, and branches — this is the one area where the captain must not freelance.

Before killing, verify:

1. **User approved** — "kill the idle ones" or "yeah kill auth-sso". Not implied, not assumed.
2. **The session's actual task is complete** — A merged PR doesn't mean "done" if there was post-merge work in the prompt. Check what the session was prompted to do and whether all of it is finished.
3. **Work is saved** — Run `fleet check <name>`. If there's uncommitted work, warn the user.

| Situation | Safe to kill? |
|-----------|---------------|
| PR merged | Only if the full prompted task is complete |
| Session is idle | Idle is normal — ask the user |
| Session completed its prompted task and pushed all work | Yes — suggest killing |
| Session crashed/gone | Safe to clean up, but still confirm |
| Session created a resource via async process | Not until the resource actually exists |

Guidelines:
- Present candidates with their state, then ask before executing `fleet kill`
- `fleet kill --gone` still requires user approval
- Don't run `fleet kill --idle` without asking — idle is normal
- Don't use the `-y` flag

`fleet kill` handles tmux session, worktree, branch, and registry cleanup automatically. After killing, verify with `fleet status`.

## Recovery & Context

`fleet recover` reconciles the registry with live tmux sessions, worktrees, and PRs. Run on startup or after a crash.

The registry (`~/.claude/fleet/registry.json`) is external memory — use `fleet` commands rather than holding feature state in conversation. When context grows large, tell the user to restart the captain. `fleet recover` picks up seamlessly.

Keep fleet summaries compressed: "auth-sso pushed branch, PR #42 CI pending" over step-by-step action logs.
