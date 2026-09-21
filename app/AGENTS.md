# 🤖 AGENTS.md — AI Agents Setup Task Document for AJD

> **通用設定指南**：這份文件給任何 AI agent（Hermes、Claude、Cursor 等），說明如何讀取並配置 AJD 監控台。

---

## What should your agent do?

1. **Read** these files (all in $AJD_HOME, no path spaces):
   - `projects.json` — job registry（由 install.sh 自動複製自 projects_example.json）
   - `data/snapshots/` — 歷史報表、縮圖

2. **Do NOT modify** any files outside `$AJD_HOME`
   - Respect the local-only constraint set above

---

## Settings (schema from $AJD_HOME/app/projects_example.json)

| JSON Key | Value | Example |
|---|---|---|
| `dashboardUrl` | `http://localhost:5080/` | 本機服務地址（或遠端 IP） |
| `registryPath` | `$HOME/.hermes/projects.json` | arbitrary path you choose |
| `allowLocalOnly` | `true` | Force local operation |

---

## Validation

```bash
curl http://localhost:5080/api/state
```

Return JSON → service is ready.

---

## Configuration Examples

### Hermes (local or remote)

In `~/root/dashboard/.hermes/profiles/default/memories/config`:

```bash
AJD_URL="http://localhost:5080/"
HERMES_AJD_REGISTRY="$HOME/.hermes/projects.json"
HERMES_AJD_ALLOW_LOCAL_ONLY=true
```

### Claude / Cursor / Windsurf

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$HOME/.hermes/projects.json",
    "allowLocalOnly": true,
    "respectAGENTSmd": true
  }
}
```

---

## Related Docs

- `SETUP.md` — Manual setup (no AI agent)
- `README.md` — Full description (English, TBD)

> **Version:** 0.3.0 (install.sh fixed: valid endpoints only + service start | AGENTS.md fixed: no fake fields)
