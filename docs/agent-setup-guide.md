# Agent Setup Guide for AJD

This document explains how to configure an AI agent (Hermes, Claude, Cursor, etc.) to work with the AJD dashboard.

## Prerequisites

1. An AI agent installed on your system
2. A running AJD instance at `http://localhost:5080/` or your custom URL

## Configuration Steps

### Step 1: Set Dashboard Environment Variable

Add to your agent's configuration (e.g., `~/.hermes/profiles/default/memories/config` for Hermes):

```bash
AJD_URL="http://YOUR_DASHBOARD_URL/"
```

For example:
- Local instance: `http://localhost:5080/`
- Remote instance on the same network: `http://192.168.1.100:5080/`
- Remote instance with domain: `https://youdomain.com/ajd/`

### Step 2: Configure Project Registry Path

Set where your agent should read project definitions from:

```bash
AI_JOBS_REGISTRY_PATH="$AJD_HOME/projects.json"
```

Or use the environment variable directly. This path will typically be:
- `$HOME/root/ajd/projects.json` (local install)
- Or wherever `install.sh` placed your `projects.json` file

### Step 3: Enable AGENTS.md Respect (Optional but Recommended)

If you want your agent to automatically respect the AGENTS.md instructions:

```bash
AI_JOBS_RESPECT_AGENTS_MD=true
```

## Agent-Specific Setup Examples

### Hermes Agent

Add to `~/.hermes/profiles/default/memories/config`:

```bash
AJD_URL="http://localhost:5080/"
AI_JOBS_REGISTRY_PATH="$HOME/root/ajd/projects.json"
AI_JOBS_RESPECT_AGENTS_MD=true
```

### Claude / Cursor / Windsurf (JSON-based)

Add to your `.claude.json` or similar config file:

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$AI_JOBS_REGISTRY_PATH",
    "respectAGENTSmd": true
  }
}
```

### Other Agents (General Pattern)

Most agents follow this JSON schema in their config:

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://dashboard-url/",
    "registryPath": "/path/to/projects.json",
    "respectAGENTSmd": true
  }
}
```

## Safety Rules (MUST FOLLOW)

1. **Read-only Operations**: Your agent should ONLY READ from `$AJD_HOME`. Do NOT modify user project files.

2. **Local Execution Only**: All AJD operations run locally. AJD does NOT upload any data to external servers.

3. **Respect AGENTS.md**: If `respectAGENTSmd=true`, your agent must follow the instructions in `$AJD_HOME/AGENTS.md` before making any configuration changes.

## Agent Detection and Instructions

When you run `install.sh`, it will:

1. Check if you have an AI agent (`~/.hermes/`, `.claude.json`, `.cursorrules`, etc.)
2. If detected, automatically generate the appropriate setup instructions
3. Print ready-to-use commands that call your local agent (AJD does NOT upload anything)
4. If no agent is detected, provide manual setup instructions in `SETUP.md`

## Verification

After configuration, run:

```bash
curl http://localhost:5080/api/state
```

Expected JSON response:

```json
{
  "projects": {
    "<PROJECT_NAME>": {
      "name": "...",
      "type": "...",
      ...
    }
  },
  "services": [...],
  "schedulers": [...]
}
```

## Available Dashboard Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/state` | GET | Get all dashboard state (projects, services, schedulers) |
| `/api/heartbeat` | POST | Submit job heartbeat status |
| `/api/schedulers` | GET | List registered scheduler backends |
| `/api/services` | GET | List registered service checkers |

## Example: Heartbeat Submission

```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{
    "project": "my_daily_report",
    "scheduler": "crontab@daily",
    "status": "ok",
    "note": "Report generated: 3.2MB"
  }'
```

## Debugging

If your agent doesn't see updates after configuration:

1. Verify the registry path is correct: `cat $AI_JOBS_REGISTRY_PATH | grep -c projects` should return a number
2. Check AJD is running: `curl http://localhost:5080/api/state` should return JSON
3. Clear agent cache if applicable (e.g., Hermes needs restart after config changes)

## Getting Help

- See `SETUP.md` for manual configuration (no AI agent required)
- Read `$AJD_HOME/README.md` for full documentation
- Check `.gitignore` in the AJD repository to understand what gets packaged

---

**Note**: This document is part of Phase 4 - Packaging & Release preparation. AJD v0.5.0 will include this auto-generated setup guide in the install output.
