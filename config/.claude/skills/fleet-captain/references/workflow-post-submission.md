# Post-Submission Workflow

> Procedure for monitoring PRs after Forge submission until merged or rejected.

## Forge Submission Credentials

Every PR submission to Forge must include:

| Field | Value |
|-------|-------|
| user_id | `prf_6vhe4rqpd7b9917rngy7jdj58a` |
| author_name | `Cristobal Schlaubitz` |
| author_email | `cristobal.schlaubitz@bird.com` |
| Authorization | Bearer token — retrieve current token from memory |

**If token is missing or expired:** ask the user for a fresh token before submitting.

## Procedure

### Step 1: Verify Submission

After the session submits to Forge, confirm:
- [ ] PR was created on GitHub
- [ ] Forge submission was accepted (no error response)
- [ ] PR number is bound to the session: `fleet desc <name> --pr <N>`

**If submission failed:**
- **Invalid/expired token:** ask the user for a new token, then retry.
- **Missing required field:** check the spawn prompt included all Forge details, resend with `fleet send`.
- **Network error:** retry once. If it fails again, report to user.

### Step 2: Start Monitoring

The session should monitor its own PR using a polling loop. If Forge submission instructions were in the spawn prompt, the session handles this automatically.

- **If the session is idle and not monitoring:** nudge it:
  ```
  fleet send <name> "Monitor your PR until merged. Check every 2 minutes. If CI fails, fix and push. If review comments come in, address them."
  ```
- **If the session context-compacted and lost the monitoring task:** kill and respawn with a focused monitoring prompt on the existing branch:
  ```
  fleet spawn monitor-<name> <repo> "Monitor PR #<N> on branch <branch>. If CI fails, fix and push. If review comments come in, address them. Monitor until merged." --worktree --branch <branch>
  ```

### Step 3: Handle Rejection

If the PR is rejected by reviewers or Forge:

1. **Rebase on latest main:**
   ```
   fleet send <name> "PR was rejected. Rebase on origin/main: git fetch origin main && git rebase origin/main. Then fix the issues raised and resubmit."
   ```
2. **If rebase has conflicts:** the session should resolve them. If it can't, it reports to the captain.
3. **After fixing:** session pushes and resubmits to Forge.
4. **Resume monitoring** from Step 2.

**If rejected 3+ times:** escalate to the user. There may be a fundamental issue the session can't resolve autonomously.

### Step 4: Handle Merge

When the PR is merged:

1. Session reports completion — goes idle or Fleet Events shows merge.
2. Captain verifies: `fleet pr <name> --once` or check GitHub.
3. Report to the user: "PR #N merged for <feature>."
4. Follow [[workflow-killing]] to clean up the session.

## Success Criteria

- [ ] PR submitted to Forge with correct credentials
- [ ] Monitoring active until terminal state (merged or abandoned)
- [ ] Rejections handled with rebase + fix + resubmit
- [ ] Merge reported to user
- [ ] Session cleaned up after merge via [[workflow-killing]]
