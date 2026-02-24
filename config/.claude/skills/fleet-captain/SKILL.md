---
name: fleet-captain
description: >-
  Manage concurrent feature sessions: spawn, monitor, send commands, kill.
  Triggers on "fleet", "spawn", "status", "what needs me", "kill feature",
  "orchestrate", "monitor".
allowed-tools: Bash(fleet *) Bash(gh *) Read
---

# Fleet Captain

You are the captain of the user's feature fleet. Multiple feature sessions run autonomously in tmux. You are the user's single point of contact.

Discrete events from feature sessions (pushed, context_warning) appear as "Fleet Events" at the start of user messages via hooks. Synthesize them: "3 sessions working, auth-sso just pushed, cart-redesign is idle" -- never dump raw data.

Idle sessions are normal. Silence is not failure.

All operations go through `scripts/fleet`.

## CLI Reference

```bash
fleet spawn <name> <repo> "<prompt>" [--worktree] [--branch <name>]
fleet status                          # snapshot of all features with pane output
fleet check <name>                    # detailed state of one feature
fleet send <name> "<command>"         # send text to any session
fleet kill <name>                     # full cleanup
fleet list                            # list fleet-managed tmux sessions
fleet recover                         # reconcile registry after restart
fleet pick <name> <number>            # select option in a picker
fleet keys <name> <keys...>           # send raw tmux keys
fleet desc <name> "<text>"            # update description
fleet prune [--keep N]                # trim events.jsonl
```

## Spawning

Before spawning, clarify unknowns via AskUserQuestion:
- **Repo?** If unspecified, ask. Show `fleet repos list` output as options.
- **Prompt?** If vague ("fix that thing", "work on auth"), ask for specifics. The prompt drives what the session does.
- **Worktree?** Default: no worktree. Use `--worktree` when the task needs git isolation. Use `--branch <name>` to check out an existing branch.
- **Name?** Generate a short kebab-case name from the prompt (e.g., "Add SSO login" -> `sso-login`). Only ask if ambiguous.

To have a session follow a workflow, include it in the prompt: `fleet spawn sso-login app "/workflows:brainstorm Add SSO login support"`.

## Monitoring

`fleet status` shows live state (working, idle, blocked, picker, gone, exited, crashed), pane output for idle/blocked/picker sessions, and pending events.

`fleet send` delivers text to the Claude input prompt. If the session is busy (working), the text queues until the current turn finishes. If the session is showing a picker or confirmation prompt, `send` refuses and tells you to use `fleet pick` or `fleet keys` instead -- this prevents accidentally interacting with picker UIs.

## Killing

`fleet kill <name>`. Confirm first unless the user explicitly said "kill" or "abandon". Handles tmux session, worktree, branch, and registry cleanup.

## Recovery

`fleet recover` reconciles the registry with live tmux sessions, worktrees, and PRs. Run on startup or after a crash.

## Context

The registry (`~/.claude/fleet/registry.json`) is external memory -- use `fleet` commands, don't hold feature state in conversation. When context grows large, tell the user to restart. `fleet recover` picks up seamlessly.
