# Fleet Modes Rethink

**Date:** 2026-02-23

## What We're Building

Simplifying the fleet spawn system by removing rigid modes and fixed pipeline phases. Instead of pre-defined workflows (phased/slfg/fix), every spawn is just a prompt sent to a Claude session. The captain and user invoke workflows as needed.

## Why This Approach

The current three modes (phased, slfg, fix) are the wrong abstractions:
- **Phased** is too rigid — a fixed 6-step pipeline that must be manually advanced
- **SLFG** is fully autonomous but opaque
- **Fix** is a catch-all for "just do this thing" but gets used for everything from debugging to quick PRs to directed tasks

In practice, most spawns are "send this prompt and let it work." The pipeline phases add friction without matching how work actually flows.

## Key Decisions

1. **Drop modes entirely.** No more `--mode phased|slfg|fix`. Every spawn sends the description as the first prompt.

2. **Drop phase tracking.** No more phase, phaseHistory, or mode fields in the registry. The captain infers what a session is doing by checking `fleet status` pane output.

3. **Drop `fleet advance`.** No fixed pipeline to advance through. The captain or user sends workflow commands directly via `fleet send` when needed (e.g., `fleet send <name> /workflows:plan`).

4. **No worktree by default.** Spawn opens a tmux session in the repo directory. Use `--worktree` to create one. Use `--branch <name>` to check out a specific branch.

5. **Auto-launch + send prompt.** Spawn still creates tmux session, launches Claude, and sends the description. Same as today, just without the mode-specific routing.

6. **Simpler registry.** Feature object reduces to: name, description, repo, worktreePath (nullable), branch, tmuxSession, tmuxSessionId, pr, status, startedAt, updatedAt.

7. **Claude Code session ID — deferred.** No reliable way to capture it yet (env var `CLAUDE_SESSION_ID` is a requested feature, not shipped). tmux session ID is sufficient for now.

## What Changes

### Spawn command
```
# Before
fleet spawn <name> <repo> "<desc>" --mode phased|slfg|fix

# After
fleet spawn <name> <repo> "<desc>" [--worktree] [--branch <name>]
```

### Registry Feature object
```
# Before
{ mode, phase, phaseHistory, description, repo, worktreePath, branch, tmuxSession, ... }

# After
{ description, repo, worktreePath, branch, tmuxSession, tmuxSessionId, pr, status, startedAt, updatedAt }
```

### Removed commands
- `fleet advance` — no longer needed

### Captain behavior
- Instead of checking phase to decide next action, captain checks pane output via `fleet status`
- Captain sends workflow commands directly when needed: `fleet send <name> "/workflows:brainstorm"`, `fleet send <name> "/workflows:plan"`, etc.

## Open Questions

None — all resolved during brainstorm.
