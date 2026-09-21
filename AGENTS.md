# 🤖 AGENTS.md — AI Agents Setup Task Document for AJD

> **通用設定指南**：這份文件給**任何 AI agent**（Hermes、Claude、Cursor 等），說明如何讀取並配置 AJD 監控台。
> 
> **安全規則**：AJD **絕對不會上傳任何資料**。所有操作在本機執行，符合使用者自己的 Agent Safety Policy。

---

## 📦 What is this?

**AJD (AI Agents Job Dashboard)** 是一個通用的 AI Agent 工作監控框架，讓你可以：
- 追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等）
- 自動收聽 heartbeat 心跳訊號，即時發現失敗的 cron job
- 將個人化的 dashboard（`~/root/dashboard/`）拆成可部署的工程

---

## 📋 What should your agent do?

1. **Read** these files (all in `$AJD_HOME`, no path spaces):
   - `projects.json` — job registry（由 install.sh 自動複製自 projects.example.json）
   - `data/snapshots/` — 歷史報表、縮圖

2. **Do NOT modify** any files outside `$AJD_HOME`
   - Respect the local-only constraint set above

---

## Settings (schema from `$AJD_HOME/app/projects.example.json`)

The actual `projects.json` schema (copied from `projects.example.json` on install):

```json
{
  "projects": {
    "<YOUR_PROJECT_NAME>": {
      "name": "<PROJECT_NAME>",
      "type": "手動 / 排程（使用者自定）",
      "profile": "<YOUR_HERMES_PROFILE>",
      "bot": "@<YOUR_BOT_USERNAME>",
      "desc": "<USER_DESCRIPTION>",
      "services": [],
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

**Key fields:**
| Field | Required | Description |
|---|---|---|
| `name` | Yes | Display name for the project |
| `type` | Yes | e.g., "排程", "手動", "服務" |
| `profile` | No | Hermes profile name if applicable |
| `bot` | No | Bot username (e.g., @mybot) |
| `desc` | No | Project description |
| `services` | No | Array of service keys from registry.services |
| `depends_on` | No | Array of project names this depends on |
| `entry` | No | Object with script paths and output dirs |
| `links` | No | Array of link objects with `name`, `url`, optional `src` for dynamic URLs |

> **Note**: AJD does NOT use `dashboardUrl`, `registryPath`, or `allowLocalOnly` — those were removed in v0.4. The dashboard URL is set via `AJD_URL` env var or defaults to `http://localhost:5080/`.

---

## Validation

```bash
curl http://localhost:5080/api/state
```

Returns JSON → service is ready.

---

## Configuration Examples

### Hermes (local or remote)

Add to `~/.hermes/profiles/default/memories/config`:

```bash
AJD_URL="http://localhost:5080/"
```

That's it — the agent reads `projects.json` from `$AJD_HOME/projects.json` (set by install).

### Claude / Cursor / Windsurf

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$AJD_HOME/projects.json",
    "respectAGENTSmd": true
  }
}
```

> **Important**: Use `$AJD_HOME/projects.json` (or your custom path) for `registryPath`. Do NOT use `$HOME/.hermes/projects.json` unless that's where you put it.

---

## Related Docs

- `SETUP.md` — Manual setup (no AI agent)
- `README.md` — Full description (English)
- `README-zh.md` — 中文說明

> **Version:** 0.4.0 (AGENTS.md schema fixed to match projects.example.json)


---

## 🚫 不要刪除的目錄（公開 repo 契約）

這個 repo 已經公開發布在 https://github.com/hongchikuo-bot/ajd ，以下路徑是**對外內容**，
清理工作（垃圾檔清除）時必須保留：

| 路徑 | 為什麼不能刪 |
|---|---|
| `docs/screenshot-*.png` | 公開 README 的示意圖，刪掉 GitHub 上的圖就會破圖 |
| `ci/github-actions.yml` | CI 設定（因 token 沒有 workflow scope 才放這裡），README 有引用 |
| `README.md` / `README-zh.md` | 對外門面（英文為主、中文並列） |

`PROGRESS.md` 相反：它是內部工作日誌（含使用者私人專案名稱），**只在 .gitignore 裡、不可提交**。
