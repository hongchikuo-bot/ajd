# 📝 SETUP.md — AI Agents Job Dashboard (AJD) 手動設定指南

> 這份文件給**沒有 AI agent** 的使用者，用純 `curl` 指令完成設定。

---

## 關於心跳（Heartbeat）回報

AJD 的核心設計：讓你的 cron job 在執行完畢後回傳 heartbeat，以表明「我已經跑過了」。這可幫助你即時發現失敗的排程任務。

**範例**：
```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"job":"my-job","status":"ok","note":"1.2MB"}'
```

---

## 快速開始：無 Agent 手動模式

### 1. 安裝

```bash
# 使用預設安裝目錄
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# 或指定安裝目錄
AJD_HOME="$HOME/my-ajd" curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

安裝完成後，記下 `AJD_HOME` 的路徑（預設 `~/root/ajd`）。

### 2. 設定環境變數

```bash
export AJD_HOME="$HOME/root/ajd"          # 你的安裝目錄
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
| `curl $AJD_URL` 非 200 | 服務未啟動 / port 衝突 | 檢查 `data/app.log`；改 `DASH_PORT` 重裝 |
| `curl $AJD_URL/api/state` 回 401/403 | 私人版有 auth | 通用版無 auth；確認用正確 repo |
| heartbeat 送出但面板未更新 | job name 不匹配 | `projects.json` 的 job name 必須與 heartbeat 的 `job` 一致 |
| job 成功但心跳失敗 | network / firewall | 確認 localhost 連線；檢查防火牆規則 |

---

## 相關文件

- `README.md` / `README-zh.md` — 完整說明
- `AGENTS.md` — AI agent 設定指南
- `SCOPE.md` — AJD 設計原則與架構
- `LICENSE` — MIT 授權