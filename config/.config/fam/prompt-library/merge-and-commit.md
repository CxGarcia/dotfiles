---
id: merge-and-commit
name: commit and sync back
category: git-workflow
tags: [git, merge, commit, worktree, sync, base-branch]
is_default: false
created_at: 2025-10-30T22:45:00Z
updated_at: 2025-10-30T23:05:00Z
usage: Use when ready to commit your work and sync with base branch
---

When finalizing your work in a worktree, follow this order:

## 1. Commit Your Work First

```bash
git add .
git commit -m "<type>: <summary>"
make fmt && make lint && make build && make test
```

**Commit message format**: `<type>: <summary>`
- Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
- Keep summary under 72 chars, lowercase after colon
- Use imperative mood: "add" not "added"

## 2. Sync with Base Branch

**IMPORTANT**: The base branch is the project directory's current branch (from `${{ git.current_branch }}`), NOT `origin/main`.

```bash
git fetch
git merge <base-branch-name>  # Use project directory's current branch
```

**If you see merge conflicts**:
1. `git status` to see which files
2. Edit files, remove `<<<<<<<`, `=======`, `>>>>>>>` markers
3. `git add <resolved-files>`
4. `git merge --continue`

**After merge**:
```bash
make fmt && make lint && make build && make test
```

If tests fail, fix the issues and commit:
```bash
git add .
git commit -m "fix: adapt to base branch changes"
```

## Key Points

- **Commit first, then sync** - Saves your work before dealing with base changes
- **Don't merge from origin/main** - Use the project directory's current branch
- **Conflicts are normal** - Just edit the files, remove markers, and continue
- **Test after merging** - Always verify everything works
- **The workflow handles the final merge** - Your job is to commit and sync

## Quick Reference

```bash
# Complete workflow:
git add .
git commit -m "feat: implement X"
make build && make test

git fetch
git merge <base-branch>
# If conflicts: edit files, git add, git merge --continue
make build && make test

# Done - approve the workflow
```
