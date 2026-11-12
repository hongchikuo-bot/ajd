# 📝 SETUP.md — AI Agents Job Dashboard (AJD) 手動設定指南

> 這份文件給**沒有 AI agent** 的使用者，用純 `curl` 指令完成設定。

---

## 關於心跳（Heartbeat）回報：專案靈魂

AJD 的**核心設計哲學**：讓您的 cron job 在真正完成後回傳 heartbeat，以證明「我確實跑過且成功」。這填補了傳統監控的最大盲點。

### 💓 為什麼 heartbeat 是「靈魂」？

現代 AI Agent 的工作流程中，**「宣告任務完成」≠ 「任務真的成功」**：
- 您的 job 輸出檔案存在，但可能是在上次失敗後遺留的舊檔
- `&&` 命令鏈看似執行完畢，但實際上可能被防火牆攔截回應、API 內部崩潰而無明確錯誤訊息
- 從系統日誌看出來了，但真正的用戶體驗層面已失效

heartbeat 用**即時狀態回報**取代推測：AJD 會明確告知成功 / 失敗、處理結果大小、延遲等關鍵指標。

### 🔍 您將遭遇的典型症狀（不使用 heartbeat）

| 現象 | 傳統檔案方式會錯過什麼？ |
|------|--------------------------|
```cron job 報錯</code>｜「跑過了但 API 回應失敗、權限不足、數據沒寫上雲端</table>
| 網路中斷 | 程式未崩潰，但用戶端的數據已過時 |
| 時間延遲 | 從 `/etc/mtab` 看不出真正執行時間 |
| 靜默失效 | 檔案存在但內容是舊資料（幾小時前的） |

### ✅ 正確的心跳發送方式

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H 'Content-Type: application/json' \
     -d '{"job":"我的每日報表","status":"ok","note":"3.2MB，1,247 rows processed","latency_ms":124}'
```

回傳確認：
```json
{
  "heartbeat_received": true,
  "last_seen": "2026-10-08T14:30:25Z",
  "job": "我的每日報表",
  "status": "ok"
}
```

### 🔧 整合至排程腳本的範例（確保真正成功才發送）

```bash
#!/bin/bash
REPORT_PATH="/reports/2026-10-08.csv"

if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    # ✅ 檔案存在且有內容 → 回報 ok
    curl -X POST "localhost:5080/api/heartbeat" \
        -H 'Content-Type: application/json' \
        -d "{\"job\":\"每日報表\",\"status\":\"ok\",\"note\":\"${REPORT_PATH}\"}"
else
    # ❌ 檔案不存在或空檔 → 回報 fail
    curl -X POST "localhost:5080/api/heartbeat" \
        -H 'Content-Type: application/json' \
        -d "{\"job\":\"每日報表\",\"status\":\"failed\",\"note\":\"report file not found\"}"
fi
```

> **要點**：只有當 job 確實成功時才發送 `ok`，失敗則發送 `fail`。AJD 會依此狀態觸發警報或進入 retry 機制。

---

## 快速開始：無 Agent 手動模式

### 1. 安裝

```bash
# 使用預設安裝目錄
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# 或指定安裝目錄
AJD_HOME="$HOME/my-ajd" curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

安裝完成後，記下 `AJD_HOME` 的路徑（預設 `$HOME/.ajd`）。

### 2. 設定環境變數

```bash
export AJD_HOME="$HOME/.ajd"          # 你的安裝目錄
export AJD_URL="http://localhost:5080/"   # Dashboard 位址
```

### 3. 編輯 projects.json

```bash
# 複製範例
cp "$AJD_HOME/app/projects.example.json" "$AJD_HOME/projects.json"

# 編輯 projects.json，填入你的專案路徑、排程、服務等
# 參考 projects.example.json 的說明
```

### 4. 在 cron / job 尾端加上 heartbeat

```bash
# 範例：每日 02:00 跑報表，跑完回報 heartbeat
0 2 * * * /path/to/your/daily-report.sh && \
  curl -X POST "$AJD_URL/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"daily-report","status":"ok"}' \
  || echo "heartbeat pending"
```

> **重點**：`&&` 確保腳本成功才回報 ok；失敗時也可回報 `{"status":"fail"}`。

### 5. 驗證

```bash
# 確認 Dashboard 存活（根端點 / 回 200）
curl -s -o /dev/null -w '%{http_code}\n' "$AJD_URL"
# → 200

# 確認 API 狀態端點
curl "$AJD_URL/api/state"
# → 回傳 JSON（含 latest、heartbeats 等）
```

---

## 常見錯誤與解決方案

| 錯誤現象 | 原因 | 解決方案 |
|---|---|---|
| `AJD_HOME: unbound variable` | 沒設定環境變數 | 安裝前 `export AJD_HOME="$HOME/.ajd"` 或用 `AJD_HOME=... bash install.sh` |
| `python3: command not found` / `ModuleNotFoundError` | 缺 Python / 依賴 | `brew install python3` (macOS) 或 `apt install python3-pip` (Linux)，再 `pip3 install -r app/requirements.txt` |
| `Address already in use` | Port 被佔用 | 改 `PORT=5199` 重裝，或 `lsof -i :5080` 找出佔用者 kill 掉 |
| `curl $AJD_URL` 回非 200 | 服務未啟動 / log 有錯 | `tail -f $AJD_HOME/data/logs/server.log` 看錯誤；確認 `AJD_HOME` 指向正確目錄 |
| `projects.json` 找不到 / 格式錯 | 沒從 example 複製 / JSON 破損 | `cp $AJD_HOME/projects.example.json $AJD_HOME/projects.json` 重編輯 |
| heartbeat 送出但面板未更新 | job name 不匹配 | `projects.json` 的專案 key/name 必須與 heartbeat 的 `job` 參數一致 |
| `logs/` 目錄不存在、server.log 寫入失敗 | 安裝腳本未建立 logs 目錄 | `mkdir -p $AJD_HOME/data/logs` |
| `ModuleNotFoundError: No module named 'flask'` | venv 沒啟用 / 依賴未裝 | `pip3 install flask` 或確認用系統 python3 而非 venv 內的 |

---

## 進階設定

### 自訂 heartbeat timeout

在 `projects.json` 的專案設定中加入：

```json
{
  "projects": {
    "my-project": {
      "...": "...",
      "heartbeatTimeoutMinutes": 60
    }
  }
}
```

超過這分鐘數沒收到 heartbeat，面板會標示為「停滯」。

### Docker 環境

```yaml
# docker-compose.yml
services:
  ajd:
    build: .
    ports:
      - "5080:5080"
    volumes:
      - ./data:/app/data
      - ./projects.json:/app/projects.json
    environment:
      - AJD_PORT=5080
```

---

## 故障排查

| 現象 | 可能原因 | 對策 |
|------|----------|------|
|| `curl $AJD_URL` 非 200 | 服務未啟動 / port 衝突 | 檢查 `$AJD_HOME/data/logs/server.log`；改 `PORT=5199` 重裝 |
| `curl $AJD_URL/api/state` 回 401/403 | 私人版有 auth | 通用版無 auth；確認用正確 repo |
| heartbeat 送出但面板未更新 | job name 不匹配 | `projects.json` 的 job name 必須與 heartbeat 的 `job` 一致 |
| job 成功但心跳失敗 | network / firewall | 確認 localhost 連線；檢查防火牆規則 |

---

## 相關文件

- `README.md` / `README-zh.md` — 完整說明
- `AGENTS.md` — AI agent 設定指南
- `SCOPE.md` — AJD 設計原則與架構
- `LICENSE` — MIT 授權