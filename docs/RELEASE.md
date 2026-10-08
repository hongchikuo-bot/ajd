# AJD Release Notes

## Version 0.5.0 — Final Stable Release

**Release date:** October 2026  
**License:** MIT

---

## 🎯 What is AJD?

**AJD (AI Agents Job Dashboard)** 是一個通用的 AI Agent 工作監控框架，讓你可以：
- 追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等）
- 自動收聽 heartbeat 心跳訊號，即時發現失敗的 cron job
- 將個人化的 dashboard（`your_dashboard/`）拆成可部署的工程

**核心設計原則：**
- ✅ **不做外掛 API** — 借使用者自己的 agent（Hermes / Claude / Cursor 等）來設定
- ✅ **通用 adapter 層** — 支援任何排程來源（crontab、launchd、systemd、Hermes cron）
- ✅ **純 HTTP POST 心跳** — 任何語言、任何框架都能回報狀態
- ✅ **零外掛** — 完全在本機執行，不上傳任何資料

---

## 📦 Installation (One-liner)

### Prerequisites

- macOS or Linux
- Bash 4.3+
- Python 3.9+
- curl, jq

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

The installer will:
1. Create the AJD service directory at `$HOME/.ajd/` 
2. Download all engine files from GitHub raw
3. Generate `projects.json` from template (edit with your projects)
4. Start the AJD HTTP service on port 5080
5. Detect your local agent and output configuration commands

### Verify Installation

```bash
curl -s http://localhost:5080/api/state | jq '.registry.projects | keys'
# Should show ["<YOUR_PROJECT_NAME>"] or [] if using manual setup
```

---

## 🔧 Configuration

The installer will detect your agent and output configuration commands. For example, for Hermes:

```bash
# Add to ~/.hermes/profiles/default/memories/config
AJD_URL="http://localhost:5080/"
```

For other agents (Claude / Cursor / Windsurf), see the `AGENTS.md` file in your AJD directory.

### Manual Setup (No Agent)

If you don't have an AI agent, use the manual setup described in `SETUP.md`.

---

## 📊 Using AJD with Your Projects

Edit `$AJD_HOME/projects.json`:

```json
{
  "projects": {
    "<YOUR_PROJECT_NAME>": {
      "name": "Daily Reports",
      "type": "排程",
      "profile": "<YOUR_HERMES_PROFILE>",
      "bot": "@<YOUR_BOT_USERNAME>",
      "desc": "自動生成每日報表",
      "services": ["port:8000"],
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

Each project entry:
- `name`: Display name for the project
- `type`: e.g., "排程", "手動", "服務"
- `profile`: Hermes profile name if applicable
- `bot`: Bot username (e.g., @mybot)
- `desc`: Project description
- `services`: Array of service keys from registry.services
- `depends_on`: Array of project names this depends on
- `entry`: Object with script paths and output directories
- `links`: Optional array of link definitions

---

## 🚀 Why Heartbeat Matters

AJD's core value is detecting **silent failures** — jobs that crontab says "I ran" but actually failed halfway.

### How Heartbeat Works

```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"daily-report","status":"ok","note":"3.2MB generated"}'
```

Heartbeat response:
```json
{
  "ok": true,
  "recorded": {
    "duration_s": 0.2,
    "job": "daily-report",
    "note": "3.2MB generated",
    "project": "",
    "status": "ok",
    "ts": "2026-10-08T15:43:01+08:00"
  }
}
```

### Heartbeat Schema

| Field | Required | Description |
|---|---|---|
| `job` | Yes | Job identifier (e.g., "daily-report") |
| `status` | Yes | "ok" or "failed" |
| `note` | No | Optional note (output size, error message) |
| `project` | No | Optional project name |
| `ts` | Auto | Unix timestamp (automatically set by server) |

See `docs/WHITEPAPER.md Appendix A` for the official heartbeat schema.

---

## 🔄 Upgrading

### Automated Upgrade

```bash
# Install AJD to a new location first, then run this:
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh \
  | bash --install-to-existing=$HOME/.ajd
```

Or simply re-run the installer (it will overwrite engine files but preserve your `projects.json`).

### Manual Upgrade

1. Clone/fetch latest updates:
   ```bash
   git pull origin main
   ```
2. Restart the AJD service:
   ```bash
   pkill -f "app.py"  # Stops existing service
   cd $HOME/.ajd/app && PORT=5080 python3 app.py &
   ```

---

## 🛠️ Project Types Reference

See `SETUP.md` for project type definitions:

| Type | Description | Example |
|---|---|---|
| 排程 | Scheduled job (cron/launchd/systemd) | Daily reports |
| 手動 | Manual execution | One-time tasks |
| 服務 | HTTP port listener | Local API server |

---

## 📚 Documentation

- `README.md` — English main documentation with architecture overview
- `README-zh.md` — Chinese version (concurrent)
- `SETUP.md` — Detailed manual setup guide (including for non-agent users)
- `AGENTS.md` — Configuration guide for your agent (Hermes, Claude, Cursor, etc.)
- `docs/USAGE.md` — API reference and usage examples
- `docs/WHITEPAPER.md` — Philosophy and design principles

---

## 🔍 Troubleshooting

### Service won't start

```bash
# Check if port is already in use
lsof -i :5080

# Kill the process using port 5080
kill $(lsof -t -i:5080) || true

# Restart service
pkill -f "app.py" && cd $HOME/.ajd/app && PORT=5080 python3 app.py &
```

### Agent detection failed

If the installer didn't detect your agent, manually add `$AJD_URL` to your agent's configuration:

**Hermes:** Add to `~/.hermes/profiles/default/memories/config`  
**Claude/Cursor/Windsurf:** See `CLAUDE.md` / `.cursorrules` in your config directories

---

## 🏗️ Architecture Overview

```
├── $HOME/.ajd/
│   ├── app/          # AJD engine (FastAPI server)
│   │   ├── static/   # Web UI assets
│   │   └── templates/ # HTML templates
│   ├── data/         # Heartbeat logs, heartbeats.jsonl
│   └── projects.json # Your project registry (EDIT THIS!)
├── AGENTS.md         # Agent configuration guide
└── SETUP.md          # Manual setup instructions
```

AJD is **read-only** for user projects — it never modifies or uploads your data.

---

## 📣 Contributing

This is an open-source project at https://github.com/hongchikuo-bot/ajd

- Report issues via GitHub Issues
- Pull requests welcome (ensure no private data in commits)
- Documentation improvements always appreciated

See `LICENSE` for contribution guidelines.

---

## 📋 Changelog

### v0.5.0 (2026-10-10) — Final Release
- Generic adapter layer with multiple scheduler sources (crontab, launchd, systemd, Hermes cron)
- Multiple service detection methods (port check, HTTP health, Docker)
- Universal heartbeat endpoint for any programming language
- Clean install script that works from GitHub raw
- Agent configuration detection and output

### v0.4.0
- Adapter layer for scheduler/service adapters
- Heartbeat API endpoints (/api/schedulers, /api/services)
- AGENTS.md for agent setup guidance

---

## 📞 Support

- Documentation: https://github.com/hongchikuo-bot/ajd/tree/main/docs
- Issues: https://github.com/hongchikuo-bot/ajd/issues
- Chat via Telegram bots (see `SETUP.md`)

---

## ⚠️ Important Disclaimers

1. **AJD never uploads any data** — All operations are local only, compliant with your agent's safety policies.
2. **Read-only access to user projects** — AJD does not modify your project files.
3. **Agent detection is optional** — Manual setup is fully supported for non-agent users.
4. **Heartbeat is the soul of AJD** — Without heartbeats, you only know crontab says "I ran", but not if it actually succeeded.

---

## 🎉 Thank You

Special thanks to kk for pioneering the original dashboard and allowing this open-source evolution.

Built with ❤️ as a MIT-licensed toolkit for any AI agent ecosystem.
