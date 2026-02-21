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
| `description` | string | Natural language description |
| `repo` | string | Absolute path to git repository |
| `worktreePath` | string | Absolute path to worktree (`<repo>/.claude/worktrees/<name>/`) |
| `branch` | string | Git branch (`worktree-<name>`) |
| `tmuxSession` | string | Session name (may get stale if renamed) |
| `tmuxSessionId` | string | Stable session ID (`$N` format, survives renames) |
| `phase` | string | Current pipeline phase |
| `phaseHistory` | string[] | Ordered list of completed phases |
| `mode` | string | `"phased"` or `"slfg"` |
| `pr` | object\|null | PR tracking object (see below) |
| `status` | string | `active`, `blocked`, `crashed`, `abandoned`, or `done` |
| `startedAt` | string | ISO 8601 |
| `updatedAt` | string | ISO 8601 |
| `artifacts` | object | Phase name to relative file path for brainstorm/plan docs |

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
| `event` | string | Event type (see below) |
| `phase` | string | Phase name (when applicable) |
| `detail` | string | Additional context (when applicable) |
| `pr` | number | PR number (for `pr_created` events) |

Event types: `spawned`, `phase_start`, `phase_complete`, `needs_input`, `crashed`, `abandoned`, `pr_created`, `ci_passed`, `ci_failed`, `done`

## Atomic Writes

Always write via temp file + `mv` (POSIX atomic rename):

```bash
cat > ~/.claude/fleet/registry.json.tmp << 'EOF'
{ ... }
EOF
mv ~/.claude/fleet/registry.json.tmp ~/.claude/fleet/registry.json
```
