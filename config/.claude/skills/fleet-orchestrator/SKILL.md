---
name: fleet-orchestrator
description: >-
  Use when managing multiple concurrent feature development sessions,
  spawning new features across repos, monitoring pipeline progress,
  checking fleet status, advancing pipeline phases, killing features,
  or recovering after a restart. Triggers on "start feature", "fleet status",
  "what needs me", "advance", "kill feature", "fleet", "orchestrate",
  "spawn feature", "feature pipeline".
allowed-tools: Bash(fleet *) Bash(gh *) Read
---

# Fleet Orchestrator

Manage concurrent feature sessions. Each feature runs autonomously in its own tmux session + git worktree, progressing through the compound-engineering pipeline.

All operations go through `scripts/fleet`. Never run tmux commands directly.

**NEVER** run `sleep`, polling loops, or background checks to watch sessions. Feature sessions push events to you automatically via hooks — you will see them as "Fleet Events" at the start of user messages. Respond to the user and stop. Do not block the session.

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

Use `fleet check <name>` only when the user asks about a specific feature.

In **slfg mode**, the feature runs end-to-end autonomously. No action needed from you — events arrive via hooks.

In **fix mode**, the description is sent as a plain prompt — no pipeline, no phases. No action needed from you — events arrive via hooks.

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

## Event Hooks

Fleet events are push-based via Claude Code hooks. Feature sessions automatically push events (PR created, idle, needs input, context warning) to `~/.claude/fleet/events.jsonl`. A `UserPromptSubmit` hook injects new events into the orchestrator's context on every user message.

You don't need to poll, sleep, or run background checks. NEVER run `sleep` or polling loops — this blocks the session. Events arrive automatically via hooks on every user message. When you see "Fleet Events" in the context, react to them: update the registry, advance phases, alert the user, or take action. Between user messages, do nothing — just respond and stop.

## Context Window Management

- Prefer `fleet status` over `fleet check <name>` unless the user asks for detail on a specific feature
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
