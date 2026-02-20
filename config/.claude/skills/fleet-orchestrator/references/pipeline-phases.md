# Pipeline Phases

## State Machine

```
spawned → brainstorm → plan → work → review → simplify → pr_monitoring → done

Any phase can transition to: crashed (abnormal exit) or abandoned (user kills)
crashed → same phase (via restart)
```

## Phase Commands

| Phase | Command | Notes |
|-------|---------|-------|
| brainstorm | `/workflows:brainstorm <description>` | May trigger AskUserQuestion for clarification |
| plan | `/workflows:plan` | Auto-detects brainstorm doc from `docs/brainstorms/` (last 14 days) |
| work | `/workflows:work` | Auto-detects plan doc. May use teams internally (swarm mode). Creates PR. |
| review | `/workflows:review latest` | Spawns parallel review subagents. Produces todo findings. |
| simplify | `"Run the code-simplifier agent on changes in this branch. Iterate until nothing left to simplify."` | Natural language, not a slash command |
| pr_monitoring | (none) | Orchestrator polls `gh pr view` for CI status |
| slfg (full-auto) | `/slfg <description>` | End-to-end: plan, work, review, resolve, video |

## Internal Team Usage

| Phase | Teams? | Details |
|-------|--------|---------|
| work | Sometimes | Swarm mode creates TeamCreate with implementer + tester |
| All others | No | Single agent or parallel subagents (not teams) |

Orphaned team directories (`~/.claude/teams/work-*`) should be cleaned up during feature kill.

## PR Monitoring

```bash
gh pr view $pr_number --repo $repo --json statusCheckRollup,reviews,mergeable,state
```

| CI conclusion | Maps to |
|---------------|---------|
| `"SUCCESS"` | passing |
| `"FAILURE"` | failing |
| `null` | pending |

Alert conditions: CI failed, review requested, CI passed + approved (ready to merge), PR merged (transition to `done`).
