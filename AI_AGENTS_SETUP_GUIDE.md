# AI Agents Setup Task Guide for AJD

> **Target audience**: Any AI agent (Hermes, Claude, Cursor, Windsurf, etc.) helping a user set up AJD on their machine.
>
> **Security**: AJD **never uploads any data**. All operations run locally. This guide complies with your Agent Safety Policy.

---

## 1. What is AJD?

**AJD (AI Agents Job Dashboard)** is a universal job monitoring framework for AI agents. It lets users:

- Track multiple jobs' status (daily reports, stock summaries, system logs, etc.)
- Automatically listen to heartbeat signals, instantly discover failed cron jobs
- Deploy in one command via `curl | bash`

---

## 2. Installation (One Command)

Run this on the user's machine:

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

**What the installer does:**
1. Creates `$HOME/.ajd/` (or custom `AJD_HOME`)
2. Downloads all engine files from GitHub raw
3. Generates `projects.json` from template (`projects.example.json`)
4. Starts the AJD HTTP service on port 5080
5. Detects the user's local AI agent and outputs configuration commands

**Verification after install:**
```bash
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5080/
# → 200

curl http://localhost:5080/api/state
# → JSON with projects, heartbeats, status
```

---

## 3. Core Configuration File: `projects.json`

**Location**: `$AJD_HOME/projects.json` (created by installer from template)

**Schema** (from `projects.example.json`):
```json
{
  "projects": {
    "<YOUR_PROJECT_NAME>": {
      "name": "<DISPLAY_NAME>",
      "type": "手動 / 排程 / 服務",
      "profile": "<HERMES_PROFILE>",
      "bot": "@<BOT_USERNAME>",
      "desc": "<DESCRIPTION>",
      "services": [],
      "depends_on": [],
      "entry": {
        "排程腳本": "/path/to/your/cron.py",
        "產出": "/path/to/output/"
      },
      "links": []
    }
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name for the project |
| `type` | Yes | "手動", "排程", or "服務" |
| `profile` | No | Hermes profile name if applicable |
| `bot` | No | Bot username (e.g., `@mybot`) |
| `desc` | No | Project description |
| `services` | No | Array of service keys from registry |
| `depends_on` | No | Array of project names this depends on |
| `entry` | Yes (for manual) | Object with script paths and output dirs |
| `links` | No | Custom link objects with `name`, `url` |

**Important**: The `job` name in heartbeat POST **must match** the project key in `projects.json` (or the `name` field).

---

## 4. The Heartbeat Mechanism (AJD's Soul)

### Why Heartbeat Matters
> **"Ran but no heartbeat" is the most valuable alert.**

Traditional cron says "I ran" but doesn't prove success. Heartbeat proves the job **actually completed**.

### Heartbeat API
```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"my-job","status":"ok","note":"3.2MB generated"}'
```

**Response:**
```json
{
  "ok": true,
  "recorded": {
    "job": "my-job",
    "status": "ok",
    "note": "3.2MB generated",
    "ts": "2026-10-08T15:43:01+08:00"
  }
}
```

### Schema
| Field | Required | Description |
|-------|----------|-------------|
| `job` | Yes | Job identifier (must match `projects.json` key) |
| `status` | Yes | `"ok"` or `"fail"` |
| `note` | No | Optional note (output size, error message) |
| `project` | No | Optional project name |

### Integration Pattern (Bash)
```bash
#!/bin/bash
REPORT_PATH="/reports/2026-10-08.csv"

if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    # ✅ File exists and has content → report ok
    curl -X POST "http://localhost:5080/api/heartbeat" \
        -H 'Content-Type: application/json' \
        -d "{\"job\":\"daily-report\",\"status\":\"ok\",\"note\":\"${REPORT_PATH}\"}"
else
    # ❌ File missing or empty → report fail
    curl -X POST "http://localhost:5080/api/heartbeat" \
        -H 'Content-Type: application/json' \
        -d "{\"job\":\"daily-report\",\"status\":\"fail\",\"note\":\"report file not found\"}"
fi
```

### Integration Pattern (Python)
```python
import requests

def send_heartbeat(job_name, status, note=""):
    try:
        requests.post(
            "http://localhost:5080/api/heartbeat",
            json={"job": job_name, "status": status, "note": note},
            timeout=3
        )
    except Exception:
        pass  # Never let heartbeat failure break the main job
```

---

## 5. Agent-Specific Configuration

After installation, the installer outputs commands tailored to the detected agent. Have the user run the appropriate command for their agent.

### Hermes
Add to `~/.hermes/profiles/default/memories/config`:
```bash
AJD_URL="http://localhost:5080/"
```

### Claude / Cursor / Windsurf
Add to the agent's config file (`CLAUDE.md`, `.cursorrules`, etc.):
```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$AJD_HOME/projects.json",
    "respectAGENTSmd": true
  }
}
```
> Use `$AJD_HOME/projects.json` for `registryPath`. Do NOT use `$HOME/.hermes/projects.json` unless that's where the user put it.

### Manual Setup (No Agent)
If no agent is detected, the installer prints manual setup instructions. The user follows `SETUP.md`:
1. `export AJD_HOME="$HOME/.ajd"`
2. `cp "$AJD_HOME/app/projects.example.json" "$AJD_HOME/projects.json"`
3. Edit `projects.json` with their paths
4. Add heartbeat curl to their cron/job scripts

---

## 6. API Endpoints (For Agent Use)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Open dashboard in browser |
| `/api/state` | GET | JSON state with projects, heartbeats, status |
| `/api/schedulers` | GET | List schedulers: crontab/hermes/launchd/systemd job counts |
| `/api/services` | GET | List service registry: docker/http/port sources |
| `/api/heartbeat` | POST | Send a heartbeat from any script |

**Validation check** (run after config):
```bash
curl http://localhost:5080/api/state
# Should return JSON with projects list
```

---

## 7. Common Issues & Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `AJD_HOME: unbound variable` | Env var not set | `export AJD_HOME="$HOME/.ajd"` |
| `python3: command not found` | Missing Python | `brew install python3` (macOS) / `apt install python3-pip` (Linux) |
| `Address already in use` | Port 5080 occupied | Use `PORT=5199` or `lsof -i :5080` + kill |
| Heartbeat sent but dashboard not updated | Job name mismatch | Ensure `projects.json` key matches heartbeat `job` |
| `logs/` directory missing | Install didn't create | `mkdir -p $AJD_HOME/data/logs` |
| `ModuleNotFoundError: flask` | Dependencies not installed | `pip3 install -r $AJD_HOME/app/requirements.txt` |

---

## 8. Agent Instructions Summary

When helping a user set up AJD:

1. **Run the installer** (or guide user to run it)
2. **Read the generated `projects.json`** from `$AJD_HOME/projects.json`
3. **Help user edit it** with their actual project paths, cron scripts, and service ports
4. **Add heartbeat calls** to their cron/job scripts (only on success!)
5. **Verify** with `curl http://localhost:5080/api/state`
6. **Configure their agent** with the appropriate config (Section 5)

**Do NOT:**
- Modify any files outside `$AJD_HOME`
- Upload any data (AJD is fully local)
- Invent API endpoints not in Section 6
- Use `projects.example.json` directly — always copy to `projects.json` first

---

## 9. Quick Reference Card

```
Install:     curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
Config:      $AJD_HOME/projects.json
Dashboard:   http://localhost:5080/
Heartbeat:   POST /api/heartbeat  {"job":"name","status":"ok|fail","note":"..."}
State:       GET  /api/state
Schedulers:  GET  /api/schedulers
Services:    GET  /api/services
```

---

## 10. Related Documents

- `README.md` — Full English documentation
- `README-zh.md` — 中文說明
- `SETUP.md` — Manual setup guide (no agent)
- `docs/USAGE.md` — API reference and usage examples
- `docs/WHITEPAPER.md` — Philosophy and design principles
- `SCOPE.md` — Project scope and architecture decisions

---

*Version: 0.5.0 — AJD AI Agents Setup Task Guide*