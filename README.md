# AJD · AI agents job dashboard

**English** | [繁體中文](README-zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.9%2B-blue.svg)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)](#requirements)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/hongchikuo-bot/ajd/issues)

> **Your agents run on cron. You usually find out they broke when someone asks why the thing didn't happen.**
>
> AJD is a self-hosted, read-only mission control for a fleet of AI agents and scheduled jobs. It finds
> your jobs instead of asking you to declare them, and it catches the failure everyone else misses:
> **the job that ran but never reported back.**

<p align="center">
  <img src="docs/screenshot-desktop.png" alt="AJD dashboard — overview" width="720">
</p>

<p align="center">
  <img src="docs/screenshot-mobile.png" alt="AJD dashboard on a phone" width="260">
</p>

---

## Why another dashboard?

There are great dashboards already. AJD exists because of one design difference: **it derives state
instead of asking you to declare it.**

| | **AJD** | uptime-kuma | homepage / glance |
|---|---|---|---|
| Where state comes from | **derived** from your files, cron, launchd/systemd timers, ports, Docker | you add each monitor by hand | you hand-write YAML per service |
| Catches *"the job ran but never finished"* | ✅ heartbeat + missed-report detection | push monitors only | ✗ |
| Understands agents (profiles, bots, jobs, produced files) | ✅ | ✗ | ✗ |
| Days since last activity / stall detection | ✅ automatic | ✗ | partial, manual thresholds |
| Adds a new project | add one entry (or let it auto-discover) | add monitor + config | write YAML |
| Fails safe | ✅ **read-only** — the dashboard dying affects nothing | ✅ | ✅ |

If you already love your YAML, keep it. AJD is for the case where the answer to *"is my stuff still
running?"* lives in twenty places and nobody wants to maintain a config file about their own machine.

## What it does

- **Auto-discovery adapters** — reads `crontab`, `launchd` plists, `systemd` timers and agent-platform
  cron stores; each source is an isolated module that emits one unified format, so the core never
  learns a new dialect.
- **Heartbeat API** — any script finishes with `POST /api/heartbeat`; AJD shows which scheduled jobs
  **ran but never reported**, the failure mode that file-mtime guessing always misses.
- **Stall & activity tracking** — last activity, files produced per 1/7/30 days, "stalled N days",
  green / yellow / red at a glance.
- **Service monitoring** — port liveness, HTTP health, Docker containers.
- **Daily snapshots & history** — what changed since yesterday, without re-reading the world.
- **Ideas inbox** — capture an idea, attach research, turn it into a one-page brief, mark
  considering / started / parked / dropped (with the reason kept).
- **Mobile-first PWA** — installs to your phone home screen, follows your system dark mode.
- **Read-only by design** — the dashboard never sits in a production path.

## Quick start

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

Then open <http://127.0.0.1:5080/>. The installer prints `✅ AJD 安裝完成！` (AJD installed) when done.

**Let your own AI agent do the wiring:** point it at [`AGENTS.md`](AGENTS.md). It explains how to fill
the project registry from *your* machine and how to call the deployment paths. The install invokes your
agent — that is the point, and it is stated in the file.

**Manual install:** [`SETUP.md`](SETUP.md).

### Requirements

macOS or Linux · Python 3.9+ · nothing else mandatory (Docker optional for the container path).
No account, no cloud, no telemetry.

## How it works

```
        crontab ─┐
         launchd ─┤
         systemd ─┼──▶  adapter layer  ──▶  unified format  ──▶  snapshots  ──▶  Flask + PWA
   agent cron ────┤      (one module            (projects,         (daily          (read-only
   ports / http ──┤       per source)            jobs, hb)          diffs)          view)
        docker ───┘
                                          ▲
                        POST /api/heartbeat ┘   ← your scripts report "I finished"
```

The registry is a single JSON file ([`app/projects.example.json`](app/projects.example.json)); everything
else is discovered or reported. Snapshots are append-only JSON, so history costs no database.

## Configuration

```jsonc
{
  "projects": {
    "daily-briefing": {
      "name": "Daily Briefing Pipeline",
      "type": "Pipeline",
      "profile": "ops",                    // your agent profile / owner team
      "bot": "@ops_bot",                   // the bot that operates it
      "desc": "Collect → render → publish → notify",
      "services": ["api-gateway"],
      "depends_on": [],
      "entry": { "job": "/path/to/job.py", "output": "/path/to/output/" },
      "links": [{ "label": "Output channel", "url": "https://example.com" }]
    }
  }
}
```

## Development

```bash
pip install -r app/requirements.txt
cd app && python3 test_adapters.py        # adapter test suite
python3 app/app.py --port 5080            # run locally
docker compose up -d                      # container happy path
```

CI (syntax checks for `install.sh` and every Python file) lives in
[`ci/github-actions.yml`](ci/github-actions.yml) — copy it to `.github/workflows/ci.yml` to enable it in
your fork.

## Documentation

| File | What's in it |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Wiring AJD to **your** AI agent (Hermes / Claude / Cursor) |
| [`SETUP.md`](SETUP.md) | Manual deployment and troubleshooting |
| [`SCOPE.md`](SCOPE.md) | Scope and roadmap |
| [`QUESTIONS.md`](QUESTIONS.md) | Open design questions |
| [`ci/README.md`](ci/README.md) | Enabling the CI workflow |

## Notes

- The dashboard UI is **bilingual (English / Chinese)**, defaulting to your browser language with a toggle.
- Every path, project name and service in the screenshots is fictional demo data.

## License

MIT — see [LICENSE](LICENSE). © 2026 Kevin ([github.com/hongchikuo-bot](https://github.com/hongchikuo-bot))
