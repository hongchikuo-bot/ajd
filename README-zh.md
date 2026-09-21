# 📊 AJD — AI Agents Job Dashboard

**一個通用的 AI Agent 工作監控面板**，讓你追蹤所有專案、排程與服務的狀態。

## ✨ 核心特色

- **通用設計**：不綁定特定 Agent（Hermes / Claude / Cursor / Windsurf / 任意腳本皆可）
- **一鍵部署**：`curl -fsSL <github-raw>/install.sh | bash` → 裝好即用
- **心跳機制**：讓排程自己回報「我跑完了」，發現「跑了但沒回報」的失敗
- **多來源支援**：crontab、launchd、systemd timers、Hermes cron
- **多服務監控**：port 檢查、HTTP health、Docker 容器
- **本地優先**：零資料上傳，完全在你的機器上運行

## 🚀 快速開始

```bash
# 一鍵安裝（macOS / Linux）
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

安裝完成後：
1. 編輯 `projects.json` 填入你的專案路徑
2. 把 `AGENTS.md` 給你的 AI agent 讀取
3. 你的 agent 會自動配置心跳回報

## 📖 文件

| 文件 | 說明 |
|------|------|
| `README.md` | 英文完整說明 |
| `README-zh.md` | 本文件（中文） |
| `AGENTS.md` | 給 AI agent 的設定任務書 |
| `SETUP.md` | 無 agent 時的手動設定路線 |
| `SCOPE.md` | 設計原則與架構 |
| `LICENSE` | MIT 授權 |

## 🔧 手動設定（無 Agent）

參考 `SETUP.md`，純用 `curl` 回報 heartbeat。

## 🔐 安全承諾

- ✅ **不上傳任何資料**到外部服務
- ✅ **只讀取**本地 `$AJD_HOME/` 內的檔案
- ✅ **不修改**你的任何專案檔案
- ✅ 遵守 `allowLocalOnly=true` 限制

## 💡 為什麼需要心跳？

> cron 說「我跑過了」≠ 真的跑完。  
> **最有價值的訊號是「跑了但沒回報」= 死在半路** —— 檔案時間看不出來。

只要你的排程在結束時打一個 HTTP POST：
```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"我的每日報表","status":"ok","note":"3.2MB"}'
```
AJD 就能即時顯示哪個排程「應該跑但沒回報」。

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

## 🤝 貢獻

歡迎 PR、Issue、討論。專案採用 MIT 授權。

## 📄 授權

MIT License — 見 `LICENSE` 檔案。