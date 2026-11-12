# AJD FAQ — 常見問題集

---

## 📦 Installation & Setup

### Q1: 安裝後顯示 "ModuleNotFoundError: No module named 'flask'" 怎麼辦？

**原因**: requirements.txt 內的 flask 未安裝。  
**解決方法**:

```bash
cd $AJD_HOME/app
pip3 install -r requirements.txt
python3 app.py --port 5080
```

或使用:
```bash
pip3 install flask>=3.0.0
```

---

### Q2: port 顯示 "address already in use" 怎麼辦？

**原因**: 另一個服务正在使用 port 5080。  
**解決方法**: 

1. 檢查並結束占用程式:
   ```bash
   lsof -i :5080
   kill $(lsof -t -i:5080)
   ```

2. 或改用其他 port（例如 5081）:
   ```bash
   python3 app.py --port 5081
   ```

**注意**: install.sh 預設使用 port `5080`，可透過 `--port` 參數指定。

---

### Q3: curl POST /api/heartbeat 回傳 "405 Method Not Allowed"？

**這是正常的**! `/api/heartbeat` 僅支援 **POST**，GET 會回傳 405。  
正確使用方式:

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -H "Content-Type: application/json" \
     -d '{"job":"my-job","status":"ok"}'
```

---

### Q4: 認證頁面出現，但我沒有設 `AJD_AUTH_REQUIRED=true`？

**排查步驟**:

1. 檢查環境變數:
   ```bash
   env | grep AJD_AUTH
   ```

2. 若顯示 `***`，則代表已啟用（預設關閉）。  
3. 要重新開機後才生效。

---

### Q5: `$HOME/root/ajd/app/projects.json` 找不到？

**說明**: install.sh 會自動建立並複製範本文件到 `$AJD_HOME/app/` 目錄。若沒有執行 `install.sh`，需手動建立:

```bash
mkdir -p "your_home/root/ajd"
# 手動抄寫 install.sh 腳本內容，或從 GitHub clone
git clone https://github.com/hongchikuo-bot/ajd.git
cd ajd
mv app/*.py "$HOME/root/ajd/"
mv apps/* "$HOME/root/ajd/"
```

---

## 🤖 Agent Configuration

### Q6: Hermes 如何自動讀取 AJD 的 projects.json？

方法 1: 設定環境變數 `$AJD_HOME$:

```bash
export AJD_HOME="$HOME/root/ajd"
echo $AJD_HOME
# → $HOME/root/ajd  (expands to your actual home path)
```

Hermes 會自動查找並讀取：
- `$AJD_HOME/app/projects.json`
- 或 `~/.hermes/projects.json` (若透過 env var 指定)

方法 2: 在 profile 內設定 `AJD_URL`:

```bash
echo 'AJD_URL="http://localhost:5080/"' \
     >> ~/.hermes/profiles/default/memories/config
```

---

### Q7: Claude/Cursor/Windsurf 如何連到 AJD？

在 agent config 加入:

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
- `registryPath`: projects.json 的絕對路徑（或 env var）
- respectAGENTSmd: 啟用代理協議

---

### Q8: Agent 宣稱"完成"但實際上沒有成功？

**驗證方法**:

1. **Heartbeat API 檢查**:
   ```bash
   curl http://localhost:5080/api/state | jq '.heartbeats[] | {job, status}'
   # → 查看 job="xxx" 是否回傳 "ok" 或 "fail" 而非空值
   ```

2. **Check output file**:
   - 確認 `entry.outputs` 指定的目錄有新增檔案。
   
3. **Check service adapter**:
   ```bash
   curl http://localhost:5080/api/services\?name=xxx
   # → 回傳 {up, detail}，確認服務正常
   ```

**建議**: 在 agent config 內加入 `respectAGENTSmd: true`，讓 agent 遵循 AGENTS.md 的說明（不妄自斷言）。

---

## 📊 Heartbeat Monitoring

### Q9: 心跳機制為何不用檔案時間戳記？

答: 檔案修改時間可能被誤判 (例如系統備份、cron 跑完等觸發)，因此採用 **Heartbeat API**。
任何排程都應在執行時 POST 心跳:

```bash
curl -X POST http://localhost:5080/api/heartbeat \
     -d '{"job":"my-script","status":"ok"}'
```

失敗時:
```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -d '{"job":"my-script","status":"fail","note":"error log"}'
```

---

### Q10: `/api/state` 回傳的心跳記錄太多如何過濾？

方法 1: 使用 `limit`:

```bash
curl http://localhost:5080/api/state\?limit=10 | jq '.heartbeats[-10:]'
```

方法 2: 定期清理舊記錄 (例如保留最近 24h):

```bash
# python snippet in app.py or use a separate script
from datetime import datetime, timedelta
cutoff = now() - timedelta(hours=24) # delete older than 24h
# ... implement cleanup logic ...
```

**說明**: 心跳檔案目前無自動清理機制，需要定期手動或透過 API cleanup 端點處理。

---

## 🐳 Docker Deployment

### Q11: `docker-compose up` 無法啟動？

常見原因:
1. **Docker not installed**: `docker --version` → 安裝 docker (brew install or official installer)
2. **Compose not installed**: `docker-compose version` → brew install docker-compose
3. **Network error**: 檢查 `/etc/docker/daemon.json` network settings
4. **Port conflict**: 確保 port mappings (e.g., `5080:5080`) 未被占用

**解決方法**:

```bash
# 重新建置
docker-compose down
docker-compose build
docker-compose up -d
```

---

### Q12: docker-compose 無法找到 "app" service？

確保 `docker-compose.yml` 內包含:

```yaml
version: '3.8'

services:
  app:
    build: ./
    ports:
      - "5080:5080"
    volumes:
      - ./data:/app/data
      - ./projects.json:/app/projects.json
    environment:
      - AJD_PORT=5080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5080/api/state"]
      interval: 30s
```

---

### Q13: Docker container 不斷 restart？

檢查 logs:
```bash
docker-compose logs app
```

常見問題:
- **Python not installed inside image**: `Dockerfile` 內已處理 (安裝 requirements.txt)
- **Port conflict**: 修改 `ports` mapping
- **Permission denied**: 確保 volume folders permissions (`chmod 755`)

---

## 🔐 Security & Privacy

### Q14: 如何開啟認證？

設定環境變數:
```bash
export AJD_AUTH_REQUIRED="true"
python3 app.py --port 5080
```

**說明**: 重新啟動後才生效。  
公開部署時建議同時啟用：
- CORS settings
- Rate limiting (Flask-Limiter)
- HTTPS (reverse proxy via nginx)

---

### Q15: AJD 會上傳任何資料到雲端嗎？

**絕對不會**。AJD **完全本地運作**:
- 無 telemetry
- 無外掛 API calls
- 無數據傳輸到外部伺服器
- 所有檔案僅在本機目錄內

符合 Agent Safety Policy。

---

## 🔄 Maintenance

### Q16: 版本更新時會覆蓋現有配置嗎？

使用 `install.sh` 安裝後，再次執行不會覆蓋：
- `$AJD_HOME/app/projects.json` → 使用者自訂的專案定義
- `/data/heartbeats.jsonl` → 心跳記錄 (但會被刪除！注意)
- `/snapshots/*` → 報表檔案

若要升級至新版本:
1. Backup: `cp $AJD_HOME/app/projects.json ~/.ajd-backup.projects.json`
2. Reinstall: `curl -L install.sh | bash`
3. Restore config: `cp ~/.ajd-backup.projects.json $AJD_HOME/app/projects.json`

---

### Q17: 如何手動清理舊心跳記錄？

```bash
# Backup current heartbeats
mv /data/heartbeats.jsonl /data/heartbeats.jsonl.backup

# Start fresh (or use API cleanup endpoint if available)
cat > /data/heartbeats.jsonl <<'EOF'
{"ts":"2026-10-14T00:00:00+08:00","job":"initial-sync","status":"ok"}
EOF
```

或使用 API(若實作):
```bash
curl -X POST http://localhost:5080/api/heartbeat \
  -d '{"action":"cleanup","older_than":3600}'
```

---

### Q18: 如何監聽特定 project 的 heartbeat?

AJD **不使用檔案時間戳記**，因此無法透過 `find /data -mmin +...` 判斷時效性。  
建議方式:
- 監控 `/api/state` (polling)
- 設定 webhook(未來擴充): POST `/heartbeat/callback/:project_id`

---

## 🧪 Testing & Validation

### Q19: 如何驗證安裝是否成功？

**完整檢查流程**:

```bash
# 1. Check service status
curl http://localhost:5080/api/state | jq .

# 2. Test heartbeat endpoint
curl -X POST http://localhost:5080/api/heartbeat \
     -H "Content-Type: application/json" \
     -d '{"job":"test","status":"ok"}'

# 3. Verify heartbeat recorded
curl http://localhost:5080/api/state | jq '.heartbeats[] | {job, status}' \
   | grep test

# 4. Check for private traces (should be empty)
grep -ril "macmima1234|hckytbot" /Users/.../$AJD_HOME/app/ | grep -v pycache
```

所有步驟成功 → ✅ 安裝完成。

---

### Q20: 如何產出 demo screenshots for documentation?

```bash
cd $AJD_HOME
python3 scripts/gen_demo_screenshots.py
# → docs/screenshot-desktop.png, docs/screenshot-mobile.png
```

或直接使用已提供的 screenshot (公開 repo 內)。

---

## 🌐 Multi-Platform Deployment

### Q21: AJD 支援 Windows 嗎？

目前**僅 macOS + Linux**。Windows 不支援的原因:
- Python path handling（路徑大小寫）
- Port forwarding/NGINX反向代理配置複雜
- Hermes 主要針對 macOS/Linux

若要用於 Windows，建議使用 WSL2。

---

### Q22: 可以在 NAS (TrueNAS) 上運行嗎？

可以! 使用 Docker:
1. 安裝 TrueNAS app（或 Synology Container Manager）
2. `git clone https://github.com/hongchikuo-bot/ajd.git`
3. 修改 docker-compose.yml:
   - 設定 volumes (`/mnt/data → /app/data`)
   - 調整 port mapping (內網 IP:5080)
4. `docker-compose up -d --build`

**注意**: TrueNAS/Docker 需支援 python3。

---

## 🤝 Contributing

### Q23: 如何提出 Issue？

1. [GitHub Issues](https://github.com/hongchikuo-bot/ajd/issues) → "New Issue"
2. 選擇 "bug report" / "feature request" / "question"
3. 提供：
   - 環境資訊（OS、版本、port）
   - 錯誤訊息/堆疊追蹤 (stack trace)
   - 可重現步驟

---

### Q24: 可以提交 PR 嗎？

可以！但請先查看:
- [CONTRIBUTING.md](../CONTRIBUTING.md) — 貢獻指南
- 確保通過 CI 驗證
- 不引入私人資料洩漏（grep 檢查）

---

## 📚 Related Docs

- [INSTALL_GUIDE.md](INSTALL_GUIDE.md) — 完整安裝流程
- [SETUP.md](SETUP.md) — 手動設定指南
- [AGENTS.md](AGENTS.md) — 代理配置說明
- [README.md](../README.md) — 英文主檔
- [README-zh.md](../README-zh.md) — 中文說明

---

## 📝 Revision History

| Version | Date | Changes |
|---------|------|---------|
| v0.5.0 | 2026-10-14 | Initial FAQ release |

---

**Version**: v0.5.0  
**Last Updated**: 2026-10-14