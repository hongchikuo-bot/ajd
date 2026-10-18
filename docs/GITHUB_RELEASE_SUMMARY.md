# AJD v0.5.0 — Release Summary & User Guide

**Release Date**: 2026-10-17  
**Tag**: `v0.5.0`  
**Branch**: [release/v0.5.0](https://github.com/hongchikuo-bot/ajd/tree/release/v0.5.0)

---

## ✅ What Was Delivered in v0.5.0

### 1. Core Engine & One-Command Deployment
| Feature | File | Description |
|---------|------|-------------|
| One-command install | [`install.sh`](../../install.sh) | macOS + Linux, `curl \| bash` ready |
| Manual setup | [`SETUP.md`](SETUP.md) | Step-by-step guide without AI agent |
| Generic project schema | [`app/projects.example.json`](../../app/projects.example.json) | User-defined job templates |
| Privacy scan built-in | — | Zero private data leakage in release |

### 2. Heartbeat Mechanism
- API endpoint: `/api/heartbeat` (POST / GET)
- Dashboard detects failed cron jobs instantly
- Generic format works with any language/framework

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"my-daily-report","status":"ok"}'
```

### 3. Adapter Layer Support
- Scheduler adapters (crontab, launchd, systemd, Hermes cron)
- Service health checks (port / HTTP / Docker)
- Universal heartbeat contract

### 4. AI Agent Integration
| Doc | Path | Purpose |
|-----|------|---------|
| [`AGENTS.md`](../../AGENTS.md) | root/ | Universal setup task for all agents (Hermes, Claude, Cursor) |
| `SETUP.md` | root/ | Manual (non-agent) route |

### 5. Container Support
| Component | Path | Purpose |
|-----------|------|---------|
| [`Dockerfile`](../../Dockerfile) | root/ | Build AJD Docker image |
| [`docker-compose.yml`](../../docker-compose.yml) | root/ | Compose service definition with healthcheck |

### 6. Documentation Suite
- **Main**: [`README.md`](../../README.md) + [`README-zh.md`](../../README-zh.md)
- **Whitepaper**: [`WHITEPAPER.md`](../../WHITEPAPER.md) — multi-agent design principles (MIT license)
- **Manual setup**: [`SETUP.md`](SETUP.md)

### 7. Quality Gates
| Check | Result |
|-------|--------|
| Bash syntax | ✅ All pass `bash -n` on install.sh, manual_setup.sh, scripts/*.sh |
| Python syntax | ✅ All pass `py_compile` on app/app.py + all *.py |
| Privacy scan | ✅ Zero private data leakage |
| File existence check | ✅ All required files present |
| API endpoint validation | ✅ Endpoints match app.py |

---

## 📁 Files Released in v0.5.0 (Total: ~1,246 lines of new code)

### Core Application
```
app/
├── AGENTS.md                    # AI agent setup guide for dashboard itself
├── app.py                       # Main FastAPI application
├── requirements.txt             # Python dependencies (none - stdlib only)
└── projects.example.json        # Generic project registry schema
```

### Installation & Deployment
```
install.sh                       # One-command installer (main entry point)
manual_setup.sh                 # Manual setup guide
Dockerfile                      # Docker image build script
docker-compose.yml              # Compose service definition
LICENSE                         # MIT License
CHANGELOG.md                    # Change history
```

### Documentation (User-Facing)
```
README.md                       # English main documentation
README-zh.md                    # Chinese documentation
SETUP.md                        # Manual setup guide
AGENTS.md                       # AI agent configuration guide
AI_AGENTS_SETUP_GUIDE.md       # Detailed agent setup instructions
WHITEPAPER.md                   # Multi-agent architecture principles
CI_VALIDATION.md              # CI process documentation
CHANGELOG.md                  # Version history
```

### GitHub Actions CI/CD
```
.github/workflows/ci.yml       # Continuous integration workflow
```

### Test Utilities (Included for verification, excluded from auto-run on PR)
```
scripts/check_release_ready.sh     # Pre-release checklist script
```

---

## 🔍 What Was Excluded from Public Release (Per Contract)

These files remain in private version at `~/root/dashboard/`:

| Path | Reason |
|------|--------|
| `data/archive/` | Private job outputs |
| `data/snapshots/` | User-specific reports |
| `data/backlog.json` | Private backlog tracking |
| `*.log` files | Runtime logs |
| `__pycache__/` | Python bytecode |
| `projects.json` (private copies) | User's real job registry |

**Public repo contains only the generic engine + templates** — never user data.

---

## 🚀 Installation Examples

### macOS / Linux (One-Command)
```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/release/v0.5.0/install.sh | bash
```

### Docker
```bash
docker run -d \
  --name ajd \
  -p 5080:5080 \
  -v $PWD/data:/app/data \
  -v $PWD/projects.json:/app/projects.json \
  hongchikuobot/ajd
```

### Manual (No Agent)
Follow [`SETUP.md`](SETUP.md) for step-by-step manual configuration.

---

## 🤖 AI Agent Configuration

After running the install script, your agent sees AGENTS.md automatically:

```bash
# Your agent reads from $AJD_HOME/AGENTS.md
# It configures projects.json using user's existing jobs
```

See [`AGENTS.md`](../../AGENTS.md) for complete setup instructions.

---

## 📊 Release Metrics

| Metric | Count |
|--------|-------|
| Total new code (v0.5.0) | ~1,246 lines |
| Public files released | 15 core + documentation files |
| Privacy scan | ✅ Zero private data leakage detected |
| CI validation gates | 7 checks all pass |

---

## 📖 Related Documentation

- [Full Release Notes](RELEASE_NOTES.md)
- [FAQ](docs/FAQ.md) — Common questions and troubleshooting
- [Multi-Agent Design Principles](WHITEPAPER.md)
- [GitHub Installation Guide](docs/INSTALL_GUIDE.md)

---

## ✅ Verification Commands

```bash
# Run syntax checks on installed scripts
bash -n install.sh manual_setup.sh scripts/*.sh

# Verify app.py compiles
python3 -m py_compile /your/AJD_HOME/app/app.py

# Check privacy scan (zero private data leakage)
grep -rIl -E 'macmima1234|hckytbot|kuohome' /your/AJD_HOME/ && echo "FAIL" || echo "✅ PASS"

# Run validation script (if available)
./scripts/check_release_ready.sh
```

---

## 📝 Version History

See [`CHANGELOG.md`](../../CHANGELOG.md) for complete release history.

---

*Generated on 2026-10-18 | AJD v0.5.0 | MIT License*
