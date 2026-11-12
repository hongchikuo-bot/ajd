# AJD v0.5.0 Release Notes

**Release Date**: 2026-10-14  
**Version**: 0.5.0 (stable)

---

## 🎉 What's New

### Core Features
- ✅ Multi-scheduler support: `crontab`, `launchd`, `systemd` adapters
- ✅ Service discovery: port-based + health check endpoints
- ✅ PWA-ready UI with manifest.webmanifest and apple touch icons
- ✅ One-click install via `curl | bash`

### Documentation
- 📖 Complete setup guides (README.md, README-zh.md)
- 🤖 AI agent configuration (`AGENTS.md`)
- 🎨 Screenshot galleries (desktop + mobile)

---

## 📦 Installation

```bash
# macOS / Linux one-click install
curl -L https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/scripts/install.sh | bash

# Then follow AGENTS.md to configure your agents
```

See `SETUP.md` for manual installation or Docker deployment.

---

## 🔧 Configuration

Place your project definitions in `$AJD_HOME/app/projects.json`:

```json
{
  "projects": {
    "my-project": {
      "name": "My Job Pipeline",
      "type": "排程",
      "profile": "default",
      "bot": "@my_bot",
      "entry": {
        "排程腳本": "/path/to/cron.py",
        "產出": "/path/to/output/"
      }
    }
  }
}
```

Use `AGENTS.md` for AI agent setup instructions.

---

## 📚 Documentation

- `README.md` — Full feature list (English)
- `README-zh.md` — 中文說明
- `SETUP.md` — Manual installation guide
- `AGENTS.md` — AI agent configuration
- `docs/screenshot-desktop.png`, `screenshot-mobile.png` — Examples

---

## 🛠️ Technical Stack

### Python Dependencies
```
requests>=2.31
fastapi>=0.109
python-multipart>=0.0.6
uvicorn[standard]>=0.27
jinja2>=3.1.2
websockets>=12.0
aiofiles>=23.2.1
```

### Web Framework
FastAPI + Jinja2 templates (PWA support)

---

## 🔒 Security Considerations

### Private Data Rules

AJD **never uploads** user data. All operations run locally:

1. **No telemetry** — no heartbeat to external servers
2. **Project registration** — purely local file-based (`projects.json`)
3. **AI agent configuration** — respects user's own Agent Safety Policy

### Local-only Guarantee

```bash
# No network calls during normal operation
# All services defined in projects.json are monitored locally
# Heartbeats sent via HTTP POST (any language/script can send)
```

---

## 🐳 Docker Support

For containerized deployments:

```bash
docker-compose up -d --build
```

See `docker-compose.yml` for service definitions.

---

## 📈 Compatibility

- **Python**: 3.9+ (FastAPI, requests)
- **OS**: macOS/Linux only (Windows not yet supported)
- **Browser**: Chrome/Edge/Firefox (PWA support)

---

## 🔍 Changelog (0.4.x → 0.5.0)

### Added
- LaunchD adapter for macOS daemons
- systemd integration for Linux
- Port-based health checks alongside HTTP checks

### Changed
- Cleaner release package (`create_release_package.sh`)
- Improved agent setup flow with AGENTS.md

---

## 📫 Support

- Project URL: https://github.com/hongchikuo-bot/ajd
- Documentation: `README.md` / `README-zh.md`
- Email: hongchikuo@gmail.com (for enterprise inquiries)

---

## 📄 License

MIT License — see LICENSE file.
