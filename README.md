# AJD · AI agents job dashboard

通用 AI Agent 工作監控框架，追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等），即時發現失敗的 cron job。

## 📦 快速開始（一鍵部署）

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

跑完會出現 `✅ AJD 安裝完成！`，然後開啟瀏覽器：
- http://127.0.0.1:5080/ —— 預設 port

## 🎯 核心功能

- **job registry**：讀取 `projects.json`，支援 crontab / launchd / systemd timers / Hermes cron
- **heartbeat monitoring**：任何腳本打 `HTTP POST /api/heartbeat` 就能讓 AJD 知道它還在跑
- **歷史記錄**：自動保存心跳時間與最後一次 heartbeat，錯過就出現於 `/backlog`
- **通用監控**：port / HTTP health / Docker 偵測

## 📂 資料檔案（不進 Git）

```
projects.json          # job 註冊表
data/snapshots/        # 歷史報表、縮圖
```

## ⚙️ 設定欄位

`projects.example.json` 的 schema（實際專案結構）：

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

## 🛠️ 開發

```bash
# 安裝 Python dep
pip install -r app/requirements.txt

# 跑測試（驗證 adapter layer）
cd app && python3 test_adapters.py

# 起服務
python3 app/app.py --port 5080

# Docker compose
docker-compose up -d

# GitHub Actions CI (.github/workflows/ci.yml)
cd .. && git add . && git commit -m "feat: ..." && git push
```

## 🏗️ 架構概覽

```
┌─────────────────────────────────────────────────────────────┐
│                      AJD Dashboard                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Schedulers  │  │  Services    │  │  Heartbeats  │      │
│  │  (adapters)  │  │  (adapters)  │  │  (POST API)  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                           ▼                                  │
│              ┌────────────────────────┐                     │
│              │   Unified Format       │                     │
│              │  (projects.json +      │                     │
│              │   snapshots + hb)      │                     │
│              └────────────┬───────────┘                     │
│                           ▼                                  │
│              ┌────────────────────────┐                     │
│              │   Flask + PWA UI       │                     │
│              │   (static + templates) │                     │
│              └────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

**Adapter 層**：每個來源（crontab、launchd、systemd、Hermes）都是獨立模組，輸出統一格式 → 核心只認統一格式。

## 📖 更多文件

- [AGENTS.md](AGENTS.md) — AI agent 配置指南（Hermes/Claude/Cursor）
- [SCOPE.md](SCOPE.md) — 專案範圍與路標
- [SETUP.md](SETUP.md) — 手動部署（不用 AI agent）
- [QUESTIONS.md](QUESTIONS.md) — 需要使用者決定的設計問題

## 📝 License

MIT · [repo](https://github.com/hongchikuo-bot/ajd)
