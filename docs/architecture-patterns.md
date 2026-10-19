# Multi-Agent System Design Patterns

> **AJD Architecture Principles** – A guide to decomposing monolithic dashboards into portable, composable agent workflows.

---

## Why This Matters

Most "personal" dashboards couple the monitoring engine directly to:
- The user's file system (reads their cron, logs, and data)
- Their specific agent framework (Hermes, etc.)
- Hard-coded service URLs and credentials

This prevents portability. **AJD decouples these layers.**

---

## Core Principles

### 1. Engine is Generic, Config is Personal

The core application reads:
- `projects.json` – user-defined job registry
- Standard adapter outputs (scheduler, service health)

It never assumes who runs cron jobs or which agent orchestrates them.

### 2. Adapter Pattern for Schedulers

```
+----------+      +------------------+      +------------+
|          |      |                  |      |            |
|  Cron    +----->| SchedulerAdapter |----->|   Core     |
|  File    |      | (crontab/launchd)|      | App Server |
|          |      |                  |      | (FastAPI)  |
+----------+      +------------------+      +------------+

+----------+      +------------------+      +------------+
|          |      |                  |      |            |
| Hermes   +----->| SchedulerAdapter |----->|   Core     |
| Cron     |      | (hermes cron API)|      | App Server |
|          |      |                  |      | (FastAPI)  |
+----------+      +------------------+      +------------+
```

Each adapter normalizes output to a **single JSON schema** that the core recognizes.

### 3. Adapter Pattern for Service Health

Same principle for services:
- Port check (HTTP status code)
- HTTP health endpoint (`GET /health`)
- Docker container inspection

All produce identical `{"status": "ok" | "failed", "msg": "..."}` responses.

### 4. Heartbeat as a Universal Signal

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"daily-report","status":"ok","note":"3.2MB"}'
```

**No agent-specific protocol**. Any language/framework can emit this.

### 5. Agent-Neutral Configuration

The `AGENTS.md` file (installed alongside the dashboard) tells any AI agent how to configure:
- Path to `projects.json`
- How to interpret `/api/heartbeat` events
- Security constraints (no uploads, read-only access to monitored data)

An agent detection heuristic in `install.sh` will print the correct setup command for:
- Hermes (`~/.hermes/profiles/`)
- Claude (`.claude/config.json`)
- Cursor (project-local `.cursorrules`)
- Or none → direct users to `SETUP.md`

---

## Implementation Guide

### Step 1: Decompose Your Current Dashboard

Identify these layers in your existing setup:
- **Engine**: Core logic for state checking, heartbeat listening, UI rendering
- **Scheduler reader**: Code that parses cron files or Hermes schedules
- **Service checker**: Code that pings external services
- **Config schema**: JSON structure for job definitions

Strip personal data from each layer to build portable adapters.

### Step 2: Define Standard Formats

Create these specs (YAML/JSON):

```yaml
# Standard heartbeat contract
heartbeat:
  job: string          # Name of the cron job
  status: ok|failed    # Pass/fail
  note?: string        # Optional details (e.g. file size, error stack)

# Standard scheduler output
project:
  name: string
  type: cron|hermes|systemd|manual
  entry:
    script: string     # Path to the job script
    output_dir: string # Where its logs/reports live
```

### Step 3: Write Adapter Interfaces

Each adapter returns a unified schema:

**Scheduler adapter:**
- Input: Path to cron file / Hermes profile
- Output: `[{name, type, scheduled_time, status}]`

**Service adapter:**
- Input: URL or port config
- Output: `[{"id", "status": "up"|"down", "port", "protocol"}]`

### Step 4: Build the Core Around these Standards

Your FastAPI app (or any framework) can now:
- Accept any scheduler adapter output
- Handle any heartbeat format
- Render a consistent dashboard UI

No more tight coupling to one cron system or agent.

---

## Security Checklist

When configuring an agent with AJD, enforce these rules in `AGENTS.md`:

1. **Read-only for monitored data**: Never modify the projects being tracked
2. **No external uploads**: Everything runs locally under `$AJD_HOME`
3. **No credentials in logs**: Sanitize output before logging
4. **Heartbeat endpoint is local only**: Bind to localhost; don't expose publicly

---

## Migration Path

For users moving from a monolithic dashboard to AJD:

```bash
# 1. Install AJD
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# 2. Edit projects.json (fill your jobs)
vi $AJD_HOME/projects.json

# 3. Configure cron or agent scheduler (via install.sh output)

# 4. Open http://localhost:5080/ and watch heartbeats arrive
```

**No code changes needed** in your job scripts! Just update `projects.json`.

---

## Versioning

- **v0.5.0**: Manual setup (`SETUP.md`), one-command install, heartbeat API
- **v1.0.0 (planned)**: Full adapter framework (crontab/launchd/systemd/Hermes)

---

## See Also

- [AGENTS.md](../AGENTS.md) – AI agent configuration guide
- [SETUP.md](../SETUP.md) – Manual setup without AI agents
- [README.md](../README.md) – Public documentation
- [SCOPE.md](../SCOPE.md) – Project scope and phases
