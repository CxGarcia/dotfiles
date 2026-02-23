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
| `event` | string | `spawned`, `pushed`, `context_warning`, `pr_created`, `abandoned` |
