# AJD v0.5.0 Release Runbook

> **Purpose**: Single source of truth for kk to manually create the GitHub Release v0.5.0.
> All code-level work is **DONE** (validated 2026-11-08 04:35). This runbook consolidates everything needed for the manual release step.

---

## 📋 Pre-Release Checklist (Already Verified ✅)

| Check | Status | Evidence |
|-------|--------|----------|
| Shell syntax (`bash -n`) | ✅ PASS | `install.sh`, `test_clean_install.sh`, all `setups/*.sh` |
| Python syntax (`py_compile`) | ✅ PASS | `app/app.py`, `app/harvest.py`, `app/test_adapters.py` |
| Adapter tests | ✅ PASS | 4 schedulers + 3 services detected |
| Privacy scan | ✅ PASS | 0 matches for private tokens/paths |
| `/Users/` hardcode scan | ✅ PASS | 0 matches in `app/` |
| Clean install test | ✅ PASS | End-to-end on port 5199 |
| Phase 6 validation | ✅ PASS | All 6 checks green |
| Required files present | ✅ PASS | 6/6 core files exist |
| API endpoints | ✅ PASS | `/api/state`, `/api/heartbeat`, `/api/schedulers`, `/api/services` |
| UI genericity | ✅ PASS | Manifest + index.html + template all AJD-branded |

---

## 🚀 Manual Release Steps (kk executes these)

### 1. Push to GitHub (Web UI — no token scope needed)

```bash
# Local: create clean archive
cd ~/root/ajd
git archive --format=zip --output=/tmp/ajd-v0.5.0.zip HEAD
```

1. Open <https://github.com/hongchikuo-bot/ajd>
2. Click **"Add file" → "Upload files"**
3. Drag `/tmp/ajd-v0.5.0.zip` (or the extracted folder contents)
4. Commit message: `Release v0.5.0 — Engine, adapters, install, docs, whitepaper`
5. Commit directly to **`main` branch**

> This overwrites remote `main` with local clean history (8 commits ahead). Exactly what we want.

### 2. Create GitHub Release

1. Go to <https://github.com/hongchikuo-bot/ajd/releases/new>
2. **Tag version**: `v0.5.0` (create new tag)
3. **Target**: `main`
4. **Release title**: `AJD v0.5.0 — AI agents job dashboard`
5. **Description**: Copy from `RELEASE_NOTES.md` (see below)
6. **Attach assets**:
   - `docs/screenshot-desktop.png`
   - `docs/screenshot-mobile.png`
   - (optional) `ajd-v0.5.0.tar.gz` from repo root
7. Click **"Publish release"**

### 3. Verify Raw Install Works (Critical)

```bash
# In a CLEAN temp directory (not the repo)
cd /tmp && rm -rf ajd-verify && mkdir ajd-verify && cd ajd-verify
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# Wait for service to start, then verify:
curl -s http://localhost:5080/api/state | jq '.registry.projects'
# Expected: ["<YOUR_PROJECT_NAME>"]

curl -s http://localhost:5080/api/schedulers | jq '.[].source'
# Expected: ["crontab","hermes","launchd","systemd"]

curl -s http://localhost:5080/api/services | jq '.[].source'
# Expected: ["docker","http","port"]

curl -s -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"verify","status":"ok"}' | jq '.ok'
# Expected: true
```

**If all 4 checks pass → Release is verified. Done.**

---

## 📄 Release Notes (copy to GitHub Release description)

```markdown
# AJD v0.5.0 — AI agents job dashboard

**General Availability Release** — A universal monitoring dashboard for scheduled jobs and services, built for any agent or no agent at all.

## ✨ What's New

### Core Features
- **General-purpose adapter layer** — Works with any scheduler (crontab, launchd, systemd, Hermes cron) and any service (HTTP health checks, port tests, Docker containers)
- **Cross-platform deployment** — macOS & Linux support via `curl | bash` one-command install
- **Universal heartbeat protocol** — Simple HTTP POST that any language can use to report job status
- **Agent-agnostic setup** — Auto-detects user's agent (Hermes, Claude, Cursor) or provides manual templates

### Security & Privacy
- 🔒 **Zero data upload** — All operations run locally on the user's machine
- 🔒 **No hardcoded secrets** — Empty `projects.json` template provided for users to fill in safely
- 🔒 **Privacy scan included** — Pre-release validation ensures no private data leakage

### Documentation
- 📖 Full English README with usage examples
- 📖 Chinese README (README-zh.md) for 中文使用者
- 📖 SETUP.md — Manual installation guide (no agent required)
- 📖 AGENTS.md — Configuration spec for AI agents to read and complete setup
- 📖 WHITEPAPER.md — Multi-agent system design principles (no personal data)

## 📦 Installation

```bash
# One-command install (macOS/Linux)
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

After install, the dashboard runs at `http://localhost:5080/`.

## 🤖 Agent Configuration

AJD works with **any** AI agent or **none at all**:

| Agent | Setup |
|-------|-------|
| **Hermes** | Add `AJD_URL="http://localhost:5080/"` to profile memories |
| **Claude / Cursor** | Create `~/.claude/settings.json` with `ai-jobs.dashboardUrl` |
| **No agent** | Follow `SETUP.md` — manual edit `projects.json` (~10 min) |

## 💓 Heartbeat Protocol (The Soul of AJD)

Cron saying "I ran" ≠ actually completed. The heartbeat captures the real signal: **"ran but didn't report" = died mid-execution**.

```bash
# Success
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"my-daily-report","status":"ok","note":"3.2MB generated"}'

# Failure
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"my-daily-report","status":"failed","note":"Download failed: 429"}'
```

AJD tracks missed heartbeats to detect silent failures in your jobs.

## 🔗 Links

- **Documentation**: [README.md](https://github.com/hongchikuo-bot/ajd/blob/main/README.md)
- **Chinese Guide**: [README-zh.md](https://github.com/hongchikuo-bot/ajd/blob/main/README-zh.md)
- **Manual Setup**: [SETUP.md](https://github.com/hongchikuo-bot/ajd/blob/main/SETUP.md)
- **Agent Spec**: [AGENTS.md](https://github.com/hongchikuo-bot/ajd/blob/main/AGENTS.md)
- **Whitepaper**: [WHITEPAPER.md](https://github.com/hongchikuo-bot/ajd/blob/main/WHITEPAPER.md)

## 📜 License

MIT — Free to modify, distribute, and use for personal or commercial purposes.
```

---

## 🔍 Post-Release Verification (Optional but Recommended)

After release is live, run the Phase 6 validation against the **GitHub raw** install:

```bash
bash setups/phase6_validation.sh ~/root/ajd
```

Expected output:
```
=== AJD Phase 6 Validation ===
🔍 1. Privacy scan — ✅ No private paths found in app/*.py / adapters
📁 2. Checking for forbidden files — ✅ Archive dir items: 0, Snapshot logs: 0
🧪 3. Testing service endpoints — ✅ Service health check passed (HTTP 200)
💾 4. Verifying screenshot file sizes — ✅ desktop: 17117 bytes (OK), mobile: 14890 bytes (OK)
📋 5. Checking required files — ✅ All 6 required files present
🔌 6. Verifying required API endpoints — ✅ /api/state and /api/heartbeat exist
==========================================
✅ Phase 6 validation PASSED (all checks)
==========================================
```

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| `install.sh` | One-command installer (macOS/Linux) |
| `app/app.py` | Flask dashboard server |
| `app/projects.example.json` | User template (no private data) |
| `app/adapters/schedulers/` | 4 scheduler adapters |
| `app/adapters/services/` | 3 service adapters |
| `README.md` | English docs |
| `README-zh.md` | Chinese docs |
| `SETUP.md` | Manual setup guide |
| `AGENTS.md` | Agent configuration spec |
| `WHITEPAPER.md` | Design principles whitepaper |
| `RELEASE_NOTES.md` | This release's notes |
| `LICENSE` | MIT license |
| `Dockerfile` + `docker-compose.yml` | Container deployment |
| `.github/workflows/ci.yml` | GitHub Actions CI (lint + test) |

---

## ⚠️ Known Limitations (Documented)

- Windows support: planned for v0.6 (PATH handling, PowerShell alternatives)
- Advanced Docker features: reserved for enterprise edition (v1.0+)
- No external API required — all functionality works with local services only

---

## 📞 Support

- Issues: <https://github.com/hongchikuo-bot/ajd/issues>
- Documentation: See links above

---

**Generated**: 2026-11-08 (auto-created by AJD developer agent)
**Status**: Code-complete, awaiting manual GitHub Release by kk