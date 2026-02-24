# State Schema

Persistent state lives under `~/.claude/fleet/`.

## Registry (`registry.json`)

```json
{
  "version": 1,
  "updated": "ISO 8601",
  "features": { "<name>": { ... } }
}
```

### Feature Object

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Prompt sent to the session |
| `repo` | string | Absolute path to git repository |
| `worktreePath` | string\|null | Absolute path to worktree |
| `branch` | string\|null | Git branch (null if default branch) |
| `tmuxSession` | string | Session name (may get stale if renamed) |
| `tmuxSessionId` | string | Stable session ID (`$N` format, survives renames) |
| `pr` | object\|null | PR tracking object (see below) |
| `scope` | string\|null | `research`, `implement`, or `any` (what the session is allowed to do) |
| `tags` | string[] | Arbitrary tags for filtering |
| `status` | string | `active`, `blocked`, `crashed`, `abandoned`, or `done` |
| `startedAt` | string | ISO 8601 |
| `updatedAt` | string | ISO 8601 |

### PR Object

| Field | Type | Values |
|-------|------|--------|
| `number` | number | GitHub PR number |
| `url` | string | Full PR URL |
| `ciStatus` | string | `"pending"`, `"passing"`, `"failing"`, `"unknown"` |
| `lastChecked` | string | ISO 8601 |

## Event Log (`events.jsonl`)

Append-only NDJSON. Each line:

| Field | Type | Description |
|-------|------|-------------|
| `ts` | string | ISO 8601 |
| `feature` | string | Feature name |
| `event` | string | `spawned`, `pushed`, `committed`, `context_warning`, `pr_created`, `abandoned` |

## State Snapshot (`.state_snapshot`)

JSON object mapping feature names to their last-seen tmux state (e.g. `{"auth-sso":"working","cart":"idle"}`). Written by `fleet poll`. Used to detect state changes between polls — only transitions are reported.
