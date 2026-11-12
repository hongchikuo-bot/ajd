# AJD Installation Guide — 安裝教學

> **通用化 AI Agent 工作監控台**  
> **一鍵安裝**: `curl -L https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/scripts/install.sh | bash`

---

## 📦 What is this?

AJD (**AI Agents Job Dashboard**) 是一個通用的 AI Agent 工作監控框架，讓你可以：
- 追蹤多個 job 的運行情況（每日報表、股票匯總、系統日誌等）
- 自動收聽 heartbeat 心跳訊號，即時發現失敗的 cron job
- 將個人化的 dashboard 拆成可部署的工程

**特色**:
- ⚡️ 一鍵安裝 (單一 `curl | bash`)
- 🔄 通用 adapter layer — 支援 Hermes、Claude、Cursor 等多種 agent
- 🔔 Heartbeat-over-HTTP — 任何語言都能回報心跳
- 📁 無私人資料泄漏 — 純通用範本，無 token/token/機密

---

## ✅ System Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| OS | macOS / Linux | Windows 不支援（優先平台） |
| Python | 3.10+ | 用於 app.py 與 requirements.txt |
| Port 開放埠 | ≥1 個 (預設 5080) | 避免與其他服务衝突 |

---

## 🚀 Quick Install

### Step 1: One-click install

```bash
curl -L https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/scripts/install.sh | bash
```

**說明**:
- `curl -L` 追隨重定向
- `bash` 執行安裝腳本
- 安裝過程會：檢查 Python3、建立目錄、複製檔案，最後在 port **5199** 啟動服務供健康檢查（正式使用可改）

---

### Step 2: Configure projects

編輯專案定義文件 `$AJD_HOME/app/projects.json`

```bash
# 查看範本架構
cat $AJD_HOME/apps/projects.example.json

# 複製範本並修改
cp $AJD_HOME/app/projects.example.json $AJD_HOME/app/projects.json
vim $AJD_HOME/app/projects.json
```

**範例 entry**:

```json
{
  "my-job": {
    "name": "每日報表生成",
    "type": "排程",
    "profile": "default",
    "bot": "@my_bot",
    "desc": "每日早晨 8:00 生成報表並推播 LINE",
    "services": ["api-gateway"],
    "depends_on": [],
    "entry": {
      "排程腳本": "/path/to/my/cron.py",
      "產出": "/output/dir/"
    },
    "links": []
  }
}
```

**字段說明**:
| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | 顯示名稱 |
| `type` | Yes | "排程" / "手動" / "服務" |
| `profile` | No | Hermes profile (若無) |
| `bot` | No | Bot username (@my_bot) |
| `desc` | No | 專案描述 |
| `services` | No | ADAPTER service keys |
| `depends_on` | No | 相依的 project names |
| `entry` | No | script paths + output dirs |
| `links` | No | Hyperlink objects |

---

### Step 3: Start the service

```bash
# Python 方式
cd $AJD_HOME/app && python3 app.py --port 5080 &

# Docker 方式 (需先建置映像檔)
docker-compose up -d --build
```

---

### Step 4: Verify installation

```bash
# 健康檢查
curl -s http://localhost:5080/api/state | jq .

# Heartbeat 測試
curl -X POST -H "Content-Type: application/json" \
     -d '{"job":"my-job","status":"ok","note":"success"}' \
     http://localhost:5080/api/heartbeat
```

**預期輸出**:

```json
{
  "heartbeats": [
    {
      "ts": "2026-10-14T09:00:00+08:00",
      "job": "my-job",
      "status": "ok",
      "note": "success"
    }
  ]
}
```

---

## 🤖 Agent Configuration

### Hermes

Add to `~/.hermes/profiles/default/memories/config`:

```bash
cat > ~/.hermes/profiles/default/memories/config <<EOF
AJD_URL="http://localhost:5080/"
EOF
```

Hermes 會自動讀取 `$AJD_HOME/projects.json` (透過 env var) 。

### Claude / Cursor / Windsurf

Add to your config file:

```jsonc
{
  "ai-jobs": {
    "dashboardUrl": "http://localhost:5080/",
    "registryPath": "$HOME/root/ajd/app/projects.json",
    "respectAGENTSmd": true
  }
}
```

**說明**:
- `dashboardUrl`: AJD API base URL
- `registryPath`: projects.json 絕對路徑 (或 env var `$HOME/.hermes/projects.json` )
- `respectAGENTSmd`: 啟用代理協議

### Other agents

AJD **不設外掛 API**，任何 agent 只需：
1. 讀取 `$AJD_HOME/app/projects.json`
2. POST `/api/heartbeat` 回報心跳
3. GET `/api/state` 取得狀態

---

## 🐳 Docker Install (Optional)

```bash
# Build image
docker build -t ajd -f Dockerfile .

# Run with docker-compose
docker-compose up -d --build

# View logs
docker-compose logs -f app
```

**Docker Compose Healthcheck**:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5080/api/state"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

## 🔐 Authentication (Optional)

AJD 預設認證關閉。若部署到公開網址，設 `auth_required=true`:

```bash
# Environment variable
export AJD_AUTH_REQUIRED="true"

# Revert to open access
export AJD_AUTH_REQUIRED="***"  # or unset
```

**說明**:
- 使用 `AJD_AUTH_REQUIRED="***"` 可讓 JWT token 存取（實際值未展示）
- 公開部署時才需啟用認證

---

## 🧹 Cleanup (Optional)

```bash
# Stop the background process
pkill app.py

# Or docker-compose down
docker-compose down
```

---

## ✅ Verification Checklist

安裝完成後的檢查清單:

- [ ] `/` 首頁顯示 "🛰 AJD"
- [ ] `/api/state` 回傳 JSON (含 heartbeats)
- [ ] POST `/api/heartbeat` 成功記錄心跳
- [ ] 無私人資料洩漏 (grep `macmima1234 hckytbot` 應全空)
- [ ] UI 标题為 "AJD · AI agents job dashboard"

---

## 📚 Related Documents

- [README.md](../README.md) — 英文說明
- [README-zh.md](../README-zh.md) — 中文說明
- [AGENTS.md](../AGENTS.md) — 代理配置指南
- [SETUP.md](../SETUP.md) — 手動設定流程
- [FAQ.md](FAQ.md) — 常見問題
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — 故障排除

---

## 🧪 Test Environment Info

本文檔測試環境:
- macOS 26.6.2 (MBP16 M1Pro 32GB)
- Python 3.x
- Port 5080 (預設)、5199(安裝測試用)

---

## 📝 Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| `PermissionError: [Errno 13] Permission denied` | 檢查 port 是否被占用，或改用 higher port (e.g., 5081) |
| `ModuleNotFoundError` | 安裝 requirements.txt (`pip3 install -r requirements.txt`) |
| Heartbeat 回傳錯誤 | 檢查 POST Body JSON 格式、timeout 設定 |
| Docker 啟動失敗 | 檢查 docker-compose.yml 內 network/port mappings |

詳細故障排除請見 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 。

---

## 🤝 Contributing

如有問題或想參與開發，歡迎:
- Issue: GitHub repo Issues
- PR: Contribution guidelines in `CONTRIBUTING.md` (WIP)

---

## 📜 License

MIT — See [LICENSE](../LICENSE) for details.

---

**Version**: v0.5.0  
**Last Updated**: 2026-10-14  