# Multi-Agent System Architecture: A Design Principle Reference

This document abstracts the practical patterns from a production-scale multi-agent deployment without exposing personal or sensitive information. It serves as a conceptual guide for engineers designing or evaluating agent orchestration systems.

---

## Executive Summary

Managing dozens of specialized agents at scale introduces common challenges—credential security, scheduling synchronization, health monitoring, and unified observability. This document codifies a practical architecture proven in real-world deployment: centralized registry, adapter pattern for heterogeneity, heartbeat-based failure detection, and clear ownership contracts between services.

---

## Architectural Principles

### 1. Local-First Privacy Presumption

All agent operations execute on the local machine using user-provided credentials stored in an encrypted vault (`.hermes` or equivalent). **No data is uploaded to external servers.** This aligns with standard Agent Safety Policies:

- Credentials never leave the user's device
- Project archives and monitoring snapshots remain local
- The dashboard serves only as a control plane, not a data plane

### 2. Adapter Pattern for Heterogeneous Integration

Agents run on diverse schedulers (crontab, launchd, systemd timers) and expose services via different health checks (port binding, HTTP endpoints, Docker container status). Rather than maintaining custom integration logic for each platform:

- Standardize outputs from all schedulers to a unified JSON schema
- Normalize service health signals through a pluggable adapter layer
- The core coordinator only recognizes the standardized format

This decouples the orchestration logic from deployment environment specifics.

### 3. Heartbeat-Based Failure Detection

Cron job exit codes alone are insufficient—processes can hang or fail to report completion due to unexpected interruptions. Require explicit heartbeat signals:

```bash
curl -X POST http://127.0.0.1:<port>/api/heartbeat \
     -H "Content-Type: application/json" \
     -d '{"job":"daily-news-report","status":"ok","note":"generated 5.4MB PDF"}'
```

The coordinator monitors heartbeat intervals. A missing signal beyond the threshold indicates a job that died mid-execution—a failure type invisible to filesystem timestamp inspection alone.

### 4. Zero API Surprises

Avoid assumptions about external services. For each integration point:

- Document required HTTP methods, headers, and payload schemas explicitly
- Provide validation tools (`ajd --check`) to verify deployment health before runtime
- Fail fast on missing paths or unreachable ports rather than relying on heuristics

---

## Deployment Topology

A typical multi-agent setup divides concerns across three layers:

```
┌─────────────────────────────────────────────────────┐
│  Agent Layer (User Devices)                          │
│  ├── Profile: default → Telegram + General Tasks     │
│  ├── Profile: stock → US Stock Monitoring            │
│  ├── Profile: news → Video Automation Pipeline       │
│  └── ... (up to N profiles per machine)              │
└─────────────────────────────────────────────────────┘
           ▲
           │ Health & Schedule Synchronization
           ▼
┌─────────────────────────────────────────────────────┐
│  Coordinator Layer (AJD Dashboard)                   │
│  ├── Job Registry (projects.json / DB)              │
│  ├── Heartbeat Listener                              │
│  ├── Failure Alerting (Telegram push)                │
│  └── Health Metrics Aggregation                       │
└─────────────────────────────────────────────────────┘
           ▲
           │ Local File & Service Access
           ▼
┌─────────────────────────────────────────────────────┐
│  Resource Layer (Local Machine or VM)                │
│  ├── Project Archives (/path/to/projects/*)         │
│  ├── Cron Jobs (via adapter)                         │
│  ├── Services (FastAPI, Docker containers)          │
│  └── Output Directories                               │
└─────────────────────────────────────────────────────┘
```

---

## Credential Management

Use a dedicated vault service for sensitive data rather than inline configuration:

- **Hermes**: `~/.hermes/profiles/<name>/.auth/vault.json` (encrypted)
- **Other agents**: Equivalent secure storage mechanism per platform

The vault must support:
- Login credentials (site identifiers + secrets)
- Payment tokens (if applicable)
- Custom fields (API keys, environment variables as strings)

Never hardcode secrets in scripts or configuration files accessible to the agent without encryption.

---

## Monitoring and Observability

### Metrics to Track Per Job

| Metric | Signal Type | Alert Threshold |
|--------|-------------|-----------------|
| `heartbeat_interval` | Gauge | > 2 × expected_interval |
| `job_duration_ms` | Histogram | 95th percentile spike |
| `output_size_bytes` | Counter | Unusually large (>10× normal) |
| `error_rate` | Counter | > 3 errors per N runs |

### Failure Escalation Path

1. **Soft failure**: Heartbeat missing, job restarts automatically
2. **Hard failure**: Consecutive soft failures → Telegram alert with stack trace excerpt
3. **Block escalation**: Persistent issues → triage queue for human review

---

## Integration Patterns

### Scheduler Adapter Examples

| Platform | Health Signal | Standard Output Format |
|----------|---------------|------------------------|
| crontab  | File timestamp check | `{"scheduler":"crontab","job":"mytask","started_at":"2026-10-17T08:00:00Z"}` |
| launchd | plist job event log | See adapter layer for normalization |
| systemd  | timer unit journal entries | Parse `journalctl -u <timer>` entries |

### Service Health Adapter

```json
{
  "type": "http_health",
  "port": 8010,
  "expected_response_text": ["Hello from ET Hubs!", "AI Education Hub"],
  "health_endpoint": "/api/health"
}
```

Docker container status checks use the container orchestrator's health endpoints rather than probing internal ports directly.

---

## Common Pitfalls to Avoid

### 1. Path Space Assumptions
Shell commands and JSON paths must not contain spaces. Enforce this in deployment scripts:

```bash
#!/bin/bash
set -uE
# Fail immediately on space-containing paths
if [[ "$HOME" == *" "* ]]; then
  echo "Error: Spaces in home directory are not supported." >&2
  exit 1
fi
```

### 2. Git History Contamination
When releasing an open-source package, always create a fresh repository. Never reuse private git history that may contain secrets or non-generic project data.

### 3. Unclosed API Endpoints in Documentation
Every endpoint referenced in `AGENTS.md` must exist in the actual application codebase. Document endpoints that don't yet exist as "future phases" and remove them before release.

---

## Testing Checklist for New Integrations

- [ ] Path validation: Verify all file paths with `ls` before reference in scripts
- [ ] Syntax check: Run `bash -n script.sh` for all shell scripts, `python3 -m py_compile module.py` for Python
- [ ] Port accessibility: Confirm service is reachable via `curl http://localhost:<port>/health`
- [ ] No personal traces: `grep -rIl "personal_string" .` returns zero results
- [ ] Generic schema compliance: `projects.example.json` should contain only template values

---

## License and Attribution

This design document abstracts patterns from practical deployments. The original production system operates under a local license agreement. AJD, the open-source release of these patterns, is licensed under MIT per `LICENSE`.

When adapting these principles to your own work:
- Credit where inspiration was drawn (optional but appreciated)
- Review and follow any third-party dependencies' licenses
- Do not copy proprietary code or internal tooling from the original system

---

## References

- [`AGENTS.md`](../../AGENTS.md): Agent setup instructions for Hermes, Claude, Cursor
- [`SETUP.md`](../../SETUP.md): Manual deployment guide (no AI agent)
- [`PROJECTS_SCHEMA.md`](../../docs/PROJECTS_SCHEMA.md): Formal JSON Schema specification
- [`CHANGELOG.md`](../../CHANGELOG.md): Version history and feature releases
