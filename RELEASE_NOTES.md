# GitHub Release Notes - AJD v0.4.0

## What's New in 0.4.0

### 🎉 一鍵部署正式完成
- ✅ Phase 1: 抽引擎 — 完成
- ✅ Phase 2: Adapter 層 — 完成 (crontab/launchd/systemd/hermes → 統一心跳)
- ✅ Phase 3: 文件 — 完成 (README.md, README-zh.md, SETUP.md, AGENTS.md)
- 📦 Phase 4: Release — 本版本可正式发布

### 🔑 心跳機制 (Heartbeat)
AJD 的核心靈魂：cron job 真的跑完不等於系統知道，**死在半路看不到**。任何語言、框架都能用固定格式回報：

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"每日報表","status":"ok","note":"3.2MB","output":"/var/log/daily_2026-09-23.log"}'
```

### 🔄 通用 adapter 支援
- **排程來源**: crontab (Linux/ macOS), launchd(macOS), systemd(Linux), Hermes cron
- **服務監控**: port 檢查 / HTTP health check(Docker), HTTP 端點
- **心跳回報**: 純 HTTP POST，任何語言都能打

### 🧹 無 Agent 也能用
若使用者沒有 AI agent，可提供手動範本：`SETUP.md`

### 🚫 安全規則
- AI agent **只能讀取** `$AJD_HOME/projects.json`
- **絕對不上傳資料**,全部在本機執行
- agents 會被明確告知會呼叫使用者自己的 agent（借他的 agent）

---

## Installation (One-command)

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

後端會：
1. 下載 AJD engine 檔案 from GitHub raw
2. 安裝 requirements.txt
3. 自動啟動 service (預設 port 5080)
4. 印出 agent config 指令給使用者複製

### 驗證
```bash
curl http://localhost:5080/api/state
# → {"ready":true,"heartbeat":"/api/heartbeat","projects_file":"projects.json"}
```

---

## Agent Configuration

AI Agents (Hermes, Claude, Cursor, etc.) 自動偵測配置方式：

### Hermes
Add to `~/.hermes/profiles/default/memories/config`:
```bash
AJD_URL="http://localhost:5080/"
```

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

See `AGENTS.md` in `$AJD_HOME` for more examples.

---

## Heartbeat Alert (Alert Example)

當 heartbeat timeout，AI agent 可在 Telegram/X/其他平台通知：

### Project entry
```json
{
  "name": "每日報表",
  "type": "排程",
  "entry": {
    "排程腳本": "/path/to/cron.py",
    "產出": "/var/log/daily/"
  }
}
```

### Heartbeat payload example
```json
{
  "job": "每日報表",
  "status": "ok",
  "note": "3.2MB",
  "output": "/var/log/daily_2026-09-23.log",
  "duration": 45.2
}
```

---

## Project Entry Example

Fill `projects.json` with your projects:

```bash
cp $AJD_HOME/projects.example.json $AJD_HOME/projects.json
```

Then edit `$AJD_HOME/projects.json`:

```json
{
  "projects": {
    "每日報表": {
      "name": "每日新聞匯總",
      "type": "排程",
      "profile": "default",
      "bot": "@news_daily_bot",
      "desc": "YouTube 每日新聞報表",
      "entry": {
        "排程腳本": "/Users/macmima1234/.hermes/cron/news/",
        "產出": "/Users/macmima1234/.hermes/profiles/default/snapshots/"
      },
      "links": [
        {
          "name": "YouTube",
          "url": "https://youtube.com/@newsdailybriefing"
        }
      ]
    },
    "美股匯總": {
      "name": "美股每日分析",
      "type": "排程",
      "profile": "default",
      "bot": "@stock_daily_bot",
      "desc": "YouTube 美股報表",
      "entry": {
        "排程腳本": "/Users/macmima1234/.hermes/cron/stock/",
        "產出": "/Users/macmima1234/.hermes/profiles/default/snapshots/"
      },
      "links": [
        {
          "name": "YouTube",
          "url": "https://youtube.com/@stockdailybriefing"
        }
      ]
    }
  }
}
```

---

## API Endpoints

- `GET /` — Dashboard UI (PWA)
- `GET /api/state` — Health check
- `GET /api/project/<name>` — Project details
- `POST /api/heartbeat` — Heartbeat report
- `POST /api/project/<pid>/backlog/add` — Add to failed jobs
- `POST /api/project/<pid>/backlog/toggle` — Toggle status
- `POST /api/project/<pid>/backlog/remove` — Remove from backlog

See API docs in `/app/README.md`.

---

## Screenshots

|  | Desktop | Mobile |
|--| --- | --- |
| Screenshot | ![Desktop](docs/screenshot-desktop.png) | ![Mobile](docs/screenshot-mobile.png) |


**Version**: 0.4.0  
**Date**: 2026-09-23  
**Repo**: https://github.com/hongchikuo-bot/ajd
