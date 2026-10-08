# AJD - AI Agents Job Dashboard

<div align="center">

**Track your AI agent jobs, catch failures via heartbeat, deploy in one command.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/hongchikuo-bot/ajd)](https://github.com/hongchikuo-bot/ajd/releases)
[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://hub.docker.com/r/hongchikuobot/ajd)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)

[📖 Documentation](#documentation) | 
[🚀 Quick Start](#quick-start) | 
[💡 What is Heartbeat?](#why-do-i-care-about-heartbeats) | 
[🤖 AI Agents Setup](./AGENTS.md)|
[🔧 Manual Setup](./SETUP.md) |
[🎥 Demo Video](#demo-video)

</div>

---

## What is AJD?

**AJD (AI Agents Job Dashboard)** is a universal job monitoring framework for AI agents. It lets you:

- ✅ Track multiple jobs' status (daily reports, stock summaries, system logs, etc.)
- ✅ Automatically listen to heartbeat signals, instantly discover failed cron jobs
- ✅ Deploy in one command via `curl | bash`

> **Security Notice**: AJD **never uploads any data**. All operations run locally on your machine. This complies with your Agent Safety Policy.

---

## Quick Start

### One-Command Deployment (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

After installation, you'll see:

```
✅ AJD installation complete!
   Dashboard: http://127.0.0.1:5080/
   Config: /your/AJD_HOME/projects.json
```

### Access the Dashboard

Open your browser and visit: `http://localhost:5080/`

---

## Why Do I Care About Heartbeats? 🎯

**This is AJD's soul.** Run `phase6_test.sh` to simulate failures and see the alerts in action.

### The Problem: Cron Lies by Omission

```bash
# A job runs at 00:02, finishes with errors but exits code=0
crontab -l | grep ... && "Job scheduled ✅"
```

Without heartbeats, you only see the silence after failure. You won't notice a broken report for days.

### The Solution: Heartbeat API

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"daily-report","status":"ok","note":"3.2MB"}'
```

### What You Get

| Condition | Without Heartbeats | With Heartbeats |
|-----------|-------------------|------------------|
| Job succeeds | ✓ Visible in dashboard | ✓ + stored result |
| Crashes with error code 0 | ❌ Silent failure until manual check | ⚠️ Immediately flagged |
| Hangs / dies partway | ❌ Never detected | ⚠️ Dead silent = anomaly |

### The Key Insight

> **"Ran but no heartbeat" is the most valuable alert.**
> 
---

## Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](./AGENTS.md) | Setup guide for AI agents (Hermes, Claude, Cursor, etc.) |
| [SETUP.md](./SETUP.md) | Manual setup (no AI agent required) |
| [USAGE.md](./docs/USAGE.md) | Quick start: your first job in 5 minutes |
| [README-zh.md](./README-zh.md) | 中文說明 |

## Quick Reference

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

**Your jobs go in your registry. Start with a small example:**
```jsonc
// $AJD_HOME/projects.json
{
  "projects": {
    "my-daily-report": {
      "name": "Daily Report",
      "type": "排程",
      "profile": "daily_ops",
      "desc": "Generates daily report at 23:00",
      "entry": {
        "排程腳本": "/root/agent/scripts/generate_report.py",
        "產出": "/tmp/reports"
      }
    }
  }
}
```

For more details, see [USAGE.md](./docs/USAGE.md).

---

## Demo Video

The dashboard is ready with screenshots in `docs/`:
- `docs/screenshot-desktop.png` — Desktop view
- `docs/screenshot-mobile.png` — Mobile view

Screenshots demonstrate:
- Dashboard overview with real job status
- Heartbeat failure alerts in action
- Manual heartbeat submission

---

## Related Links

- [GitHub Repository](https://github.com/hongchikuo-bot/ajd)
- [Release Notes (v0.4.0)](https://github.com/hongchikuo-bot/ajd/releases/tag/v0.4.0)

---

## License

MIT License — See [`LICENSE`](./LICENSE) for details.
