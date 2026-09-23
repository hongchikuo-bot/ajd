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
[🎥 Demo Video]([TODO: link after screenshot])

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

**This is AJD's soul.**

Your cron jobs say "I ran" but that doesn't guarantee success:
- Jobs can crash halfway through
- Network failures, API timeouts, permission issues
- You'll never know without explicit feedback

With heartbeat-enabled jobs:

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"daily-report","status":"ok","note":"3.2MB"}'
# or for failures
-d '{"job":"daily-report","status":"failed","error":"API timeout"}'
```

AJD then alerts you immediately — no matter whether your cron is managed by crontab, launchd, systemd, or Hermes.

---

## Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](./AGENTS.md) | Setup guide for AI agents (Hermes, Claude, Cursor, etc.) |
| [SETUP.md](./SETUP.md) | Manual setup (no AI agent required) |
| [README-zh.md](./README-zh.md) | 中文說明 |

---

## Demo Video

Coming soon! Stay tuned for screen recordings demonstrating:
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
