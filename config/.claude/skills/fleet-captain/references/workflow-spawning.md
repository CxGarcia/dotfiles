# Spawning Workflow

> Captain procedure for spawning feature sessions. Covers repo resolution, prompt construction, worktree enforcement, and background execution.

## Hard Rules

- **ALWAYS use `--worktree`** for any session that modifies files. No exceptions.
- **ALWAYS spawn in background** (`run_in_background: true` on the Bash tool call). Worktree creation is slow — blocking the captain wastes time.
- **Default to `--worktree`** unless the session is explicitly `--scope research` AND confirmed read-only.

## Procedure

### Step 1: Decompose the Work

Identify independent work units from the user's request.

- **Single task:** one session.
- **Multiple independent tasks:** one session per task. Spawn all in parallel (multiple background Bash calls in one message).
- **Dependencies between tasks:** spawn sequentially or use `fleet relay` to chain output.

### Step 2: Resolve the Repo

- **User specified a repo:** use it.
- **One repo in `fleet repos list`:** use it.
- **Multiple repos:** show `fleet repos list` and ask the user to pick.
- **No repos indexed:** ask for the path.

**If repo path doesn't exist:** stop. Ask the user.

### Step 3: Validate the Prompt

The prompt must contain a **verb** and a **specific target**.

- **Clear** ("Fix auth token refresh in `src/auth/refresh.ts`"): proceed.
- **Vague** ("fix that thing", "work on auth"): ask the user to specify.
- **User insists vague is fine:** proceed — they may have context you don't.

**Do NOT write step-by-step instructions.** Define what and why — the agent figures out how. See "Writing Prompts" in SKILL.md.

### Step 4: Generate the Session Name

Short kebab-case from the target ("Fix auth token refresh" → `fix-auth-refresh`). Only ask if two equally valid names exist.

### Step 5: Set Scope and Flags

| Work type | Flags |
|-----------|-------|
| Code changes (feature, fix, refactor) | `--worktree` |
| Continue existing branch | `--worktree --branch <existing-branch>` |
| Follow-up after merged PR | `--worktree` (new name, fresh branch) |
| Read-only research | `--scope research` (no worktree) |

**Do NOT skip `--worktree` for code-changing sessions.** If you catch yourself about to do this, stop.

### Step 6: Append Forge Submission Instructions

For any session that will create a PR, append to the prompt:

```
After creating the PR, submit it to Forge for review:
- user_id: prf_6vhe4rqpd7b9917rngy7jdj58a
- author_name: Cristobal Schlaubitz
- author_email: cristobal.schlaubitz@bird.com
- Include the Authorization Bearer token (retrieve current token from memory)
- Monitor until merged
```

**If no Forge token exists in memory:** ask the user for the current token before spawning.

### Step 7: Append CI Ownership

For code-pushing sessions, append to the prompt:

```
After pushing, run `gh pr checks <number> --watch` to block until all checks complete. If any check fails, fix and push again. Do not go idle until all checks pass.
```

### Gate: Ready to Spawn

Before running `fleet spawn`:
- [ ] Repo resolved to an absolute path
- [ ] Prompt has verb + specific target
- [ ] `--worktree` set for any session that modifies files
- [ ] Forge submission instructions included (if session will create a PR)
- [ ] CI ownership instruction included (if session will push code)

**If any check fails:** resolve before spawning.

### Step 8: Execute the Spawn

Run `fleet spawn` using the Bash tool with `run_in_background: true`:

```bash
fleet spawn <name> <repo> "<prompt>" --worktree [--branch <name>] [--scope <scope>] [--tag <tags>]
```

**Do NOT wait for the spawn to complete.** Background it and move on. The spawn event appears in Fleet Events on the next turn.

**If spawn fails:** check the error.
- **Session name already exists:** use a different name or kill the existing one first.
- **Worktree path conflict:** `fleet kill --gone -y` to clean up stale worktrees, then retry.
- **Repo not found:** verify the path with `fleet repos list`.

## Success Criteria

- [ ] Session spawned in background (`run_in_background: true`)
- [ ] `--worktree` used for all file-modifying sessions
- [ ] Forge instructions included in PR-creating sessions
- [ ] CI ownership included in code-pushing sessions
