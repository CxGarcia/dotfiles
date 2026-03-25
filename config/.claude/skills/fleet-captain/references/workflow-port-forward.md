# Port-Forward Management Workflow

> Procedures for managing kubectl port-forwards and background monitoring processes that fleet sessions depend on.

## Port-Forward Setup

### Step 1: Start Auto-Reconnecting Port-Forward

Use an auto-reconnecting loop to handle connection drops:

```bash
while true; do kubectl port-forward -n <namespace> svc/<service> <local-port>:<remote-port>; sleep 1; done
```

Run with the Bash tool using `run_in_background: true`.

**If port is already in use:** kill the existing process first (`pkill -f "kubectl port-forward.*<service>"`), then start fresh.
**If kubectl context is wrong:** switch context before starting: `kubectl config use-context <context>`.

### Step 2: Verify Connectivity

After starting, verify the port-forward is working:

```bash
curl -s localhost:<local-port>/health || echo "Not ready"
```

- **Healthy response:** proceed.
- **No response:** wait 3 seconds, retry. If still failing after 3 attempts, check:
  - Is the pod running? `kubectl get pods -n <namespace>`
  - Is the service correct? `kubectl get svc -n <namespace>`
  - Are there network policies blocking? Check with the user.

## Q Monitor Setup

For Forge queue monitoring or similar background processes that need API keys.

### Step 1: Start with nohup

```bash
nohup env FORGE_API_KEY=<key> <monitoring-command> &
```

- **FORGE_API_KEY must be set correctly** — retrieve from environment or memory.
- Use `nohup` to survive terminal disconnects.

**If the key is missing:** ask the user.

### Step 2: Verify the Monitor

```bash
ps aux | grep <monitoring-command>
```

- **Process found:** monitor is running.
- **Process not found:** check `nohup.out` for errors, then restart.

## Cleanup

Kill background processes when no longer needed:

```bash
# Kill port-forward loop
pkill -f "kubectl port-forward.*<service>"

# Kill Q monitor
pkill -f "<monitoring-command>"
```

Run cleanup when:
- All fleet sessions that depend on the port-forward are killed
- User explicitly asks to stop
- Switching to a different cluster/context

## Success Criteria

- [ ] Port-forward running with auto-reconnect loop
- [ ] Connectivity verified
- [ ] Background monitors started with correct API keys
- [ ] Cleanup executed when no longer needed
