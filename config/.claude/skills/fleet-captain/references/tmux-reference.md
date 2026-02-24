# tmux Reference

Low-level tmux commands used by `fleet` scripts. The orchestrator should use `fleet` commands, not these directly. This is reference for understanding and debugging.

## State Detection

| Check | Command | Result |
|-------|---------|--------|
| Claude running? | `tmux display-message -t "$id" -p '#{pane_current_command}'` | `claude` = yes, `fish`/`bash` = exited |
| Claude idle? | `pane_title` starts with `✳` + no picker/blocked patterns in last non-empty lines | Idle, waiting for input |
| Claude working? | `pane_title` does not start with `✳` | Actively processing |
| Blocked? | `pane_title` starts with `✳` + last non-empty lines match `\[y/n\]`, `\[Y/n\]`, or `\[yes/no\]` | Waiting for confirmation |
| Picker? | `pane_title` starts with `✳` + last non-empty lines match `Enter to select`, `Space to select`, `to confirm`, or `to navigate` | Showing a selection menu |
| Exited? | `tmux display-message -t "$id" -p '#{pane_dead}'` | `1` = dead; check `#{pane_dead_status}` for exit code |

## Sending Commands

```bash
# Always use -l for literal text, then Enter separately
tmux send-keys -t "$session_id" -l "command text"
tmux send-keys -t "$session_id" Enter

# Exact name match (avoids prefix matching)
tmux send-keys -t "=$session_name" -l "command"
```

## Session Properties

| Variable | Description | Example |
|----------|-------------|---------|
| `#{session_id}` | Stable ID (survives renames) | `$47` |
| `#{session_name}` | Current name (may change) | `auth-sso` |
| `#{pane_title}` | Claude's current task | `Implementing auth` |
| `#{pane_current_command}` | Running process | `claude` or `fish` |
| `#{pane_current_path}` | Working directory | `/path/to/worktree` |
| `#{pane_pid}` | Process ID | `12345` |
| `#{pane_dead}` | Process exited? | `0` or `1` |
| `#{pane_dead_status}` | Exit code (when dead) | `0` |

## Custom Metadata

| Option | Purpose | Values |
|--------|---------|--------|
| `@fleet_managed` | Marks session as fleet-managed | `1` |
| `@fleet_captain` | Marks session as the captain | `1` |
| `@claude_task` | Task description (shown in picker) | Free text |

```bash
tmux show-option -qv -t "$session" @fleet_managed   # read
tmux set-option -t "$session" @fleet_managed 1       # write
```

## Bulk Discovery

```bash
# List fleet-managed sessions
tmux list-sessions -F '#{session_id} #{session_name}' | while read id name; do
  fleet=$(tmux show-option -qv -t "$name" @fleet_managed 2>/dev/null)
  [ "$fleet" = "1" ] && echo "$id $name"
done
```
