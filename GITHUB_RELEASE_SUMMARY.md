# GitHub Release Summary — v0.5.0

**Release Date**: 2026-10-17  
**Version**: 0.5.0 (General Availability)  
**License**: MIT  

## 🎯 What's New in v0.5.0

### Core Features
✅ **General-purpose adapter layer** — Works with any scheduler (crontab, launchd, systemd, Hermes cron) and any service (http health checks, port tests, Docker containers)  
✅ **Cross-platform deployment** — macOS & Linux support via `curl | bash` one-command install  
✅ **Universal heartbeat protocol** — Simple HTTP POST that any language can use to report job status  
✅ **Agent-agnostic setup** — Auto-detects user's agent (Hermes, Claude, Cursor) or provides manual templates  

### Security & Privacy
🔒 **Zero data upload** — All operations run locally on the user's machine  
🔒 **No hardcoded secrets** — Empty `projects.json` template provided for users to fill in safely  
🔒 **Privacy scan included** — Pre-release validation ensures no private data leakage  

### Documentation
📖 Full English README with usage examples  
📖 Chinese README (README-zh.md) for 中文使用者  
📖 SETUP.md — Manual installation guide (no agent required)  
📖 AGENTS.md — Configuration spec for AI agents to read and complete setup  

---

## 📋 Validation Results

### ✅ Syntax Checks
```bash
✅ install.sh (bash -n → exit 0)
✅ app/app.py (python3 -m py_compile → success)
✅ app/harvest.py (python3 -m py_compile → success)
✅ app/test_adapters.py (python3 -m py_compile → success)
```

### ✅ API Endpoints Verified
| Endpoint | Method | Expected | Actual | Status |
|----------|--------|----------|--------|--------|
| `/` | GET | 200 | 200 | ✅ |
| `/api/state` | GET | 200 JSON | 200 JSON | ✅ |
| `/api/schedulers` | GET | 200 jobs[] | 200 jobs[] | ✅ |
| `/api/services` | POST/GET | 200 | 200 empty list | ✅ |
| `/api/heartbeat` | POST | Accepted | 200 recorded | ✅ |

### ✅ Scheduler Adapters
- crontab ✓
- hermes ✓ (includes `ajd-progress-watch` job)
- launchd ✓
- systemd ✓

### ✅ Service Adapters
- http health checks ✓
- port availability tests ✓
- Docker container status ✓

### ✅ Privacy Verification
```bash
grep -rIl -e macmima1234 -e hckytbot -e kuohome \
     -e news_auto -e stock_auto -e idiom_auto \
     -e ethubs -e zaiditong -e hermesagent \
     -e kuo_bot -e wabi-sabi ~/root/ajd/app/ | grep -v __pycache__
# Result: 0 matches (no private data leakage)
```

### ✅ UI Genericity Checks
- manifest.webmanifest: title = "AJD · AI agents job dashboard" ✓
- index.html: No KK personal name residues ✓
- projects.example.json: Version template schema (with `<YOUR_PROJECT_NAME>`) ✓

---

## 📦 Installation Instructions

### One-command install (macOS/Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

This will:
1. Create `~/root/ajd/` directory
2. Copy clean engine files from source
3. Set up service configuration
4. Start the dashboard server
5. Generate `AGENTS.md` in your installation directory
6. Print setup instructions for your agent (if detected)

### Manual Validation After Install

```bash
cd ~/root/ajd
./scripts/check_release_ready.sh
# Expected output: ALL TESTS PASSED
```

---

## 🤖 Agent Configuration Examples

### For Hermes users

Add to `~/.hermes/profiles/default/memories/config`:

```bash
AJD_URL="http://localhost:5080/"
```

Your agent will automatically find and configure AJD. No token, bot name, or personal data needed — just fill in `projects.json` with your own projects.

### For Claude/Cursor users

Create `$HOME/.claude/settings.json` (or equivalent):

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$AJD_HOME/projects.json",
    "respectAGENTSmd": true
  }
}
```

---

## 📡 Heartbeat Protocol (Why it matters)

Cron schedules saying "I ran" ≠ actually completed. The heartbeat protocol captures the real signal: **"ran but didn't report"** = died mid-execution. This is the soul of this project.

Example heartbeat call (works from any language):

```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"myscheduler","status":"ok","note":"3.2MB"}'
```

Or for failures:

```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"myscheduler","status":"failed" "note":"Download failed: 429 Too Many Requests"}'
```

AJD tracks missed heartbeats to detect silent failures in your jobs.

---

## 📊 What's Covered

### Projects
- **Status page** — Track multiple job statuses (daily reports, stock summaries, system logs)
- **Heartbeat monitoring** — Detect failed cron jobs instantly via HTTP heartbeat tracking
- **General scheduling support** — Works with any scheduler, not just Hermes cron

### Services
- **Port-based health checks** — Simple TCP port probe for local services
- **HTTP health endpoints** — Validate API/service availability via status codes
- **Docker container visibility** — Monitor containers without agent overhead

---

## 🔗 Related Documentation

- [README.md](README.md) — Full English feature documentation  
- [README-zh.md](README-zh.md) — Chinese usage guide  
- [SETUP.md](SETUP.md) — Manual setup (no AI agent required)  
- [AGENTS.md](AGENTS.md) — Configuration spec for AI agents  
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — Common issues and fixes  

---

## 🐛 Known Limitations & Future Work

- Windows support planned for v0.6 (cross-platform PATH handling, PowerShell alternatives)
- Advanced Docker features reserved for enterprise edition (v1.0+)
- No external API required — all functionality works with local services only

---

## 🔒 Security Notes

- AJD does **NOT** upload any data to external servers
- All operations execute locally on the user's machine
- The `projects.json` file is **never committed** to GitHub raw content
- Fill in your own projects from the provided template (`app/projects.example.json`)

---

## 🙏 Acknowledgments

Built with ❤️ for open-source monitoring.  
Forked from kk's private "Dashboard Monitoring" into a clean, reusable open-source project.  

License: MIT — Free to modify, distribute, and use for personal or commercial purposes.
