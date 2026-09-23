# AJD - AI Agents Job Dashboard

<div align="center">

**追蹤您的 AI Agent 工作狀態、透過心跳捕捉失敗任務、一鍵部署。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/hongchikuo-bot/ajd)](https://github.com/hongchikuo-bot/ajd/releases)

[🚀 快速開始](#快速開始) | 
[💡 什麼是心跳機制？](#為什麼我應該關心心跳) | 
[🤖 AI Agent 設定指南](./AGENTS.md)|
[🔧 手動設定](./SETUP.md) |
[📖 英文說明](./README.md)

</div>

---

## 什麼是 AJD？

**AJD (AI Agents Job Dashboard)** 是一個通用的 AI Agent 工作監控框架，讓您可以：

- ✅ 追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等）
- ✅ 自動收聽 heartbeat 心跳訊號，即時發現失敗的 cron job
- ✅ 將個人化的 dashboard「~/root/dashboard/」拆成可部署的工程

> **安全規則**：AJD **絕對不會上傳任何資料**。所有操作在本機執行，符合使用者自己的 Agent Safety Policy。

---

## 快速開始

### 一鍵部署（macOS / Linux）

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

安裝完成後會看到：

```
✅ AJD installation complete!
   Dashboard: http://127.0.0.1:5080/
   Config: /your/AJD_HOME/projects.json
```

### 開啟監控面板

開啟瀏覽器訪問：`http://localhost:5080/`

---

## 為什麼我應該關心心跳機制？ 🎯

**這是本專案的靈魂。**

您的 cron job 說「跑過了」不等於真的成功：
- 可能在過程中崩潰
- API 超時、網路中斷、權限不足
- 從檔案時間看不出真正狀況

使用 heartbeat 的工作回報：

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"我的每日報表","status":"ok","note":"3.2MB"}'
```

AJD 即時回報成功 / 失敗狀況，不受您用什麼排程工具管理（crontab、launchd、systemd、Hermes cron 皆可）。

---

## 文件與指南

| 文件 | 用途 |
|------|------|
| [AGENTS.md](./AGENTS.md) | AI Agent 設定任務書給 Hermes、Claude、Cursor 等 |
| [SETUP.md](./SETUP.md) | 手動安裝說明（不用 agent） |

---

## 展示影片

稍候提供螢幕錄影，包含：
- 監控面板總覽與實際 job 狀態
- 心跳失敗即時警報演示
- 手動回報 heartbeat

---

## 相關連結

- [GitHub 專案](https://github.com/hongchikuo-bot/ajd)
- [發布註記 (v0.4.0)](https://github.com/hongchikuo-bot/ajd/releases/tag/v0.4.0)

---

## 授權條款

MIT 授權 — 詳見 [`LICENSE`](./LICENSE)。
