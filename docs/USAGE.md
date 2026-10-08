# Quick Start: Your First AJD Job in 5 Minutes

This guide walks you through deploying a job with the AI Agents Job Dashboard (AJD).

## Prerequisites

- macOS or Linux
- Python 3.8+ and `curl` available
- **Optional**: An AI agent (Hermes, Claude, Cursor) for automated setup  
  If no agent is detected/setup, use the [SETUP.md](./SETUP.md) manual guide.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

After installation:

- Your dashboard will be available at `http://localhost:5080/` (or as specified by install)
- A config file `projects.json` will be created in your AJD directory.

## Understanding `projects.json`

The registry of jobs lives here. Use `$AJD_HOME/projects.example.json` or `$AJD_HOME/app/projects.demo.json` as a template.

### Minimal Example (Manual Job)

Add this to your `projects.json`:

```json
{
  "projects": {
    "my-logs-collector": {
      "name": "My System Logs",
      "type": "手動",       // Or: "排程" for cron, "服務" for monitoring a service
      "desc": "Collects logs from /var/log/myapp every day.",
      "bot": "@my_agent_user",  // Your Telegram bot or agent alias (optional)
      "profile": "logs-collector",  // Your Hermes profile or script group
      "entry": {
        "排程腳本": "/scripts/collect_logs.sh",
        "產出": "/tmp/logs"
      }
    }
  }
}
```

### Understanding Fields

| Field | Required? | Example Values |
|-------|-----------|----------------|
| `name` | ✅ Yes | `"Daily Sales Report"` |
| `type` | ✅ Yes | `"手動"`, `"排程"`, `"服務"` |
| `desc` | No | `"Generates weekly PDF report on Fridays"` |
| `profile` | No | Your Hermes profile name or group name |
| `bot` | No | `@telegram_bot_user` or agent alias |
| `depends_on` | No | `["dependency-job-a"]` or `[]` |
| `entry` | ✅ Yes (for manual) | `{ "排程腳本": "...", "產出": "..." }` |
| `services` | No | Array of keys from AJD service registry |
| `links` | No | Custom link objects with `name`, `url` |

## Common Workflows

### 1. Manual Job (Run Whenever You Want)

- Set `"type": "手動"`
- `entry["排程腳本"]`: Run command or script path (can be a shell command, Python, etc.)
- AJD doesn't auto-run; you trigger it manually via dashboard or cron.

### 2. Scheduled Job (Cron / Heremes)

A scheduled job example with Hermes cron integration:

```jsonc
{
  "my-daily-report": {
    "name": "Daily Report Generator",
    "type": "排程",
    "profile": "daily_ops",
    "bot": "@ops_bot",
    "desc": "Generates a daily report at 23:00 every day.",
    "entry": {
      "排程腳本": "/root/agent/scripts/generate_daily_report.py",
      "產出": "/tmp/reports"
    }
  }
}
```

- Use `"type": "排程"` for cron-based jobs.
- For Hermes, also add `crontab` or a job ID to the project entry if you want heartbeat integration.

### 3. Service Monitoring (Port / HTTP Health)

Monitor a service that listens on port 8081:

```jsonc
{
  "my-api": {
    "name": "API Health Monitor",
    "type": "服務",
    "desc": "Monitors the health of our main API.",
    "services": ["web-api"],  // Must be registered in $AJD_HOME/app/services.json or config
    "entry": {
      "port": 8081,
      "path": "/health"       // Optional HTTP health endpoint path
    }
  }
}
```

AJD will periodically check that port and alert if unreachable.

## Adding Heartbeat Support (Recommended)

Heartbeats let you detect failures that exit with code 0 but silently fail internally.

### Example: Python Script with Heartbeat

Add this to your job's script entry-point:

```python
#!/usr/bin/env python3
"""Daily report job with heartbeat."""
import requests
from datetime import datetime

def main():
    print("Running daily report...")
    # ... do your work ...
    
    if True:  # Success
        try:
            requests.post(
                "http://localhost:5080/api/heartbeat",
                json={"job": "daily-report", "status": "ok", "note": "Generated"}
            )
        except Exception:
            pass

if __name__ == "__main__":
    main()
```

AJD will automatically record each successful heartbeat and track the last run time.

## Dashboard Endpoints

After starting (`app/app.py`), use these endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Open dashboard in browser |
| `/api/state` | GET | JSON state with job list, heartbeats, status |
| `/api/heartbeat` | POST | Send a heartbeat from a cron script |

Example:

```bash
curl http://localhost:5080/api/state -s | jq '.'
```

## Validation Check

Before deployment, run:

```bash
cd $AJD_HOME
python3 app/app.py --port 5199 &   # or whatever port config uses
sleep 2
curl -s http://localhost:5199/api/state
# Should return JSON with job list
kill %1
```

If you see `{"jobs": [], "status": "ready", ...}`, your configuration is valid.

## Next Steps

- Read [AGENTS.md](./AGENTS.md) to integrate with AI agents (Hermes, Claude, Cursor).
- Check [SETUP.md](./SETUP.md) for manual setup without an agent.
- Explore [README.md](./README.md) for architecture and heartbeat philosophy.
- For advanced users: customize [app/app.py](../app/app.py) logic or add new adapters in `app/adapters/`.

---

## FAQ

**Q: Can I monitor Linux systemd services?**  
A: Yes. Use `"type": "服務"` with the service key registered as part of your configuration, and AJD's systemd adapter handles it.

**Q: How do I know when a job fails?**  
A: Heartbeat alerts immediately flag a failure. If you miss heartbeats (or a heartbeat reports error status), the dashboard shows a red alert.

**Q: Can I run jobs without an AI agent?**  
A: Absolutely! Use manual mode (`"type": "手動"`) or cron + heartbeat from any language/script.

**Q: Where is my `projects.json` saved after install?**  
A: It's in `$AJD_HOME/projects.json` (e.g., `/your/AJD_HOME/projects.json`). Customize by editing this file as needed.

---

*Version: 0.4.x – AJD User Usage Guide*