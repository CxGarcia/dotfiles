# Feature Fleet Orchestrator

**Date:** 2026-02-20
**Status:** Brainstorm Complete

## What We're Building

A meta-orchestrator system that manages multiple concurrent feature development sessions, each autonomously driving through the compound-engineering pipeline (brainstorm → plan → work → review → simplify → monitor PR → merge → follow-up).

The orchestrator is a Claude session with a custom skill that uses tmux and the Claude CLI to spawn, monitor, and coordinate a fleet of independent feature sessions. The user interacts primarily with the orchestrator and only jumps into individual feature sessions when they need direct input (brainstorm questions, smoke tests, design decisions).

## Why This Approach

**Problem:** The user's daily workflow is a repeatable pipeline applied across many features in parallel. Currently each feature is manually shepherded through each phase. This is predictable enough to automate.

**Approach: Claude-native orchestrator (no new scripts)**
- The meta-orchestrator is just a Claude session with a well-crafted skill
- It uses existing tools directly: bash for tmux commands, `gh` for PR status, filesystem for docs
- No new fish functions or scripts needed upfront — patterns can be factored out later once the workflow stabilizes
- Leverages `claude -w <name> --tmux` for worktree + session creation in one command

**Why not other approaches:**
- A fish-script fleet manager would be deterministic but can't reason, prioritize, or communicate naturally
- A hybrid approach (scripts + Claude) adds indirection and code to maintain before we know what patterns are worth stabilizing

## Architecture

### Two-Layer Design

```
Layer 1: Meta-Orchestrator (Claude session in tmux)
├── Spawns feature sessions via `claude -w <name> --tmux`
├── Sends pipeline commands via `tmux send-keys`
├── Monitors status via tmux, gh, filesystem
├── Presents dashboard / status summaries
└── Alerts user when sessions need attention

Layer 2: Feature Sessions (independent Claude instances)
├── Each runs in its own tmux session + git worktree
├── Follows compound-engineering pipeline autonomously
├── Creates agent teams for /workflows:work (parallel coding)
├── Creates agent teams for /workflows:review (parallel review agents)
├── Creates agent teams for iteration loops (review → fix → re-review)
├── Sets pane title to current task (existing sync-title.sh picks this up)
└── Blocks on AskUserQuestion when needing user input
```

This sidesteps two Claude Code limitations:
- **One team per session:** Each feature session is its own Claude instance, so each can have its own team
- **No nested teams:** Not needed — feature sessions are independent, not teammates

### Feature Session Lifecycle

```
Orchestrator spawns session
  ↓
claude -w <feature-name> --tmux --dangerously-skip-permissions
  ↓ (worktree created, tmux session created, Claude starts)
  ↓
Orchestrator sends initial command via tmux send-keys
  ↓
┌─────────────────────────────────────────────────────────┐
│ Phase-gated mode          │ Full-auto mode (/slfg)      │
├───────────────────────────┼─────────────────────────────┤
│ /workflows:brainstorm ... │ /slfg <description>         │
│   ← user jumps in         │   ← user jumps in if needed │
│ /workflows:plan           │   (runs end-to-end)         │
│ /workflows:work           │                             │
│ /workflows:review         │                             │
│ code-simplifier loop      │                             │
│ monitor PR + CI           │                             │
└───────────────────────────┴─────────────────────────────┘
  ↓
PR merged → orchestrator marks feature done
  ↓
Follow-up PRs if needed (new feature session)
```

### Inter-Session Communication

**Orchestrator → Feature Session:**
- `tmux send-keys -t <session> "<command>" Enter` for pipeline phase commands
- Only sends when the session is at the Claude prompt (detected via `tmux capture-pane`)

**Feature Session → User:**
- `AskUserQuestion` blocks the session naturally
- User jumps in via existing session picker (`Ctrl-a Ctrl-a` / `ts`)
- Answers directly in the feature session, then switches back

**Orchestrator monitoring (polling-based):**
- `tmux display-message -t <session> -p '#{pane_title}'` — current task description
- `tmux capture-pane -t <session> -p` — recent output, detect prompts/questions
- `tmux list-panes -t <session> -F '#{pane_current_command}'` — is Claude still running?
- `gh pr list --repo <repo> --head <branch>` — PR status and CI checks
- Filesystem: check for brainstorm/plan docs in the worktree

**Detecting "needs attention":**
- Pane content shows AskUserQuestion prompt → session blocked, needs user
- Claude process exited → phase complete (in phase-gated mode, ready for next command)
- PR checks failing → CI issue to investigate
- PR has review comments → needs response

### Orchestrator Commands

The orchestrator skill would understand natural language, but the key intents are:

| Intent | Example |
|--------|---------|
| Start feature (phased) | "Start a feature to add SSO support in ~/dev/app" |
| Start feature (full auto) | "Run slfg for pagination support in ~/dev/api" |
| Check status | "Status" / "What's going on?" |
| What needs attention | "What needs me?" / "Any blockers?" |
| Advance phase | "Move auth-sso to the next phase" |
| Kill feature | "Stop the cart-redesign feature" |
| List features | "List all active features" |

### Status Dashboard

The orchestrator queries tmux sessions, PR status, and pane titles to build a summary:

```
Active Features:
  auth-sso         ● coding       every/app     worktree-auth-sso      3m ago
  cart-redesign    ■ BLOCKED      every/app     worktree-cart-redesign  needs input
  api-pagination   ▶ reviewing    every/api     worktree-api-pagination 12m ago
  email-templates  ✓ monitoring   every/app     PR #234 — CI passing
```

### Code Isolation

Every feature session uses a git worktree via `claude -w <name> --tmux`:
- Worktree at `<repo>/.claude/worktrees/<name>/`
- Branch: `worktree-<name>`
- Full isolation — multiple features can develop in the same repo without conflicts
- Works across different repos too (orchestrator `cd`s to the target repo before spawning)

### Integration with Existing Tmux Setup

**What stays the same:**
- `ts.sh` session picker — feature sessions appear as regular tmux sessions
- `sync-title.sh` — auto-renames feature sessions based on Claude's pane title
- `util-window.sh` — auto-creates utility windows for git repos
- `Ctrl-a Ctrl-a` — jump between orchestrator and feature sessions
- Rose-pine theme, keybindings, plugins — all unchanged

**What changes:**
- The orchestrator session is a new "always-on" session type
- `tclaude` may be used less (orchestrator spawns sessions instead)
- Feature sessions are spawned by `claude -w --tmux` rather than manually

## Key Decisions

1. **Claude-native orchestrator** — no new scripts, just a skill/prompt
2. **Two-layer architecture** — tmux for session management, each session manages its own teams
3. **Always worktrees** — every feature gets code isolation via `claude -w`
4. **Phase-gated by default** — orchestrator drives phases sequentially, with full-auto (`/slfg`) as an option
5. **Jump-in for attention** — user switches to feature sessions directly when they need input (via session picker)
6. **Orchestrator status command** — ask the orchestrator for a dashboard, not embedded in the picker (for now)

## Additional Requirements (from planning handoff)

1. **Session-orchestrator bridge:** The orchestrator needs full context of what's happening in each session — access to outputs, current phase, artifacts produced (brainstorm docs, plan docs, PRs), and session history. Not just pane titles.

2. **Session state tracking:** The orchestrator needs a persistent registry of managed sessions — which features are active, their repo, worktree, branch, current phase, PR number, and status. This must survive orchestrator restarts.

3. **Teams within feature sessions:** Feature sessions use agent teams heavily — `/workflows:work` spawns coding teams, `/workflows:review` spawns parallel review agents, and iteration loops (review → fix → re-review) use teams too. The orchestrator needs to understand that feature sessions have their own internal team lifecycle.

## Open Questions

None — all resolved during brainstorming.

## Scope

**In scope (v1):**
- Custom orchestrator skill for Claude
- Spawn feature sessions with `claude -w --tmux`
- Phase-gated and full-auto modes
- Status dashboard via orchestrator query
- Detection of blocked sessions
- Integration with existing tmux picker for session switching

**Out of scope (future):**
- Automated brainstorm phase (answering questions without user)
- Enhanced session picker showing pipeline phase
- GitHub issue integration as feature input
- Cross-feature dependency management
- Persistent state across orchestrator restarts (session resume)
- Automatic follow-up PR creation
