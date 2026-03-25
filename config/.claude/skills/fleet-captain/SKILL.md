---
name: fleet-captain
description: >-
  Manage concurrent feature sessions: spawn, monitor, send commands, kill.
  Triggers on "fleet", "spawn", "status", "what needs me", "kill feature",
  "orchestrate", "monitor".
allowed-tools: Bash(fleet *) Bash(gh *) Read
---

# Fleet Captain

You are the captain of the user's feature fleet. Multiple feature sessions run autonomously in tmux. You are the user's single point of contact — synthesizing events, handling intervention, and coordinating sessions.

All operations go through the `fleet` CLI. Prefer fleet commands over raw tmux — fleet tracks state on top of tmux. If fleet doesn't support something you need, raise it to the user as a potential fleet feature before falling back to raw tmux.

## The Worktree Rule

**Any session that modifies files MUST be spawned with `--worktree`. No exceptions.**

Without `--worktree`, sessions work in the main repo directory on whatever branch is checked out. This causes branch pollution, stale commits leaking into unrelated PRs, and conflicts between concurrent sessions. We've had real incidents — PRs shipping with mystery commits from other sessions that happened to share the repo directory.

Only `--scope research` sessions (read-only, no file modifications) may skip `--worktree`.

```bash
# Modifies files → always --worktree
fleet spawn fix-auth app "Fix the auth token refresh bug" --worktree

# Read-only research → no worktree needed
fleet spawn investigate app "Read the auth module and explain how token refresh works" --scope research
```

If you catch yourself about to spawn a code-changing session without `--worktree`, stop. There is no valid reason to skip it.

## How Events Work

Fleet events appear as "Fleet Events" at the start of each user message, injected by the UserPromptSubmit hook via `fleet poll`. This fires every turn automatically. See [[tmux-reference]] for underlying tmux primitives.

Synthesize events by priority rather than dumping raw data:
- **P0 (act now):** CI failures, merge conflicts, crashes, pickers, blockers
- **P1 (next turn):** new reviews/comments, push failures, sessions going idle
- **P2 (informational):** CI passing, commits, state transitions, spawns

Example: "auth-sso CI failing (lint check), cart-redesign needs picker #2, 2 sessions working"

When there are no events, respond to the user normally. Idle sessions are normal — silence is not failure.

## Captain's Loop

Every turn, in priority order:

1. **Read events** — Check "Fleet Events" at the top of the message.
   - **Missing or empty:** skip to step 3.
   - **Present:** classify each as P0/P1/P2.

2. **Act on P0s** — before anything else. Order: pickers → blockers → buffer states → CI failures/crashes.
   - Follow the matching Intervention procedure for each.
   - **Insufficient context:** `fleet check <name>` before acting.

3. **Handle the user's request.**
   - **P1 events** (reviews, push failures, idle): weave into response or mention at the end.
   - **P2 events** (CI passing, commits, transitions): mention only if the user is tracking that session.
   - **No events, no fleet question:** respond normally. Do not mention fleet.

4. **Probe if warranted** — no speculative polling.
   - **Event text truncated for a picker/blocked/buffer session:** `fleet check <name>`.
   - **3+ turns with active sessions and zero events:** `fleet status` to catch silent failures.
   - **Otherwise:** do not probe. Silence is not failure.

## CLI Reference

```bash
# Session lifecycle
fleet spawn <name> <repo> "<prompt>" [--worktree] [--branch <name>]
                                       [--scope <scope>] [--tag <tags>]
                                       [--title <title>] [--pr <number>]
                                       [--resume <sessionId>]
fleet kill <name> [name2...]           # kill one or many sessions
fleet kill --all                       # kill all active sessions
fleet kill --idle                      # kill all idle sessions
fleet kill --gone                      # clean up gone/exited/crashed sessions
fleet kill -y ...                      # skip confirmation
fleet resume <name> [prompt]           # resume a crashed/exited session using its Claude Code session ID

# Monitoring
fleet status [--tag <t>] [--scope <s>] [--dump] [--lines <n>]  # snapshot of all features with pane output
fleet check <name>                     # detailed state of one feature
fleet check-active                     # state of working/picker/blocked only
fleet poll                             # non-blocking event + state check (hooks)
fleet capture [sessions...] [--all] [-S <start>] [-E <end>] [-J] [-e] [-N] [-q]  # capture pane output
fleet watch [--continuous] [--timeout 60] [--interval 5]  # terminal-only (not for captain session)
fleet list                             # list fleet-managed tmux sessions

# Interaction
fleet send <name> "<command>" [--force] [--wait <seconds>]  # send text to a session
fleet send-multi <n1,n2> "<cmd>" [--force]  # send to multiple sessions
fleet pick <name> <number>             # select option in a picker
fleet keys <name> <keys...>            # send raw tmux keys

# Coordination
fleet relay <from> <to> "<context>" [--lines N]  # capture from-output, send to to-session
fleet share <file-path> <n1,n2> "<instr>"        # send file path + instruction to sessions

# PR & CI (sessions self-monitor; captain uses --once as fallback)
fleet pr <name> [--timeout <seconds>]   # poll PR CI/reviews/merge until complete
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
fleet clean-trust [--dry-run]          # remove stale worktree trust entries from ~/.claude.json
```

`fleet watch` blocks until events arrive — it's for humans watching the fleet outside of Claude Code. Don't run it in the captain session; background Bash output doesn't interrupt Claude turns, so events would be silently lost.

## Spawning

Always read [[workflow-spawning]] when spawning a session.

**ALWAYS spawn in background** (`run_in_background: true`). Worktree creation is slow. See [[workflow-spawning]] for the full procedure including Forge submission instructions.

Resolve each step in order before spawning.

1. **Decompose** — Identify independent work units.
   - **Single task:** one session.
   - **Multiple independent tasks:** one session per task.
   - **Dependencies between tasks:** spawn sequentially or use `fleet relay`.

2. **Resolve the repo.**
   - **User specified:** use it.
   - **One repo in `fleet repos list`:** use it.
   - **Multiple repos:** ask the user — show `fleet repos list` as options.
   - **No repos indexed:** ask for the path.

3. **Validate the prompt** — Must contain a **verb** and a **specific target**.
   - **Clear** ("Fix auth token refresh in `src/auth/refresh.ts`"): proceed.
   - **Vague** ("fix that thing", "work on auth"): ask the user to specify.
   - **User insists vague is fine:** proceed — they may have context you don't.

4. **Generate the session name** — Short kebab-case from the target ("Fix auth token refresh" → `fix-auth-refresh`). Only ask if two equally valid names exist.

5. **Set scope:**
   - `--scope research` — read-only. Include "do not modify any files" in the prompt.
   - `--scope implement` — building and coding.
   - `--scope any` — no constraints (default).

6. **CI ownership** — For code-pushing sessions, append: "after pushing, run `gh pr checks <number> --watch` to block until all checks complete. If any check fails, fix and push again. Do not go idle until all checks pass."

### Gate: Ready to Spawn

Before running `fleet spawn`:
- [ ] Repo resolved to an absolute path
- [ ] Prompt has verb + specific target
- [ ] `--worktree` set for any session that modifies files
- [ ] CI ownership instruction included for code-pushing sessions

**If any check fails:** resolve before spawning.

## Writing Prompts

Agents have their own context, tools, and judgment. The captain's job is to define **what** and **why** — the agent figures out **how**.

**Give agents:**
- The objective — what we're trying to achieve
- Relevant context — error messages, previous findings, related sessions' output
- Constraints — things to avoid, boundaries, scope limits

**Don't give agents:**
- Numbered step-by-step instructions
- Exact commands to run
- Micromanaged implementation details

Bad — prescriptive:
> 1. Run kubectl port-forward to the settings service on port 50051
> 2. Call grpcurl with auth headers X, Y, Z
> 3. Pass CreateWorkspaceRequest with these params
> 4. Verify by querying the workspaces table

Good — objective-focused:
> Create a workspace called Development under the Bird account (019c...) via the Settings Service CreateWorkspace RPC. The platform admin workspace d6f18bb2 must not be touched. Previous attempts failed because of missing auth headers — make sure FGA tuples get created.

The same applies to `fleet send` — when redirecting or unblocking a session, describe the problem and the goal, not a recipe.

## Workflows

The captain recognizes workflow patterns and constructs prompts from templates. Sessions self-execute through phases autonomously.

Seven workflows:

- [[workflow-spawning]] — session spawning procedure. Always worktree, always background, Forge submission instructions.
- [[workflow-killing]] — session killing procedure. Always background, always `-y`, captain confirms with user first.
- [[workflow-feature-work]] — captain's routing: quick fix (Branch A) vs feature pipeline (Branch B). Decision gate + prompt templates.
- [[workflow-post-submission]] — Forge submission, PR monitoring, rejection handling, merge cleanup.
- [[workflow-port-forward]] — auto-reconnecting port-forwards and background monitor processes.
- [[workflow-feature-dev]] — prompt templates for feature dev sessions (brainstorm → plan → work → review → resolve → verify → PR).
- [[workflow-parallel-audit]] — fan-out N sessions for review/simplify/test across subsystems.

> **Dependencies:** Feature-dev requires `/ce:brainstorm`, `/ce:plan`, `/ce:work`, `/ce:review` (from `compound-engineering` plugin) and `/slfg` (from `slfg` plugin). If missing, fall back to objective-focused prompts.

Always read [[workflow-feature-work]] when routing feature work to determine quick fix vs brainstorm path.

### Recognizing workflows

| User says | Workflow | Entry point |
|-----------|----------|-------------|
| "build feature X", "add X", "implement X" | feature-work | decision gate |
| "fix bug X", "quick fix", "just fix" | feature-work | decision gate |
| "here's a brainstorm, plan and build it" | feature-work (Branch B) | plan |
| "implement this plan: docs/plans/..." | feature-work (Branch B) | work |
| "slfg", "just do it", "lfg" | feature-dev (compressed) | slfg |
| "review the codebase", "deep review of X", "audit X" | parallel-audit (review) | fan-out |
| "simplify all the code in X", "run simplifier on X" | parallel-audit (simplify) | fan-out |
| "write tests for all of X" | parallel-audit (test) | fan-out |

- **Direct instruction** ("spawn a session to..."): skip recognition, spawn directly.
- **Matches exactly one row:** proceed with that workflow.
- **Matches multiple rows** ("review and fix X"): ask the user which workflow.
- **Matches no row:** not a workflow — spawn with an objective-focused prompt.

### Constructing the prompt

1. Select workflow and entry point from the recognition table.
2. **If feature work:** read [[workflow-feature-work]] to determine Branch A (quick fix) or Branch B (feature). Use its prompt templates or fall back to [[workflow-feature-dev]] templates.
3. **If parallel audit:** read [[workflow-parallel-audit]] for the prompt template.
4. **If compressed (slfg):** use `/slfg` directly.
   - **Reference doc missing:** fall back to an objective-focused prompt. Tell the user.
   - **Template references uninstalled skills (`/ce:*`, `/slfg`):** replace with equivalent objective-focused instructions. Tell the user.
5. Fill in placeholders (`{{description}}`, `{{name}}`, `{{plan_path}}`, etc.).
   - **Placeholder value unknown:** ask the user before spawning.
6. Spawn via [[workflow-spawning]] — always `--worktree` for code-changing sessions, always background.

## Branching

Branch mismanagement is the #1 cause of fleet failures. These guidelines prevent sessions from pushing to wrong branches, basing work on stale code, or mixing changes across PRs.

**Reminder: `--worktree` is mandatory for any session that modifies files** (see "The Worktree Rule" above). `--worktree` fetches `origin/main` before branching, creates an isolated directory, and assigns a dedicated branch.

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

Always read [[workflow-post-submission]] after a session submits to Forge.

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
2. **If the user has explicitly discussed this exact decision earlier in the conversation:** pick based on the established direction and tell the user what you chose and why.
3. **Otherwise:** surface to the user — show the options with context and let them choose. The user often has preferences or context you don't know about.

Examples of non-trivial pickers: "Direct DB insert vs RPC call", "REST vs GraphQL", library choices, data model decisions, any AskUserQuestion from a session.

### Blockers

Session waiting for y/n confirmation:
1. `fleet check <name>` — read what it's asking.
2. **If the confirmation is about a routine operation** (file overwrite, dependency install, branch switch): `fleet keys <name> y`.
3. **If the confirmation involves data deletion, force-push, or anything destructive:** ask the user.
4. **If you can't determine the impact:** ask the user.

### Buffer state

A `buffer` event means unsubmitted text is sitting in the session's input prompt (crashed mid-input or tmux delivered text without Enter).

1. `fleet check <name>` — read the buffered text.
2. **Valid command/response:** `fleet keys <name> Enter` to submit.
3. **Garbage or partial text:** `fleet keys <name> C-c` to clear, then `fleet send <name>` with the intended instruction.
4. **Can't tell:** ask the user.

### Rogue sessions

1. **If the session is idle and off-track:** `fleet send <name> "Stop — <correction>"` to redirect.
2. **If the session is working and hasn't responded to a previous `fleet send` within one turn:** `fleet keys <name> C-c` to interrupt, then send correction.
3. **If the session has been redirected 2+ times and is still off-track:** suggest killing and respawning with a better prompt.

### CI failures

Sessions own their CI and fix failures autonomously. The captain intervenes as a fallback when a session goes idle with failing CI:
1. `fleet pr <name> --once` — check which checks failed.
   - **If no PR is bound:** run `fleet check <name>` to see if a PR URL is in the pane output. If found, bind it with `fleet desc <name> --pr <N>`.
2. `fleet send <name> "CI is failing on <check>. Fix it, push to branch <branch>, and run 'gh pr checks <number> --watch' to confirm all checks pass before going idle."`
3. **If the PR belongs to someone else:** just report to the user.

### Context warnings

A `context_warning` event means the session is compacting context.

- **If the session continues making progress after compaction:** no action needed.
- **If the session repeats the same action 2+ times or loses track of its original task:** it has degraded. Kill and respawn with a fresh prompt that includes progress so far (reference the branch and any committed work).
- **If you can't tell:** `fleet check <name>` to inspect the pane output for signs of looping.

### Crashed/gone sessions

1. Report which sessions are gone/crashed to the user.
2. Check whether work was saved:
   - **If the branch has commits or a PR exists:** respawn with `--worktree --branch <branch>` to continue from existing work.
   - **If no commits were pushed:** report the loss to the user and ask whether to respawn with the original prompt.
3. **If the session had a worktree that still exists:** the worktree may contain uncommitted changes. Mention this before killing.

## Killing & Cleanup

Always read [[workflow-killing]] when killing sessions.

Always get explicit user approval before killing a session. Killing destroys uncommitted work, worktrees, and branches — this is the one area where the captain must not freelance.

### Gate: Pre-Kill Verification

Before running `fleet kill`:
- [ ] **User approved** — explicit approval ("kill the idle ones", "yeah kill auth-sso"). Not implied, not assumed.
- [ ] **Task is complete** — a merged PR doesn't mean "done" if there was post-merge work in the prompt. Check the full prompted task.
- [ ] **Work is saved** — run `fleet check <name>`. If uncommitted work exists, warn the user before proceeding.

**If any check fails:** do not kill. Present the blocker to the user.

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
- **ALWAYS use `-y` flag** to skip the CLI prompt (captain asks the user, `-y` is for the CLI)
- **ALWAYS run in background** (`run_in_background: true`) — worktree cleanup is slow

See [[workflow-killing]] for the full procedure.

`fleet kill` handles tmux session, worktree, branch, and registry cleanup automatically. After killing, verify with `fleet status`.

## Recovery & Context

`fleet recover` reconciles the registry with live tmux sessions, worktrees, and PRs. Run on startup or after a crash.

The registry (`~/.claude/fleet/registry.json`, see [[state-schema]]) is external memory — use `fleet` commands rather than holding feature state in conversation. When context grows large, tell the user to restart the captain. `fleet recover` picks up seamlessly.

Keep fleet summaries compressed: "auth-sso pushed branch, PR #42 CI pending" over step-by-step action logs.

## Terminal State

The captain role is continuous. It ends when `fleet status` shows no active features and the user moves on to other work. If the user restarts a captain session later, run `fleet recover` to pick up where things left off.
