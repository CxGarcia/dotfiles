# Parallel Audit Workflow

Fan-out N sessions across subsystems for codebase-wide review, simplification, or test coverage. Each session runs autonomously and creates its own PR.

## Pattern

1. Captain determines subsystems to cover (from user prompt, or by asking via AskUserQuestion).
2. Spawns N parallel sessions, each scoped to one subsystem.
3. Each session runs autonomously — commits, pushes, creates PR.
4. Captain monitors for failures/blockers across all sessions.

## Audit Types

| Type | Session does | Prompt includes | Auto-merge |
|------|-------------|-----------------|------------|
| review | Deep code review, finds and fixes issues | "Find and fix: redundant code, dead code, untested code, convention violations" | No |
| simplify | Code simplification loop | "Run code-simplifier in a loop until nothing else to simplify" | Yes — `gh pr merge --auto --squash` |
| test | Writes integration tests | "Write deep integration tests covering the full surface" | No |

## Prompt Templates

### Review audit

```
Deep code review of the {{subsystem}} layer.

SCOPE: {{scope_paths}}

WHAT TO LOOK FOR: redundant code, dead code, untested code, convention violations, missing error handling, inconsistent patterns.

PROCESS:
1. Read every file in scope.
2. Create a findings document summarizing issues found.
3. Fix all issues found.
4. Run tests to verify fixes don't break anything.
5. Commit, push to branch worktree-review-{{subsystem}}, and create a PR to main.
6. After pushing, run `gh pr checks` to monitor CI and fix any failures.
```

### Simplify audit

```
Use the code-simplifier:code-simplifier agent to simplify all code in {{scope_paths}}.

Run in a loop: simplify → verify tests pass → simplify again. Continue until there is nothing left to simplify.

Follow established architecture, code conventions, and reuse existing functionality.

After the loop completes:
1. Commit all changes.
2. Push to branch worktree-simplify-{{subsystem}}.
3. Create a PR to main.
4. Enable auto-merge: gh pr merge --auto --squash <PR_NUMBER>
5. Run `gh pr checks` to monitor CI and fix any failures.
```

### Test audit

```
Write deep integration tests for the {{subsystem}} layer.

SCOPE: {{scope_paths}}

Cover the full surface: happy paths, error paths, edge cases. Prefer few deep tests over many shallow ones. Test against real dependencies where possible (local DB, docker services).

After writing tests:
1. Run the full test suite to verify everything passes.
2. Commit, push to branch worktree-test-{{subsystem}}, and create a PR to main.
3. After pushing, run `gh pr checks` to monitor CI and fix any failures.
```

## Fan-out Procedure

```bash
# For each subsystem, spawn a session with the appropriate template:
fleet spawn {type}-{subsystem} {repo} "{prompt}" --worktree --tag audit,{type}

# Examples:
fleet spawn review-sync-engine app "Deep code review of the sync engine..." --worktree --tag audit,review
fleet spawn simplify-catalog app "Use code-simplifier on apps/catalog/..." --worktree --tag audit,simplify
fleet spawn test-credentials app "Write integration tests for credentials..." --worktree --tag audit,test
```

Naming convention: `{audit_type}-{subsystem}` (e.g., `review-sync-engine`, `simplify-catalog`, `test-credentials`).

Tag all audit sessions with `audit` and the audit type for filtering: `fleet status --tag audit`.

## Captain Guidance

| Signal | Meaning | Action |
|--------|---------|--------|
| All sessions idle with PRs | Audit complete | Report: "N/N audit sessions have PRs." Kill sessions |
| `context_warning` on a session | Session compacting (common for review/simplify loops) | Kill and respawn with `--branch` to continue from existing commits |
| Session idle without PR | Session may be stuck or finished without creating PR | `fleet check`, nudge with `fleet send` |
| CI failing on audit PR | Audit introduced a regression | `fleet send` with fix instruction, or kill and respawn |
