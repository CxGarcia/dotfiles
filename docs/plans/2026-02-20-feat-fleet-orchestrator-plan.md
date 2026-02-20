---
title: "feat: Fleet Orchestrator for Multi-Feature Development"
type: feat
status: completed
date: 2026-02-20
---

# Fleet Orchestrator for Multi-Feature Development

## Overview

A Claude Code skill that acts as a meta-orchestrator, managing multiple concurrent feature development sessions. Each feature runs autonomously through the compound-engineering pipeline (brainstorm → plan → work → review → simplify → monitor PR) in its own tmux session + git worktree. The orchestrator spawns, monitors, advances, and reports on all active features from a single session.

## Problem Statement / Motivation

The user's daily workflow is a repeatable pipeline applied across many features in parallel. Currently each feature is manually shepherded through each phase. This is predictable enough to automate — the orchestrator eliminates the manual coordination overhead while preserving human control at decision points.

## Proposed Solution

A Claude Code skill at `~/.claude/skills/fleet-orchestrator/` that teaches Claude how to:
- Spawn feature sessions (detached tmux session + `claude -w` for worktree)
- Send pipeline commands via `tmux send-keys`
- Monitor status via `tmux capture-pane`, pane titles, `gh pr`, and Claude Code hooks
- Track state in a persistent JSON registry at `~/.claude/fleet/registry.json`
- Present status dashboards and route user attention

## Technical Approach

### Architecture

```
Layer 1: Meta-Orchestrator (Claude session in its own tmux session)
├── Spawns feature sessions (detached tmux + claude -w)
├── Sends pipeline commands via tmux send-keys
├── Monitors via tmux capture-pane, pane titles, gh CLI
├── Tracks state in ~/.claude/fleet/registry.json
├── Presents dashboard / status on demand
└── Alerts user when sessions need attention

Layer 2: Feature Sessions (independent Claude instances)
├── Each in its own tmux session + git worktree (via claude -w)
├── Follows compound-engineering pipeline autonomously
├── Creates agent teams for /workflows:work (swarm mode)
├── Creates agent teams for /workflows:review (parallel reviewers)
├── Sets pane title to current task (sync-title.sh picks this up)
└── Blocks on AskUserQuestion when needing user input
```

### Spawning Mechanics

The orchestrator CANNOT use `claude -w --tmux` because it blocks the caller (switches tmux client or attaches). Instead:

```bash
# 1. Create detached tmux session in the target repo
tmux new-session -d -s "$session_name" -c "$repo_path"

# 2. Mark as fleet-managed (prevents sync-title.sh from renaming)
tmux set-option -t "$session_name" @fleet_managed 1

# 3. Record the stable session ID (survives renames)
session_id=$(tmux display-message -t "$session_name" -p '#{session_id}')

# 4. Start Claude with worktree (handles branch creation, cleanup on exit)
tmux send-keys -t "$session_name" -l "claude -w $feature_name --dangerously-skip-permissions"
tmux send-keys -t "$session_name" Enter

# 5. Wait for Claude to be ready (poll for prompt)
# ... polling loop ...

# 6. Send initial pipeline command
tmux send-keys -t "$session_name" -l "/workflows:brainstorm $description"
tmux send-keys -t "$session_name" Enter
```

This gives us: worktree isolation via `claude -w` (proper branch naming `worktree-<name>`, cleanup prompts on exit) + full tmux control (detached, no client switching).

### Session Identity: Solving the sync-title.sh Problem

**Problem:** The existing `sync-title.sh` renames tmux sessions based on Claude's pane title. If the orchestrator creates session "auth-sso", sync-title.sh renames it to "add-sso-support" — breaking all subsequent `tmux send-keys -t auth-sso` commands.

**Solution:** Two-pronged:

1. **Mark fleet sessions:** Set `@fleet_managed 1` on orchestrator-spawned sessions. Modify `sync-title.sh` to skip sessions with this flag (3-line change).

2. **Store session IDs:** Record the tmux session ID (`$N` format, stable across renames) in the registry. Use session IDs for all tmux commands as a safety net.

```bash
# In sync-title.sh, add early exit for fleet-managed sessions:
fleet=$(tmux show-option -qv -t "$SESSION" @fleet_managed 2>/dev/null)
[[ "$fleet" == "1" ]] && exit 0
```

### State Detection

Three approaches, in order of reliability:

**1. Claude Code Hooks (event-driven, most reliable)**

Configure hooks in user settings to write events to a shared log:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "echo '{\"event\":\"stop\",\"ts\":\"'$(date -u +%FT%TZ)'\",\"cwd\":\"'$PWD'\"}' >> ~/.claude/fleet/events.jsonl"
      }]
    }],
    "Notification": [{
      "matcher": "permission_prompt",
      "hooks": [{
        "type": "command",
        "command": "echo '{\"event\":\"needs_input\",\"ts\":\"'$(date -u +%FT%TZ)'\",\"cwd\":\"'$PWD'\"}' >> ~/.claude/fleet/events.jsonl"
      }]
    }]
  }
}
```

The `Stop` hook fires when Claude finishes responding (ready for next input). The `Notification` hook with `permission_prompt` matcher fires when Claude needs user confirmation.

**2. tmux capture-pane pattern matching (polling fallback)**

```bash
content=$(tmux capture-pane -t "$session_id" -p -S -10)

# Idle: prompt visible, no activity spinner
if echo "$content" | grep -q '❯' && ! echo "$content" | grep -qE '(ctrl\+c to interrupt|·.*tokens)'; then
  state="idle"
# Working: activity spinner or progress indicators
elif echo "$content" | grep -qE '(ctrl\+c to interrupt|·.*tokens|Thinking|Running)'; then
  state="working"
# Blocked: permission/question prompt
elif echo "$content" | grep -qE '\[y/n\]|\[Y/n\]'; then
  state="needs_input"
fi
```

**3. Process state check (quick health check)**

```bash
cmd=$(tmux display-message -t "$session_id" -p '#{pane_current_command}')
if [[ "$cmd" != "claude" ]]; then
  # Claude exited — check exit status
  dead=$(tmux display-message -t "$session_id" -p '#{pane_dead}')
  if [[ "$dead" == "1" ]]; then
    exit_code=$(tmux display-message -t "$session_id" -p '#{pane_dead_status}')
    # exit_code 0 = normal, non-zero = crash
  fi
fi
```

### Persistent State: Registry

Location: `~/.claude/fleet/registry.json`

```json
{
  "version": 1,
  "updated": "2026-02-20T14:30:00Z",
  "features": {
    "auth-sso": {
      "description": "Add SSO support with SAML provider",
      "repo": "/Users/cristobalschlaubitz/dev/app",
      "worktreePath": "/Users/cristobalschlaubitz/dev/app/.claude/worktrees/auth-sso",
      "branch": "worktree-auth-sso",
      "tmuxSession": "auth-sso",
      "tmuxSessionId": "$47",
      "phase": "work",
      "phaseHistory": ["brainstorm", "plan"],
      "mode": "phased",
      "pr": null,
      "status": "active",
      "startedAt": "2026-02-20T10:15:00Z",
      "updatedAt": "2026-02-20T14:25:00Z",
      "artifacts": {
        "brainstorm": "docs/brainstorms/2026-02-20-auth-sso-brainstorm.md",
        "plan": "docs/plans/2026-02-20-feat-auth-sso-plan.md"
      }
    }
  }
}
```

Design choices:
- **Map keyed by feature name** — O(1) lookups, no array searching
- **Both session name AND session ID** — name for human readability, ID for reliable tmux targeting
- **Phase as string, not enum** — Claude reasons about phases naturally
- **Artifacts map** — orchestrator can read brainstorm/plan docs for context bridging
- **Atomic writes** — write to `.tmp`, then `mv` (atomic rename on POSIX)

### Event Log

Append-only JSONL at `~/.claude/fleet/events.jsonl` for audit trail:

```jsonl
{"ts":"2026-02-20T10:15:00Z","feature":"auth-sso","event":"spawned","phase":"brainstorm"}
{"ts":"2026-02-20T10:30:00Z","feature":"auth-sso","event":"phase_complete","phase":"brainstorm"}
{"ts":"2026-02-20T10:30:05Z","feature":"auth-sso","event":"phase_start","phase":"plan"}
```

No read-modify-write — just append. Safe against crashes.

### Phase State Machine

```
spawned → brainstorm → plan → work → review → simplify → pr_monitoring → done
                                  ↑                              |
                                  └── iteration (review found issues) ──┘

Any phase can transition to:
  → crashed (abnormal exit detected)
  → abandoned (user kills feature)

crashed → retry_<phase> (orchestrator restarts current phase)
```

Valid phase commands:

| Phase | Command sent to feature session | Arguments |
|-------|-------------------------------|-----------|
| brainstorm | `/workflows:brainstorm` | Feature description |
| plan | `/workflows:plan` | (auto-detects brainstorm doc) |
| work | `/workflows:work` | Plan file path (optional) |
| review | `/workflows:review` | `latest` |
| simplify | Run code-simplifier agent | Branch context |
| pr_monitoring | (no command — orchestrator polls gh) | — |

For full-auto mode (`/slfg`), a single command replaces the entire state machine:

| Mode | Command | Behavior |
|------|---------|----------|
| slfg | `/slfg <description>` | Runs entire pipeline autonomously |

### Context Window Management

The orchestrator's context fills up from polling output. Mitigations:

1. **Minimal captures:** Always use `tmux capture-pane -p -S -5` (last 5 lines only)
2. **Structured status:** Parse tmux output into short status strings, don't dump raw pane content
3. **On-demand detail:** Only capture full pane content when the user asks for detail on a specific feature
4. **Registry is the memory:** All durable state lives in `registry.json`, not in conversation context
5. **Graceful restart:** When context gets large, the orchestrator can instruct the user to restart it. The new session reads `registry.json` and picks up where it left off.

### Crash Recovery

The orchestrator reconstructs state from multiple independent sources:

```
1. Read ~/.claude/fleet/registry.json (primary — has all feature metadata)
2. For each feature in registry:
   a. tmux has-session -t "$tmuxSessionId" → session alive?
   b. tmux display-message -t "$tmuxSessionId" -p '#{pane_current_command}' → Claude running?
   c. test -d "$worktreePath" → worktree exists?
   d. gh pr list --repo "$repo" --head "$branch" → PR status?
3. Reconcile: mark stale features, update phases from observed state
4. Scan for orphaned sessions: tmux sessions with @fleet_managed=1 not in registry
5. Write updated registry
```

### Feature Session Cleanup

On kill/complete, in order (each step idempotent):

```bash
# 1. Interrupt Claude if running
tmux send-keys -t "$session_id" C-c
sleep 1

# 2. Exit Claude
tmux send-keys -t "$session_id" -l "/exit"
tmux send-keys -t "$session_id" Enter
sleep 2

# 3. Clean up orphaned teams (if any)
# Scan ~/.claude/teams/ for teams with matching worktree CWD
for team_dir in ~/.claude/teams/*/; do
  # kill team panes, remove team + task dirs
done

# 4. Kill tmux session
tmux kill-session -t "$session_id"

# 5. Remove worktree and branch
git -C "$repo" worktree remove --force "$worktreePath"
git -C "$repo" branch -D "$branch"

# 6. Update registry
# Set status to "done" or "abandoned", add completedAt timestamp
```

### Orchestrator Session Bridge

The orchestrator needs context of what's happening in feature sessions. Bridge mechanisms:

| Need | Mechanism |
|------|-----------|
| Current task | `tmux display-message -t $id -p '#{pane_title}'` |
| Recent output | `tmux capture-pane -t $id -p -S -10` |
| Phase artifacts | Read brainstorm/plan docs from worktree path (stored in registry) |
| PR details | `gh pr view <number> --repo <repo> --json title,body,statusCheckRollup,reviews` |
| Git progress | `git -C <worktree> log --oneline -5` |
| Full session transcript | `~/.claude/projects/<path>/<session-id>.jsonl` (if session ID is known) |

## Implementation Phases

### Phase 1: Foundation — Registry and sync-title.sh fix

**Files to create/modify:**

| File | Action |
|------|--------|
| `~/.claude/fleet/registry.json` | Create — empty initial registry `{"version":1,"features":{}}` |
| `~/.claude/fleet/events.jsonl` | Create — empty event log |
| `config/.config/tmux/scripts/sync-title.sh` | Modify — skip `@fleet_managed` sessions |

**sync-title.sh change** (add after line `[[ "$WINDOW_NAME" != "claude" ]] && exit 0`):

```bash
fleet=$(tmux show-option -qv -t "$SESSION" @fleet_managed 2>/dev/null)
[[ "$fleet" == "1" ]] && exit 0
```

**Success criteria:**
- `~/.claude/fleet/` directory exists with empty registry
- `sync-title.sh` skips sessions with `@fleet_managed 1`
- Existing non-fleet sessions still get renamed as before

### Phase 2: Orchestrator Skill — Core

**Files to create:**

| File | Purpose |
|------|---------|
| `~/.claude/skills/fleet-orchestrator/SKILL.md` | Main skill — orchestrator prompt and workflow |
| `~/.claude/skills/fleet-orchestrator/references/state-schema.md` | Registry JSON schema and phase definitions |
| `~/.claude/skills/fleet-orchestrator/references/tmux-reference.md` | Tmux commands for spawning, monitoring, detecting |
| `~/.claude/skills/fleet-orchestrator/references/pipeline-phases.md` | Phase state machine, commands per phase, transition logic |

**SKILL.md structure** (~1500 words, imperative style):

```yaml
---
name: fleet-orchestrator
description: >-
  Use when managing multiple concurrent feature development sessions,
  spawning new features across repos, monitoring pipeline progress,
  checking fleet status, advancing phases, killing features, or
  recovering after a restart. Triggers on "start feature", "fleet status",
  "what needs me", "advance", "kill feature", "fleet", "orchestrate".
---
```

Body sections:
1. **Role definition** — you are a fleet orchestrator managing feature sessions
2. **Registry management** — read/write `~/.claude/fleet/registry.json`
3. **Spawn flow** — create tmux session, start `claude -w`, send initial command
4. **Phase advancement** — detect completion, send next command
5. **Status dashboard** — query all sessions, format table
6. **Attention routing** — detect blocked sessions, alert user
7. **Cleanup** — kill/complete features, remove worktrees
8. **Recovery** — reconstruct state from registry + tmux + git + gh

**Success criteria:**
- User can start the orchestrator skill and spawn a feature
- Feature session runs in a detached tmux session with `claude -w`
- Registry tracks the feature
- User can ask for status and see the feature listed

### Phase 3: Pipeline Integration — Phase-Gated Mode

Add phase advancement logic to the skill:

1. After spawning, orchestrator monitors feature session state
2. When phase completes (Claude returns to prompt), orchestrator:
   - Updates registry with completed phase
   - Logs event to events.jsonl
   - Sends next phase command
3. Between brainstorm and plan: no gate (auto-advance)
4. Between plan and work: no gate (auto-advance, plan auto-detects brainstorm)
5. After work: pause for user review before `/workflows:review`
6. After review: auto-advance to simplifier
7. After simplify: auto-advance to PR monitoring
8. PR monitoring: poll `gh pr view`, alert on CI failures or merge readiness

**Phase command construction:**

```bash
# Brainstorm: needs description
/workflows:brainstorm $description

# Plan: auto-detects brainstorm doc in docs/brainstorms/
/workflows:plan

# Work: auto-detects plan doc OR pass path
/workflows:work

# Review: review latest changes
/workflows:review latest

# Simplify: run code-simplifier
# (This is a subagent within the feature session, not a slash command)
# Send: "Run the code-simplifier agent on the changes in this branch"

# PR monitoring: no command, orchestrator polls gh CLI
```

**Success criteria:**
- Feature advances through brainstorm → plan → work → review → simplify → monitoring
- Phase gates work (pauses where expected)
- Registry tracks phase progression

### Phase 4: Full-Auto Mode and Multi-Feature

Add `/slfg` mode and multi-feature management:

1. When user says "run slfg for X in repo Y", send `/slfg <description>` instead of phase-gated commands
2. Support N concurrent features across multiple repos
3. Dashboard shows all features with their status
4. "What needs me?" scans all features for blocked states
5. Feature name uniqueness: auto-append `-2`, `-3` on collision

**Success criteria:**
- `/slfg` mode runs end-to-end autonomously
- Multiple features tracked simultaneously
- Dashboard shows accurate status for all features
- Blocked features are surfaced

### Phase 5: Robustness — Hooks, Recovery, Cleanup

1. **Claude Code hooks:** Add `Stop` and `Notification` hooks to user settings for event-driven detection
2. **Crash recovery:** Implement registry reconciliation on orchestrator startup
3. **Feature cleanup:** Implement kill/abandon with full cleanup (session, worktree, branch, teams)
4. **Orphan detection:** Scan for fleet-managed tmux sessions not in registry
5. **Team cleanup:** On feature crash, scan `~/.claude/teams/` for orphaned teams

**Success criteria:**
- Orchestrator recovers gracefully from crashes
- Killed features are fully cleaned up (no orphans)
- Hooks provide faster state detection than polling alone

## System-Wide Impact

### Interaction with sync-title.sh

Modified to skip `@fleet_managed` sessions. Non-fleet sessions unaffected.

### Interaction with util-window.sh

Fleet-managed sessions in git repos will still get auto-created utility windows (window index 2). This is fine — worktree paths are inside the repo, so `git rev-parse --show-toplevel` resolves correctly. Utility windows will be shared across feature sessions in the same repo.

### Interaction with ts.sh session picker

Fleet-managed sessions appear in the picker like regular sessions. The user can switch to them freely. The `@fleet_managed` metadata could optionally be displayed in the picker preview in a future enhancement.

### Interaction with compound-engineering plugin

The orchestrator sends slash commands (`/workflows:brainstorm`, `/workflows:plan`, etc.) to feature sessions. These commands come from the compound-engineering plugin which must be installed and enabled. The orchestrator does not modify the plugin — it simply invokes its commands via tmux send-keys.

Feature sessions using `/workflows:work` in swarm mode create their own teams internally. These teams are invisible to the orchestrator. If a feature session crashes with an active team, the orchestrator handles cleanup by scanning `~/.claude/teams/` for directories whose tasks reference the feature's worktree.

## Acceptance Criteria

### Functional Requirements

- [ ] Spawn feature sessions with `claude -w` in detached tmux sessions
- [ ] Track features in persistent JSON registry
- [ ] Advance phased features through the pipeline
- [ ] Support full-auto mode via `/slfg`
- [ ] Present status dashboard on demand
- [ ] Detect and surface blocked feature sessions
- [ ] Clean up features (kill session, remove worktree, delete branch)
- [ ] Recover state after orchestrator restart

### Non-Functional Requirements

- [ ] Context window stays manageable (minimal pane captures)
- [ ] Registry survives crashes (atomic writes)
- [ ] No interference with existing tmux setup (sync-title, util-window, picker)

## Dependencies & Risks

| Risk | Mitigation |
|------|-----------|
| `tmux capture-pane` pattern matching is fragile | Use Claude Code hooks as primary detection; patterns as fallback |
| Orchestrator context window exhaustion | Minimal captures (5 lines), registry as external memory, graceful restart |
| `sync-title.sh` renames sessions | `@fleet_managed` flag skips renaming; session IDs as safety net |
| Feature session crashes with active teams | Scan `~/.claude/teams/` for orphaned teams on cleanup |
| `send-keys` timing issues | Poll for Claude readiness before sending; use `-l` flag for literal text |
| Multiple features in same repo cause merge conflicts | Worktrees provide full isolation during development; conflicts only at merge time |

## References & Research

### Internal References

- Brainstorm: `docs/brainstorms/2026-02-20-feature-fleet-orchestrator-brainstorm.md`
- Tmux config: `config/.config/tmux/tmux.conf`
- sync-title.sh: `config/.config/tmux/scripts/sync-title.sh`
- util-window.sh: `config/.config/tmux/scripts/util-window.sh`
- Session picker: `config/.config/tmux/scripts/ts.sh`
- Claude workspace launcher: `config/.config/fish/functions/tclaude.fish`

### External References

- [Claude Code Agent Teams docs](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code CLI Reference](https://code.claude.com/docs/en/cli-reference)
- [claude-tmux detection patterns](https://github.com/nielsgroen/claude-tmux)
- [Overstory agent orchestration](https://github.com/jayminwest/overstory) — SQLite mail system, tiered watchdog
- [Tmux-Orchestrator](https://github.com/absmartly/Tmux-Orchestrator) — git-derived state, checkpoint scheduling
- [Claude Code Agent Farm](https://github.com/Dicklesworthstone/claude_code_agent_farm) — JSON coordination files
- [Claude Code Swarm Orchestration Skill](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
