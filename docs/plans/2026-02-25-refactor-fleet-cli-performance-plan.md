---
title: Fleet CLI Performance Optimizations
type: refactor
status: completed
date: 2026-02-25
deepened: 2026-02-25
---

# Fleet CLI Performance Optimizations

## Enhancement Summary

**Deepened on:** 2026-02-25
**Review agents used:** TypeScript reviewer, Performance oracle, Code simplicity reviewer, Architecture strategist, Pattern recognition specialist

### Key Improvements from Review
1. **`Promise.allSettled` over `Promise.all`** — One failed `gh pr view` or tmux call must not crash the entire status output. Use `allSettled` with fallback values for resilience.
2. **Eliminate `sessionExists` as separate subprocess** — The `tmux display-message` call already returns non-zero when a session doesn't exist. Checking exit code eliminates 1 extra subprocess per session (5 saved for 5 sessions).
3. **Simplify mutation pattern** — Replace the mutation collection array with a return-value approach: `resolveFeaturePrDisplay` returns `{ pr, ci, discoveredPrNumber }`, callers apply updates after the loop. No shared mutable arrays.
4. **`bun build --compile`** — Compiling the fleet script to a native binary cuts Bun startup from ~50ms to ~10ms. Zero architectural changes, zero risk.
5. **Parameterize `tmuxSend` sleep** — Use 300ms for `spawn` (shell init risk), 200ms for `send`/`relay` (Claude readline is already waiting).
6. **Use `\x1f` delimiter consistently** — Plan text and code examples now unified on ASCII Unit Separator.

### New Issues Discovered
- `check` command (line 550) has the same double-capture as `status` — must also use returned content
- `watch` initial snapshot loop (lines 773-775) is also sequential — must also parallelize
- `grep` pattern in fleet-inject uses `\s` which is not POSIX ERE on macOS — use `[[:space:]]`
- PR cache writes also race in parallel — same batching needed as registry

## Overview

The fleet CLI (`config/.claude/skills/fleet-captain/scripts/fleet`) has noticeable latency on common operations. `fleet status` with 5 sessions takes ~375ms. More critically, `fleet poll` — which runs on **every user prompt** via the `UserPromptSubmit` hook — adds ~255ms of latency to every Claude interaction. This plan addresses all identified bottlenecks, reducing `fleet status` to ~65ms and `fleet poll` to ~70ms.

## Problem Statement

Three root causes account for ~90% of the latency:

1. **Sequential subprocess spawning** — Every multi-session command (`status`, `poll`, `check-active`, `watch`) loops through features sequentially, awaiting 3-5 tmux subprocesses per feature. With 5 sessions, this means 15-25 sequential tmux calls (~200ms) when they could all run in parallel (~20ms).

2. **Redundant tmux calls** — `checkSessionState` makes 1 `has-session` + 3-4 separate `display-message` calls that could be replaced by a single `display-message` with a combined format string. Additionally, `status` and `check` capture pane content twice for idle sessions.

3. **Redundant file I/O** — Registry and PR cache files are re-read from disk on every loop iteration even though they don't change during a single command invocation.

## Proposed Solution

Nine optimizations organized into three phases by impact and dependency.

## Technical Approach

### Phase 1: Parallelization (highest impact, ~180ms saved on poll)

#### Task 1.1: Batch tmux calls and eliminate `sessionExists` in `checkSessionState`

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 168-171 (sessionExists), 191-217 (checkSessionState), 157-159 (tmuxGet)

Currently `checkSessionState` makes 1 `has-session` + up to 4 `display-message` calls = up to 5 subprocess spawns per session (~50ms). The `sessionExists` call is a hidden extra subprocess the original plan missed.

Replace with a single `display-message` call using a combined format string. If the session doesn't exist, `tmux display-message` exits non-zero — check the exit code instead of a separate `has-session` call:

```typescript
const SEP = "\x1f"
const FMT_STATE = `#{pane_current_command}${SEP}#{pane_dead}${SEP}#{pane_dead_status}${SEP}#{pane_title}`

type SessionStateResult = { state: string; content: string | null }

async function checkSessionState(target: string, captureLines = 5): Promise<SessionStateResult> {
  const result = await $`tmux display-message -t ${target} -p ${FMT_STATE}`.quiet().nothrow()
  if (result.exitCode !== 0) return { state: "gone", content: null }

  const [cmd, dead, deadStatus, title] = result.text().trim().split(SEP)

  if (cmd !== "claude") {
    if (dead === "1") {
      return { state: deadStatus === "0" ? "exited" : `crashed:${deadStatus}`, content: null }
    }
    return { state: "exited", content: null }
  }

  if (title.startsWith("✳")) {
    const lines = (await $`tmux capture-pane -t ${target} -p`.quiet().nothrow()).text().split("\n")
    const lastNonEmpty = lines.findLastIndex(l => l.trim() !== "")
    const content = lines.slice(Math.max(0, lastNonEmpty - (captureLines - 1)), lastNonEmpty + 1).join("\n")
    const stateContent = lines.slice(Math.max(0, lastNonEmpty - 4), lastNonEmpty + 1).join("\n")
    if (/\[y\/n\]|\[Y\/n\]|\[yes\/no\]/.test(stateContent)) return { state: "blocked", content }
    if (/Enter to select|Space to select|to confirm|to navigate/.test(stateContent)) return { state: "picker", content }
    return { state: "idle", content }
  }

  return { state: "working", content: null }
}
```

Key design decisions:
- **`captureLines` parameter** — `poll` passes 5 (only needs state), `status`/`check-active`/`check` pass 20 (need display content). Avoids coupling state detection to display concerns.
- **`\x1f` delimiter** — ASCII Unit Separator. Cannot appear in pane titles, command names, or exit codes.
- **Exit code replaces `sessionExists`** — Eliminates 1 subprocess per session. `tmux display-message` to a nonexistent target exits non-zero.

**Impact:** 5 subprocess spawns → 1 (+ 1 conditional `capture-pane`). Saves ~40ms per session.

#### Task 1.2: Eliminate double capture-pane in `status`, `check-active`, and `check`

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 208+501-503 (status), 585-591 (check-active), 539-552 (check)

With `checkSessionState` now returning `{ state, content }`, all three commands use the returned content instead of re-capturing:

```typescript
// status command — use returned paneContent
const rows = results
  .filter((r): r is PromiseFulfilledResult<...> => r.status === "fulfilled")
  .map(r => r.value)

for (const row of rows) {
  if (["idle", "blocked", "picker"].includes(row.state) && row.paneContent) {
    console.log(`\nPANE:${row.name}`)
    console.log(row.paneContent)
  }
}
```

Also update `check` (line 550) — it has the same double-capture pattern that the original plan missed.

**Impact:** Eliminates 1 tmux subprocess per idle/blocked/picker session per call.

#### Task 1.3: Parallelize per-feature loops with `Promise.allSettled`

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 487-494 (status), 565-572 (check-active), 773-775 (watch initial snapshot), 807-822 (watch/collectStateChanges), 1029-1040 (poll)

Use `Promise.allSettled` (not `Promise.all`) for resilience — one failed `gh pr view` or tmux call must not crash the entire command output:

```typescript
// status command
const prCache = readPrCache()
const results = await Promise.allSettled(
  active.map(async ([name, feat]) => {
    const [stateResult, branch, prCi] = await Promise.all([
      checkSessionState(feat.tmuxSession, 20),
      resolveFeatureBranch(feat),
      resolveFeaturePrDisplay(name, feat, prCache),
    ])
    return {
      name,
      state: stateResult.state,
      repo: basename(feat.repo),
      branch,
      pr: prCi.pr,
      ci: prCi.ci,
      title: feat.title || name,
      tmuxTarget: `${feat.tmuxSession}:claude`,
      paneContent: stateResult.content,
      discoveredPrNumber: prCi.discoveredPrNumber,
    }
  })
)

const rows = results
  .filter((r): r is PromiseFulfilledResult<typeof results[number] extends PromiseSettledResult<infer T> ? T : never> => r.status === "fulfilled")
  .map(r => r.value)

// Apply discovered PR numbers after parallel work completes
for (const row of rows) {
  if (row.discoveredPrNumber) {
    updateFeature(row.name, { pr: { number: row.discoveredPrNumber, ciStatus: "unknown", lastChecked: ts() } })
  }
}
writePrCache(prCache)
```

Apply to all five sites:
- `status` (lines 487-494) — full parallel with PR resolution
- `check-active` (lines 565-572) — full parallel with PR resolution
- `watch` initial snapshot (lines 773-775) — parallel state checks only
- `watch`/`collectStateChanges` (lines 807-822) — parallel state checks only
- `poll` state detection (lines 1029-1040) — parallel state checks only

`poll` and `watch` are simpler — they only call `checkSessionState`, not `resolveFeatureBranch` or `resolveFeaturePrDisplay`.

**Impact:** O(N × 20ms) → O(20ms). With 5 sessions, saves ~80ms on `poll`, ~160ms on `status`.

### Phase 2: File I/O Reduction & Side-Effect Cleanup

#### Task 2.1: Make `resolveFeaturePrDisplay` pure — return `discoveredPrNumber`

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 296-328 (resolveFeaturePrDisplay), 304 (readPrCache), 309+323 (updateFeature side effects)

Currently `resolveFeaturePrDisplay` has two side effects: it calls `readPrCache()` (N file reads) and `updateFeature()` (N registry reads/writes). Both cause races when parallelized.

Make it pure by accepting pre-read cache and returning discovered PR numbers instead of writing:

```typescript
async function resolveFeaturePrDisplay(
  name: string,
  feat: Feature,
  prCache?: Record<string, PrCacheEntry>,
): Promise<{ pr: string; ci: string; discoveredPrNumber?: number }> {
  if (feat.pr?.number) {
    const ci = feat.pr.ciStatus && feat.pr.ciStatus !== "unknown" ? feat.pr.ciStatus : "—"
    return { pr: `#${feat.pr.number}`, ci }
  }

  if (!feat.branch) return { pr: "—", ci: "—" }

  const cache = prCache ?? readPrCache()
  const cacheKey = `${feat.repo}:${feat.branch}`
  const cached = cache[cacheKey]
  if (cached && (Date.now() - new Date(cached.checkedAt).getTime()) < PR_CACHE_TTL) {
    return cached.number
      ? { pr: `#${cached.number}`, ci: "—", discoveredPrNumber: cached.number }
      : { pr: "—", ci: "—" }
  }

  const result = await $`gh pr view ${feat.branch} --repo ${feat.repo} --json number -q .number`.quiet().nothrow()
  const num = parseInt(result.text().trim())
  const prNumber = isNaN(num) ? null : num

  cache[cacheKey] = { number: prNumber, checkedAt: ts() }
  // Note: cache object is mutated in place, caller writes once after loop

  if (prNumber) return { pr: `#${prNumber}`, ci: "—", discoveredPrNumber: prNumber }
  return { pr: "—", ci: "—" }
}
```

Callers read PR cache once before the loop, pass it in, and write once after. The `discoveredPrNumber` is applied to the registry after all parallel work completes (see Task 1.3 code). Single-feature callers like `check` omit the cache parameter and get the old behavior.

**Impact:** N PR cache reads → 1. N registry reads/writes → 1 write. No shared mutable arrays, no mutation collection infrastructure.

#### Task 2.2: Cache `getOwnerRepo` result

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 624-628 (getOwnerRepo), 639 (called in fetchCiSnapshot)

Add a module-level cache:

```typescript
const ownerRepoCache = new Map<string, string>()

async function getOwnerRepo(repoPath: string): Promise<string> {
  const cached = ownerRepoCache.get(repoPath)
  if (cached !== undefined) return cached
  const remote = (await $`git -C ${repoPath} remote get-url origin`.quiet().nothrow()).text().trim()
  const match = remote.match(/github\.com[:/](.+?)(?:\.git)?$/)
  const result = match ? match[1] : ""
  ownerRepoCache.set(repoPath, result)
  return result
}
```

**Impact:** Eliminates redundant `git remote get-url origin` calls in `pr --poll` loop (~10ms × poll iterations).

### Phase 3: Quick Wins

#### Task 3.1: Batch `list` command into single tmux call

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 1193-1208 (list command)

Currently: 1 `list-sessions` + N × (`show-option` + `tmuxGet`) = 1 + 2N tmux calls.

Replace with a single format-string call:

```typescript
fleet.command("list")
  .description("List fleet-managed tmux sessions")
  .action(async () => {
    const fmt = `#{session_id} #{session_name} #{@fleet_managed} #{pane_current_command} #{@claude_task}`
    const sessions = (await $`tmux list-sessions -F ${fmt}`.quiet().nothrow()).text().trim()
    if (!sessions) return

    for (const line of sessions.split("\n")) {
      const [id, sname, managed, cmd, ...taskParts] = line.split(" ")
      if (managed !== "1") continue
      const task = taskParts.join(" ").trim()
      console.log(`ID=${id} NAME=${sname} CMD=${cmd}${task ? " TITLE=" + task : ""}`)
    }
  })
```

**Impact:** 1 + 2N tmux calls → 1 call. With 5 managed sessions: 11 → 1.

#### Task 3.2: Parameterize `tmuxSend` sleep

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`
**Lines:** 161-166 (tmuxSend)

Use 300ms for `spawn` (shell may not have initialized) and 200ms for `send`/`relay` (Claude readline is already waiting):

```typescript
async function tmuxSend(session: string, text: string, sleepMs = 200) {
  await $`tmux send-keys -t ${session}:claude C-u`.quiet()
  await $`tmux send-keys -t ${session}:claude -l ${text}`.quiet()
  await Bun.sleep(sleepMs)
  await $`tmux send-keys -t ${session}:claude Enter`.quiet()
}
```

`spawn` calls `tmuxSend(session, text, 300)`. All other callers use the default 200ms.

**Impact:** Saves 700-800ms per message. Spawn saves 1.4s total (2× tmuxSend).

#### Task 3.3: Optimize fleet-inject with shell-native registry check

**File:** `config/.claude/skills/fleet-captain/scripts/fleet-inject`
**Lines:** 12 (jq call)

Replace `jq` with portable `grep` (note: `\s` is not POSIX ERE on macOS BSD grep):

```bash
# New: shell-native check (~1ms), portable across macOS/Linux
grep -qE '"status"[[:space:]]*:[[:space:]]*"(active|blocked)"' "$REGISTRY" || exit 0
```

This is an approximation (matches raw JSON text, not parsed). False positives possible if a description field contains `"status": "active"` literally. Acceptable tradeoff for a 19ms saving on the cold path.

**Impact:** Saves ~19ms on every prompt when no active sessions exist.

#### Task 3.4: Compile fleet to native binary

**File:** `config/.claude/skills/fleet-captain/scripts/fleet`

Compile the fleet script to a native binary using `bun build --compile`:

```bash
bun build --compile config/.claude/skills/fleet-captain/scripts/fleet --outfile config/.claude/skills/fleet-captain/scripts/fleet-bin
```

Update `fleet-inject` to use the compiled binary. Bun compiled binaries start in ~5-10ms vs ~50ms for interpreted scripts.

**Impact:** Saves ~40ms on every `fleet poll` invocation. Zero architectural changes, zero risk. This is the single largest remaining bottleneck after Phase 1 optimizations.

## Acceptance Criteria

- [x]`checkSessionState` makes exactly 1 `tmux display-message` call (no separate `has-session`) + 1 conditional `capture-pane`
- [x]`checkSessionState` returns `{ state, content }` with parameterized capture line count
- [x]`status`, `check-active`, `check`, `watch`, `poll` all use `Promise.allSettled` for per-feature loops
- [x]Failed features in parallel loops produce fallback values, not crashes
- [x]PR cache is read once before the loop via optional parameter
- [x]`resolveFeaturePrDisplay` is pure — returns `discoveredPrNumber` instead of calling `updateFeature`
- [x]Registry writes happen once after the loop, not per-feature
- [x]`getOwnerRepo` caches results in a module-level Map
- [x]`list` command uses a single `tmux list-sessions -F` call
- [x]`tmuxSend` sleep parameterized: 300ms for spawn, 200ms default
- [x]`fleet-inject` uses portable grep instead of jq for registry check
- [x]Fleet binary compiled with `bun build --compile` for ~40ms startup reduction
- [x]All existing commands produce identical output (behavioral parity)
- [x]`\x1f` delimiter used consistently in format string and split

## Success Metrics

| Command | Current | Target |
|---|---|---|
| `fleet status` (5 sessions, cached) | ~375ms | <80ms |
| `fleet poll` (5 sessions, every prompt) | ~255ms | <70ms (compiled) |
| `fleet watch` poll cycle | ~200ms + sleep | <30ms + sleep |
| `fleet list` (5 sessions) | ~120ms | <15ms |
| `fleet spawn` message delivery | ~2200ms (2× tmuxSend) | ~600ms |

## Dependencies & Risks

**Risk: Delimiter in tmux format output.** Use `\x1f` (ASCII Unit Separator) consistently in both the format string constant and the `split()` call. Non-printable control character that cannot appear in pane titles, command names, or exit codes.

**Risk: `Promise.allSettled` error swallowing.** Failed features produce fallback values (state="gone", branch="—", pr="—"). Log rejections to stderr for debugging but don't crash the command.

**Risk: PR cache concurrent mutations.** The pre-read `prCache` object is passed by reference and mutated in place by parallel `resolveFeaturePrDisplay` calls. Since JavaScript objects are single-threaded and mutations are to different keys (each feature has a unique `repo:branch` cache key), there's no actual race. A single `writePrCache(prCache)` after the loop captures all mutations.

**Risk: `tmuxSend` sleep reduction causes missed input.** The 1000ms sleep was conservative. Parameterized approach: 300ms for `spawn` (shell init may be slow), 200ms for `send`/`relay` (Claude readline is already listening). If flaky on `spawn`, bump to 500ms — still 50% improvement.

**Risk: `grep` approximation in fleet-inject.** Matches raw JSON text, not parsed. Could false-positive on descriptions containing `"status": "active"`. Acceptable for a guard that only skips the fast-exit path — worst case, `fleet poll` runs unnecessarily and exits immediately with no output.

**Risk: Compiled binary freshness.** After editing the fleet script, the compiled binary must be regenerated. Add a check in the build/deploy flow, or use a Makefile target.

## Sources

- Research analysis from conversation (2026-02-25)
- Fleet script: `config/.claude/skills/fleet-captain/scripts/fleet`
- Fleet inject hook: `config/.claude/skills/fleet-captain/scripts/fleet-inject`
- Bun subprocess benchmarks: ~888µs per `spawnSync` on Apple M1 Max (Bun docs)
- Review agents: TypeScript, Performance, Simplicity, Architecture, Pattern Recognition
