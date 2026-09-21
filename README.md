# AJD · AI agents job dashboard

通用 AI Agent 工作監控框架，追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等），即時發現失敗的 cron job。

## 📦 快速開始（一鍵部署）

```bash
curl -fsSL https://raw.githubusercontent.com/kkh0518/ajd/main/install.sh | bash
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

`projects.example.json` 的 schema：

| JSON Key | Value | Example |
|---|---|---|
| `dashboardUrl` | http://localhost:5080/ | 本機服務地址（或遠端 IP） |
| `registryPath` | $HOME/.hermes/projects.json | job 註冊表路徑 |
| `allowLocalOnly` | true | 強制本地操作 |

## 🛠️開發

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

## 📖更多文件

- [AGENTS.md](AGENTS.md) — AI agent 配置指南（Hermes/Claude/Cursor）
- [SCOPE.md](SCOPE.md) — 專案範圍與路標
- [SETUP.md](SETUP.md) — 手動部署（不用 AI agent）
- [QUESTIONS.md](QUESTIONS.md) — 需要使用者決定的設計問題

## 📝 License

MIT · [repo](https://github.com/kkh0518/ajd)
