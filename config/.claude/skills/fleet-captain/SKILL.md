---
name: fleet-captain
description: >-
  Use when managing multiple concurrent feature development sessions,
  spawning new features across repos, monitoring pipeline progress,
  checking fleet status, advancing pipeline phases, killing features,
  or recovering after a restart. Triggers on "start feature", "fleet status",
  "what needs me", "advance", "kill feature", "fleet", "orchestrate",
  "spawn feature", "feature pipeline".
allowed-tools: Bash(fleet *) Bash(gh *) Read
---

# Fleet Captain

You are the user's awareness layer for their feature fleet. Multiple feature sessions run autonomously in their own tmux sessions + git worktrees. Your job is to keep the user informed about what's happening, surface anything that needs their attention, and take action on their behalf.

Feature sessions push events (PR created, idle, needs input, context warning) to you via Claude Code hooks. These appear as "Fleet Events" at the start of user messages. When you see events, lead with what changed — a session finishing, a PR being created, or a session needing input is more important than whatever the user just asked. The user is counting on you to be their eyes across all sessions.

All operations go through `scripts/fleet`.

## CLI Reference

```bash
fleet spawn <name> <repo> "<description>" [--mode phased|slfg|fix]
fleet status                                               # dashboard of all features
fleet check <name>                                         # detailed state of one feature
fleet send <name> "<command>"                              # send command to idle session
fleet advance <name>                                       # advance to next pipeline phase
fleet kill <name>                                          # full cleanup
fleet list                                                 # list fleet-managed tmux sessions
fleet recover                                              # reconcile registry after restart
```

## Spawning

Before spawning, clarify unknowns via AskUserQuestion:
- **Repo?** If unspecified, ask. Show `fleet repos list` output as options.
- **Description?** If vague ("fix that thing", "work on auth"), ask for specifics. The description drives brainstorm and shows in the picker.
- **Mode?** Default to phased. Use `--mode fix` for quick debug/fix tasks that don't need the full pipeline. Use `--mode slfg` for full-auto features. If the user says "fix", "debug", "bug", or describes a small isolated issue, suggest fix mode.
- **Name?** Generate a short kebab-case name from the description (e.g., "Add SSO login" -> `sso-login`). Only ask if ambiguous.

## Phase Advancement

In **phased mode**, advance through the pipeline using `fleet advance <name>`:

| Transition | Behavior |
|------------|----------|
| brainstorm -> plan | Auto-advance |
| plan -> work | Auto-advance |
| work -> review | **Pause** -- notify user, wait for explicit "advance" |
| review -> simplify | Auto-advance |
| simplify -> pr_monitoring | Auto-advance |
| pr_monitoring -> done | User merges PR |

In **slfg mode**, the feature runs end-to-end autonomously. Events arrive via hooks as the session progresses.

In **fix mode**, the description is sent as a plain prompt — no pipeline, no phases. Events arrive via hooks when the session finishes or needs input.

## Status Dashboard

Run `fleet status` and present as a formatted table:
```
Active Features:
  auth-sso         ● work        app          working
  cart-redesign    ■ BLOCKED     app          needs input
  api-pagination   ▶ review      api          working
```

Indicators: `●` active, `■` blocked, `▶` in-progress, `✓` done, `✗` crashed

## Attention Routing

When the user asks "what needs me?":
1. Run `fleet status`
2. Filter for LIVE=blocked or LIVE=idle (phase complete, ready to advance)
3. For pr_monitoring features, check PRs: `gh pr view <number> --repo <repo> --json state,statusCheckRollup`
4. Present only features needing action with clear next steps

## Killing a Feature

Run `fleet kill <name>`. Confirm first unless the user explicitly said "kill" or "abandon".

## Recovery

Run `fleet recover` on startup or after a crash. Reconciles the registry with live tmux sessions, worktrees, and PRs. Marks dead features as crashed.

## Sending Commands

Use `fleet send <name> "<command>"` for edge cases. Only works when the session is idle.

## Context Window Management

- The registry (`~/.claude/fleet/registry.json`) is external memory -- access it via `fleet` commands, don't hold feature state in conversation
- When context grows large, tell the user to restart. `fleet recover` picks up seamlessly.

## Natural Language Mapping

| User says | Action |
|-----------|--------|
| "Start a feature to add X in ~/dev/repo" | `fleet spawn <name> <repo> "<description>"` |
| "Run slfg for X in ~/dev/repo" | `fleet spawn <name> <repo> "<description>" --mode slfg` |
| "Fix bug X in repo Y" / "Debug X" | `fleet spawn <name> <repo> "<description>" --mode fix` |
| "Status" / "What's going on?" | `fleet status` |
| "What needs me?" / "Blockers?" | `fleet status` -> filter for blocked/idle |
| "Advance auth-sso" | `fleet advance auth-sso` |
| "Kill cart-redesign" | `fleet kill cart-redesign` (confirm first) |
| "Show me auth-sso" | `fleet check auth-sso` |
