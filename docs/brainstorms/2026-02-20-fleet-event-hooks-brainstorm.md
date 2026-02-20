# Fleet Event Hooks — Push-Based Monitoring

**Date:** 2026-02-20
**Status:** Brainstorm Complete

## What We're Building

Replace the fleet monitor's tmux polling with push-based events using Claude Code hooks. Feature sessions push events to `~/.claude/fleet/events.jsonl` via hooks. The orchestrator reads new events on every user interaction via a `UserPromptSubmit` hook.

## Why This Approach

Polling tmux capture-pane is fragile (pattern matching), slow (2s intervals), and misses discrete events (PR creation, test results). Hooks are event-driven, reliable, and give us structured data with full context (tool inputs, responses, session IDs).

## Architecture

```
Feature Sessions (hooks push events)        Orchestrator (hook injects events)
┌─────────────────────────┐                 ┌──────────────────────────┐
│ PostToolUse: gh pr create│──┐              │ UserPromptSubmit hook:   │
│ PostToolUse: git push    │  │              │   read events.jsonl      │
│ Stop: Claude idle        │  ├─► events.jsonl ──► from last offset     │
│ Notification: blocked    │  │              │   inject as context      │
│ PreCompact: context warn │──┘              │   update offset          │
└─────────────────────────┘                 └──────────────────────────┘
```

## Events to Capture (v1 — lean)

| Hook Event | Trigger | What we log |
|------------|---------|-------------|
| PostToolUse (Bash) | `gh pr create` in command | `pr_created` + PR URL |
| PostToolUse (Bash) | `git push` in command | `pushed` + branch |
| Stop | Claude finishes responding | `idle` |
| Notification | `elicitation_dialog` type | `needs_input` |
| PreCompact | Context compaction triggered | `context_warning` |

## Key Decisions

1. **Push, not poll** — hooks write to events.jsonl, no tmux polling for event detection
2. **UserPromptSubmit injection** — orchestrator sees events automatically on every interaction
3. **Byte offset tracking** — `.events_offset` file stores last-read position, no daemon needed
4. **Fleet filtering** — hook checks if CWD is under `.claude/worktrees/` to skip non-fleet sessions
5. **Monitor stays for auto-advance** — reads from events.jsonl instead of polling tmux, only needed for autonomous phase advancement
6. **Global hooks** — configured in `~/.claude/settings.json` since fleet spans repos

## Scope

**In scope:**
- Hook script that writes events from feature sessions
- UserPromptSubmit hook that injects events into orchestrator
- Offset-based read tracking
- Update `fleet monitor` to consume events.jsonl instead of polling

**Out of scope (future):**
- Cross-session conflict detection (file change tracking)
- Test result capture
- Team/subagent activity tracking
