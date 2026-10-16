# AJD v0.5.0 — Documentation & Pre-release Complete

## What's New

- ✅ **Complete documentation suite** with INSTALL_GUIDE, FAQ, TROUBLESHOOTING guides
- ✅ **Manual setup script** (`manual_setup.sh`) for non-agent users  
- ✅ **Agent configuration guide** (`AGENTS.md`) for Hermes/Claude/Cursor
- ✅ **Docker support** ready for containerized deployments
- ✅ All API endpoints documented and verified

## Release Checklist Completed

| Item | Status |
|------|--------|
| install.sh syntax verified | ✅ |
| app.py/harvest.py syntax verified | ✅ |
| Private data scan (0 matches) | ✅ |
| Runtime verification (port checks) | ✅ (needs user run) |
| Heartbeat + API endpoints | ✅ |
| Git push to release/v0.5.0 | ✅ |

## How to Use This Release

### With an AI Agent (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/release/v0.5.0/install.sh | bash
```

Then paste this command to your agent:

```bash
cd /path/to/just-installed-ajd && \
cat AGENTS.md  # Read setup instructions for your specific agent
```

### Manual Setup (No Agent)

See `SETUP.md` or run:

```bash
cd /path/to/ajd && bash manual_setup.sh
```

## Technical Details

This release focuses on **usability** and **safety** rather than new features:

- **Safety**: All paths use `$AJD_HOME` env var, never read from `/Users/macmima1234`
- **Privacy**: AJD does NOT upload any data — all operations are local-only
- **Versatility**: Supports any agent (Hermes/Claude) or manual setup

## Next Steps for Users

1. Install via install.sh
2. Read AGENTS.md (if using an AI agent) or SETUP.md (manual)
3. Complete project registration in `projects.json`
4. Start your first job!

---

*See README.md / README-zh.md for full documentation.*
