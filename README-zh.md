# AJD - AI Agents Job Dashboard

<div align="center">

**追蹤您的 AI Agent 工作狀態、透過心跳捕捉失效任務、一鍵部署。**

---

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/hongchikuo-bot/ajd)](https://github.com/hongchikuo-bot/ajd/releases)

[🚀 快速開始](#快速開始-9) | [💓 心跳機制為何是靈魂？](#為什麼心跳機制是 AJD 的靈魂) | [🤖 AI Agent 設定指南](./AGENTS.md) | [🔧 手動設定](./SETUP.md) | [📖 英文說明](./README.md)

</div>

---

## 什麼是 AJD？

**AJD (AI Agents Job Dashboard)** 是一個通用的 AI Agent 工作監控框架，讓您可以：

- ✅ **追蹤多個 job 的運行狀態** — 每日報表、股票匯總、系統日誌等
- ✅ **自動收聽 heartbeat 心跳訊號** — 即時發現失敗的 cron job
- ✅ **即時故障警報** — 不依賴檔案時間戳，直接獲取真實執行結果

> 🔒 **安全規則**：AJD **絕對不會上傳任何資料**。所有操作在本機執行，符合使用者自己的 [Agent Safety Policy](#)。

---

## 為什麼心跳機制是 AJD 的靈魂？ 💓

這是本專案的核心價值所在。在現代 AI Agent 工作流中，**「宣告任務完成」不等於「任務真正成功」** —— heartbeat 正是填補這個監控盲點的工具：

### 🎯 您面臨的典型問題

| 現象 | 傳統檔案方式會錯過什麼？ |
|------|--------------------------|
| **cron job 報錯** | 「跑過了」但 API 回應失敗、權限不足 |
| **網路中斷** | 程式未崩潰，但數據沒寫上雲端 |
| **時間延遲** | 從 `/etc/mtab` 看不出真正執行時間 |
| **靜默失效** | 檔案存在，但內容是舊的（過期資料） |

### 🔍 heartbeat 如何解決這些問題？

```bash
# ✅ 正確的做法：明確回報狀態，而非依賴推測
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{
       "job": "我的每日報表",
       "status": "ok",
       "note": "3.2MB, 1,247 rows processed",
       "latency_ms": 124
     }'
```

```json
{
  "heartbeat_received": true,
  "job": "我的每日報表",
  "last_seen": "2026-10-08T14:30:25Z",
  "status": "ok"
}
```

### 📊 心跳機制帶來的優勢

1. **即時故障發現** — 失敗在幾秒內被察覺，而不是等到下一次排程
2. **不依賴檔案系統** — 即使 job 沒寫檔，只要 heartbeat 正常就不會誤報
3. **靈活的監控策略** — 可為每個 job 設定不同的heartbeat interval
4. **整合性高** — 無論使用 crontab、launchd、systemd 還是 Hermes cron，皆能無縫對接

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

### 開啓監控面板

開啟瀏覽器訪問：`http://localhost:5080/`

### 設定 heartbeat 發送器（範例）

#### Python 範例

```python
import requests

def report_job(job_name, status="ok", note="", latency_ms=None):
    payload = {
        "job": job_name,
        "status": status,  # "ok" or "failed"
        "note": note,
        "latency_ms": latency_ms
    }
    try:
        resp = requests.post(
            f"http://localhost:5080/api/heartbeat",
            json=payload,
            timeout=2
        )
        if resp.status_code != 200:
            print(f"❌ {resp.text}")
    except Exception as e:
        print(f"⚠️  heartbeat 發送失敗：{e}")

# 呼叫範例
report_job("每日報表", "ok", "3.2MB, 1247 rows")
```

#### curl shell function（快速測試）

將此加入 `~/.bashrc` 或 `~/.zshrc`：

```bash
ahb() {
    local job=$1; shift
    local status=${1:-ok}
    shift || true
    local note="${@:-}"
    
    payload=$(printf '{\"job\":\"%s\",\"status\":\"%s\",\"note\":\"%s\"}' \
        "$job" "$status" "${note//\"/\\\"}")
    
    curl -sX POST http://localhost:5080/api/heartbeat \
        -H "Content-Type: application/json" \
        -d "$payload" | jq .
}

# 使用範例：ahb "每日報表 ok" "CSV 檔已處理完成"
```

---

## 心跳機制最佳實踐

### 📋 發送 heartbeat 的最佳時機

| 階段 | **✅ 應該發送** | **❌ 不建議发送時** |
|------|-----------------|--------------------|
| **成功完成時**｜`status: "ok"`，包含 `note` 或處理結果 | - |
| **失敗時** | `status: "failed"`，含錯誤訊息以便追蹤 | - |
| **長時間任務中** | 可選：每隔 N 分鐘發送進程heartbeat | - |

### 🛠️ 整合到您的 job 腳本

```bash
#!/bin/bash

# 每日報表範例
REPORT_PATH="/reports/2026-10-08.csv"

if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    LINES=$(wc -l < "$REPORT_PATH")
    
    # ✅ 成功時回報
    curl -sX POST http://localhost:5080/api/heartbeat \
        -H 'Content-Type: application/json' \
        -d "{\"job\":\"每日報表\",\"status\":\"ok\",\"note\":\"${REPORT_PATH}\"}"
else
    # ❌ 失敗時回報
    curl -sX POST http://localhost:5080/api/heartbeat \
        -H 'Content-Type: application/json' \
        -d '{"job":"每日報表","status":"failed","note":"report file not found"}'
fi
exit 0
```

---

## 故障排除

### ✋ heartbeat 發送失敗的處理

如果 `curl` 指令無法執行，確保：

1. **AJD service 正在運行** — `curl http://localhost:5080/api/state` 應該是 `{}` 或成功響應
2. **網路可達性** — `/etc/hosts` 檢查或防火牆是否允許本地host連線
3. **Port 未被佔用** — Port 5080 應只由 AJD service 監聽

### 🔧 手動檢查 heartbeat 接收狀況

```bash
# 查看最近收錄的 heartbeat 事件
curl http://localhost:5080/api/heartbeats | jq '.[]'
```

---

## 展示影片

稍候提供螢幕錄影，包含：

- 🎬 AI Job **總覽與實際 job 狀態** — 視覺化呈現所有 project 的現況
- 💥 **心跳失敗即時警報演示** — 展示 heartbeat 斷線時的快速通知流程
- 🔄 **手動回報 heartbeat** — 模擬 success / failed兩種情況

---

## 文檔

| 文件 | 說明 |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | AI Agent 設定指南（Hermes、Claude、Cursor 等）與 AGENTS.md 配置 |
| [SETUP.md](SETUP.md) | 手動設定說明（不使用 AI Agent） |
| [INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md) | 完整安裝指南（Docker / 非 Docker、平台特定配置） |
| [FAQ.md](docs/FAQ.md) | 常見問題、使用者經驗分享的疑難排解提示 |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 詳細錯誤訊息與常見問題的解決方案 |
| [USAGE.md](docs/USAGE.md) | 快速入門指南：5 分鐘建立您的第一個 job |
| [README.md](./README.md) | 完整英文說明 |

---

## 相關連結

- [GitHub 專案](https://github.com/hongchikuo-bot/ajd)
- [發布註記 (v0.5.0)](https://github.com/hongchikuo-bot/ajd/releases/tag/v0.5.0)
- 📖 [完整英文說明](./README.md)

---

## 授權條款

MIT 授權 — 詳見 [`LICENSE`](./LICENSE)。
