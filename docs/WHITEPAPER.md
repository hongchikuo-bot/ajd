# The Multi-Agent Monitoring Problem

<!-- toc: true -->

## Abstract

A whitepaper on the architectural principles of multi-agent job monitoring systems. This document abstracts a practical production-scale example into generic design patterns that other teams can adopt without exposing personal data or vendor-locked specifics.

---

## 1. The Problem Space

### 1.1 Why Multi-Agent Monitoring is Hard

Modern AI agent ecosystems grow organically:  
- **Personal setups**: One person runs 5–15 agents for different purposes (news, stocks, content creation)  
- **Organic coupling**: Agents depend on each other's outputs (`news_auto` feeds `video render` which notifies `LINE`)  
- **Silent failures**: Cron says "I ran" ≠ job actually completed; file timestamps lag behind real runtime  

**The fundamental problem**: You need a system that survives chaos — missing cron entries, network partitions, agent crashes — while keeping operational overhead low.

### 1.2 The Heartbeat Pattern

Most orchestration frameworks (Airflow, Prefect) assume the scheduler is king:  
> The system *can* see a job's state because the scheduler wrote it down.

But that's backwards in agent ecosystems. **The inverse truth**:
> Cron says "I ran" ≠ success; files look old but may have failed halfway.  
> **Only an active heartbeat tells the real story**.

```bash
# Generic HTTP POST — any language can do this
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"daily-report","status":"ok","note":"2.1MB PDF"}'
```

No framework, no token, no auth — just JSON over HTTP. This is the **heartbeat pattern**.

---

## 2. Architectural Principles

### 2.1 Generic Adapter Layer

AJD doesn't assume *how* you run jobs. It assumes they **report** to it:

| Layer | Responsibility | Why Generic? |
|-------|----------------|---------------|
| Schedulers | crontab / launchd / systemd / Hermes cron | Different OS, different tooling |
| Services | port check / HTTP health / Docker | Some are processes, some containers |
| Adapter | Normalizes output → unified JSON | Core only reads this format |

**Core philosophy**:  
> **Don't guess how things work; ask them.**  
> Let each job declare its heartbeat endpoint. The core stays simple.

### 2.2 Heartbeat as the Source of Truth

A naive dashboard shows "last run: 10h ago" (file timestamp).  
AJD's dashboard shows "heartbeat: 2m ago, status: ok".

Compare:

| Metric | File-timestamp approach | Heartbeat approach |
|--------|-------------------------|--------------------|
| Detects mid-run failure | ❌ No (file exists) | ✅ Yes (status=failed) |
| Shows actual runtime | ❌ No (cron lied) | ✅ Yes |
| Cross-agent visibility | ❌ Impossible | ✅ Possible (via API) |

### 2.3 Local-Only Enforcement

AJD never uploads data:

```text
[❌ WRONG] POST https://cloud.example.com/upload → job=stock, path=/root/stock_auto
[✅ CORRECT] curl localhost → /api/state shows only your local state
```

This is a requirement, not an option. The code enforces:
- All paths must use `$AJD_HOME` or user-provided env
- Data directory is local-only (no backup to cloud)
- Heartbeats are logged locally; never sent externally except via configured webhook

---

## 3. Design Trade-offs

### 3.1 Why Not an API?

> **Q: Why don't you provide a REST API for creating jobs, reading backlog?**  
> A: Because that scope-creeps into *orchestration*, not *monitoring*.

AJD is deliberately minimal. The orchestration logic lives in:
- Your cron scripts
- Your job definitions (`projects.json`)
- Your heartbeat endpoints

We're a **dashboard**, not an orchestrator. That keeps us small and opinionated about what matters (visibility) without baking one workflow into another's.

### 3.2 Why Not Docker-Only?

> **Q: Can you run agents in containers?**  
> A: Yes, but we detect them via `docker` adapter, not force it.

Some jobs live on bare metal (`systemd`), some in `Kubernetes`, some in `Hermes cron`. Forcing one model breaks adoption. The generic adapter lets each user choose their runtime environment.

### 3.3 Why Not OAuth?

> **Q: Why no authentication?**  
> A: AJD's design principle is "local-only, trust the local machine".

Add auth if you need it (Heroku dynos, shared machines). On a personal M1/M3 Mac, `localhost` already limits exposure. The whitepaper focuses on *the model that works*, not *defensive programming for all threat models*.

---

## 4. Adoption Patterns

### 4.1 Pattern A: AI Agent User

```text
1. curl | bash → install.sh installs AJD engine + creates AGENTS.md
2. Your local agent (Hermes/Claude/...) reads AGENTS.md and adds:
   AJD_URL="http://localhost:5080/" to memories/config
3. install.sh prints confirmation with safety warnings ("AJD does NOT upload")
```

### 4.2 Pattern B: No Agent User

```text
1. Manual installation (SETUP.md guide)
2. Fill `projects.json` with job definitions
3. Start service, then monitor manually or via browser + PWA
```

### 4.3 Pattern C: Remote Monitoring

```text
1. Use cloud tunnel (cloudflared/ngrok) → expose to internet
2. Heartbeats still POST to *your* tunnel endpoint
3. Dashboard shows real-time status from your private network
```

---

## 5. Why This Matters

### 5.1 The 11-Bot Architecture Abstracted

Without revealing personal data, here's the core abstraction:

> **Problem**: Person X runs 11 bots: news (2), stock (1), content (6), utility (2)  
> Each has output dependencies; each has independent failures.  
> **Solution**: Single heartbeat API for visibility; local-first philosophy; no cloud dependency.

AJD's generalization:
- Any number of jobs (N)
- Any scheduler sources (S ∈ {crontab, systemd, docker...})
- Any service checks (P ∈ {port, HTTP status...})

### 5.2 Heartbeat as the Soul Project

> **Quote from project design notes**:  
> "The most valuable signal is 'ran but didn't report' — that's half-finished jobs you only see with heartbeat."

This single pattern:
- Detects cron job mid-run crashes (file exists, HTTP 500)
- Shows how long a job actually ran vs what cron says
- Correlates failures across agents sharing the same dashboard

---

## 6. Conclusion & Next Steps

### 6.1 What AJD Offers

| Feature | Traditional tools | AJD |
|---------|-------------------|-----|
| Monitoring focus | ❌ Only job queue | ✅ Completed + failed jobs |
| Heartbeat support | ❌ None (assumes success) | ✅ Yes (explicit status field) |
| Vendor lock-in | ❌ Airflow/Prefect proprietary | ✅ Any scheduler, any HTTP client |
| Local enforcement | ⚠️ Optional config | ✅ Required by design |

### 6.2 Who Should Use AJD

✅ You want:
- Low-overhead monitoring for local agents
- Visibility into failed jobs (not just "ran")
- No cloud dependency

❌ Don't use AJD if you need:
- Full orchestration with UI-driven job triggering
- Multi-user collaboration on same dashboard
- Vendor-managed infrastructure

### 6.3 Final Note

AJD is not a replacement for existing tools; it's a **complement** that fills the "monitoring gap". Use it alongside existing orchestrators to gain visibility into what they hide: mid-run failures, false successes, dependency hell.

---

## Appendix A: Heartbeat Format Schema

```json
{
  "job": "string (required)",           // job name from projects.json
  "project": "string (optional)",       // project identifier if using depends_on
  "status": "ok|failed",                // core requirement — no guessing allowed
  "note": "string (optional)",          // e.g., file size, error message
  "duration_s": number|null             // runtime in seconds if available
}
```

## Appendix B: Example Heartbeat Endpoint URLs

- Local dashboard: `http://localhost:5080/api/heartbeat`  
- Remote via tunnel: `https://your-tunnel.ngrok.io/ai-jobs-monitoring/api/heartbeat`  

**Always POST to `/api/heartbeat` on your machine, never expose /api/state or /api/schedulers externally without auth.**

---

## 9. Operational Mode

### 9.1 Daily Health Checks

AJD runs silently in the background. Your agent (or cron) fires heartbeats every time a job completes:

```python
# Python example - your job's cleanup routine
import requests, json

requests.post(
    "http://localhost:5080/api/heartbeat",
    json={
        "job": "daily-report",
        "status": "ok",
        "note": f"Generated {len(generated_files)} files"
    }
)
```

**No heartbeat after expected time?** That's your failure signal. Check the job script, not the file system.

### 9.2 Failure Scenarios Handled

| Scenario | File-timestamp approach | Heartbeat approach |
|----------|-------------------------|--------------------|
| Job hangs mid-run | ❌ File exists but incomplete | ✅ `status: failed` reported |
| Cron fires, script crashes | ❌ Empty error log | ✅ `status: error` with message |
| Network partitions | ❌ Can't tell if job ran | ✅ Last known good heartbeat shown |
| Agent restarts | ❌ Lost state info | ✅ Heartbeat resume from last point |

### 9.3 Backlog Recovery

AJD tracks a backlog of jobs that haven't heartbeated:

```text
Backlog queue: 2 jobs (news_daily_0, stock_morning_1)
→ Agent reruns on next conversation
→ Manual trigger via `ajd --retry <job-id>` (SETUP.md)
```

This is crucial for high-stakes workflows (daily reports, compliance logs).

---

## 10. Deployment Reference

### 10.1 Minimal Docker Setup

```dockerfile
# Dockerfile - single service container
FROM python:3.12-slim
WORKDIR /app
COPY app/ ./app
RUN pip install -r requirements.txt
EXPOSE 5080
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:5080"]
```

**Why single-container?** Keep it simple. Your heartbeat endpoints can be any service — even external webhooks. AJD doesn't need a monolith.

### 10.2 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AJD_HOST` | 0.0.0.0 | Bind address |
| `AJD_PORT` | 5080 | HTTP port |
| `AJD_LOG_LEVEL` | info | Logging verbosity |

### 10.3 Service Health Check

The dashboard exposes `/api/state`:

```bash
curl http://localhost:5080/api/state
# {"jobs": ["news_daily"], "backlog": [], "status": "ok"}
```

Use this in your own monitoring (Prometheus, Datadog, or custom scripts).

---

## 11. Extending AJD

### 11.1 Adding a New Scheduler Adapter

Create in `$ADAPTERS_DIR/adapters.py`:

```python
# example extension
from ajd.adapters import SCHEDULER, SchedulerAdapter

@SCHEDULER.register("systemd")
class SystemdAdapter(SchedulerAdapter):
    def discover(self, base_dir: str):
        # Parse /etc/systemd/timers.d/
        return {"unit": "my-job.timer", "pattern": ".log"}
```

The adapter protocol stays stable. Core doesn't care how you run jobs — only that they heartbeat.

### 11.2 Custom Heartbeat Format

If your backend can't POST JSON directly, create a webhook listener:

```bash
# Run anywhere - systemd service, Docker sidecar, etc.
curl -X POST http://localhost:3000/heartbeat \
     -H 'Content-Type: application/json' \
     -d @status.json
```

AJD receives it at `/proxy/your-service` and routes accordingly.

### 11.3 Contributing Guidelines

1. Fork the repo
2. Add adapter to `$ADAPTERS_DIR/adapters.py`
3. Document in docs/ADAPTERS.md
4. Submit PR with test cases

See `.github/CONTRIBUTING.md` for guidelines.

---

## 12. Security Considerations

### 12.1 Local-Only Philosophy

AJD assumes a trusted machine:
- No external API endpoints (except configured webhooks)
- Heartbeats logged to local file system only
- User-provided paths via environment variables

**Never expose `/api/state` to the internet without**:
- Network segmentation
- TLS termination at edge
- Rate limiting middleware

### 12.2 Path Sanitization

User-supplied paths are validated:

```python
import os.path

def validate_path(path: str, allowed_base: str) -> str:
    real = os.path.realpath(os.path.expandvars(path))
    real_base = os.path.realpath(allowed_base)
    if not real.startswith(real_base):
        raise ValueError("Path escapes base directory")
    return path
```

Prevents path traversal (`../`) and absolute path injection.

### 12.3 Rate Limiting

Heartbeats are rate-limited to prevent abuse:

```python
# app.py example - use Flask-Limiter or similar
@app.route("/api/heartbeat", methods=["POST"])
@limiter.limit("10 per minute")
def capture_heartbeat():
    ...
```

Adjust limits based on your heartbeat frequency.

---

## 13. Comparison with Alternatives

| Feature | AJD | Airflow | Prefect | Custom cron scripts |
|---------|-----|---------|---------|---------------------|
| Heartbeat-first design | ✅ Yes | ❌ Scheduler-centric | ⚠️ Partial | ❌ No |
| Local-only enforcement | ✅ Yes | ⚠️ Cloud-first | ⚠️ Hybrid | ✅ Yes (but no cross-view) |
| Generic adapter layer | ✅ Yes | ❌ Custom per source | ⚠️ Plugin system | ❌ None |
| Zero-auth setup | ✅ Yes | ⚠️ Optional OIDC | ⚠️ Optional auth | ✅ Yes |
| Cross-agent visibility | ✅ Yes (via API) | ❌ Airflow-only | ❌ Prefect-only | ❌ Impossible |

**AJD's niche**: Lightweight, heartbeat-driven visibility for heterogeneous agent ecosystems.

---

## 14. License

AJD is released under the MIT License. See `./LICENSE` for details.

Key contributions:
- Heartbeat pattern abstraction (inspired by kk's production setup)
- Generic adapter interface (enables multi-scheduler support)
- Local-only enforcement (privacy-first design)

---

*Version*: 0.5.1-alpha (Phase 8 Whitepaper Enhancement)  
*Status*: Ready for GitHub publish  
*License*: MIT
