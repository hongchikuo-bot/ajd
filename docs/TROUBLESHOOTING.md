# AJD Troubleshooting Guide — 故障排除指南

---

## ❌ Installation Errors

### Error: `PermissionError: [Errno 13] Permission denied`

**原因**: 
- Port 5080 已被占用
- 或目錄權限不足 (chmod)

**解決方法**:

```bash
# 檢查 port 占用
lsof -i :5080

# 結束占用程式
kill $(lsof -t -i:5080)

# 或使用較高 port
python3 app.py --port 5081
```

**chmod**:
```bash
chmod 755 "$AJD_HOME"
chown -R $USER:$GROUP "$AJD_HOME"
```

---

### Error: `ModuleNotFoundError: No module named 'flask'`

**原因**: requirements.txt 未安裝。

**解決方法**:

```bash
cd $AJD_HOME/app
pip3 install -r requirements.txt
python3 app.py --port 5080 &   # 重新啟動
```

或：
```bash
pip3 install flask>=3.0.0
```

---

### Error: `address already in use` / `AddressFamilyError`

**說明**: port 已被占用。

**排查與解決**:

```bash
# 找出占用程式
lsof -i :5080 || netstat -an | grep 5080

# 查看是哪个 service
ps -p $(lsof -t -i:5080) -o comm

# 或切換 port
python3 app.py --port 5199 &   # 安裝測試用
```

**建議**: 
- 正式環境：固定使用 `--port 5080`，避免與其他 service 衝突。
- 測試/開發環境：可以使用 5xxx 範圍內的 port。

---

### Error: `curl: (3) URL using bad HTTP protocol version`

**原因**: curl 與 server 溝通時 HTTP/1.1 vs HTTP/2 版本問題（罕見）

**解決方法**:

```bash
curl --http1.1 http://localhost:5080/api/state > /dev/null && echo "success"
```

---

## 🤖 Agent Configuration Issues

### Issue: Agent 回報錯誤但心跳正常

**可能原因**: 
- Agent 讀取到舊的 projects.json 路徑
- `AJD_URL` env var 未設定
- respectAGENTSmd=false（agent 不遵循 AGENTS.md 說明）

**排查步驟**:

```bash
# 1. 確認 env var
env | grep AJD_HOME

# 2. 確認 projects.json 存在
cat "$AJD_HOME/app/projects.json" | head -n 10

# 3. 檢查 agent config（Hermes memories/config）
cat ~/.hermes/profiles/default/memories/config | grep AJD_URL
```

**解決方法**: 

- 確保 `AJD_HOME` env var 正確設為 `$HOME/root/ajd`。
- 設定 `AJD_URL="http://localhost:5080/"`。
- respectAGENTSmd=true（讓 agent 閱讀 AGENTS.md）。

---

### Issue: Agent 宣稱"完成"但未實際運行任務

**驗證方法**:

```bash
# 1. 心跳記錄檢查
curl http://localhost:5080/api/state | jq '.heartbeats[] | {job, status}'

# 2. 確認 output file 有更新
ls -la "$AJD_HOME/app/projects.json"
cat "/path/to/output/" > /dev/null && echo "output dir exists"

# 3. 服務狀態檢查
curl http://localhost:5080/api/services --get \
   --data "name=api-gateway" | jq .
```

**建議**: 
- Agent config 內加入 `respectAGENTSmd: true`。
- 不輕易相信 agent 的"完成"/"上傳成功"宣稱 —— 必須查實際檔案狀態。

---

## 🐳 Docker Deployment Issues

### Error: `docker-compose: command not found`

**解決方法**:

```bash
brew install docker-compose
# or
brew tap docker/compose
brew install docker-compose-v2
```

或安裝官方：

```bash
curl -fsSL https://get.docker.com | sh
```

---

### Error: `Cannot start service app: bind mount failure`

**原因**: 卷掛載失敗（目錄不存在、權限不足）。

**排查與解決**:

```bash
# 檢查 volume 目錄
ls -la "$AJD_HOME/data" "$AJD_HOME/snapshots"
mkdir -p "$AJD_HOME"/data "$AJD_HOME"/snapshots

# 調整權限
chown -R $(whoami):$(id -gn) "$AJD_HOME"
chmod -R 755 "$AJD_HOME"

# rebuild image
docker-compose build --no-cache
docker-compose up -d
```

---

### Error: Container restarts automatically after startup

**排查方法**:

```bash
docker logs app | tail -n 100
```

常見原因:
- Python crash（missing dependency）
- Port already in use
- Missing volume directories

**解決方法**: 參考上方排查步驟。

---

## 🔐 Authentication Failures

### Error: `Unauthorized` on `/api/state`

**檢查認證**:

```bash
# 確認環境變數
env | grep AJD_AUTH

# 預設關閉（AUTH_REQUIRED=***）
echo "Auth enabled? $([ -z "$AJD_AUTH_REQUIRED" ] && echo "disabled" || echo "enabled")"

# 若已啟用，使用 token 存取
export JWT_TOKEN="your-token-here"
curl http://localhost:5080/api/state -H "Authorization: Bearer $JWT_TOKEN"
```

**禁用認證（測試用）**:

```bash
AJD_AUTH_REQUIRED="***" python3 app.py --port 5080 &
```

---

### Error: JWT token rejected / Invalid authentication

**可能原因**:
- Token 已過期或格式錯誤
- 需要重新獲取 token（登入頁面顯示）

**解決方法**:
- 使用 `browser_vault_list` 查看儲存 logins。
- 在登入頁保存 login，Hermes 會自動產生 token。

---

## 📊 Heartbeat Monitoring Issues

### Issue: Heartbeat API 記錄心跳但未反映在服务狀態頁面

**說明**: `/api/state` 回傳的心跳是全部記錄，服務狀態則顯示當前健康。
若 heartbeat 回傳 `status:"fail"`, API state 會標記該 job 為異常。

**排查方法**:

```bash
# 查看所有心跳記錄
curl http://localhost:5080/api/state | jq '.heartbeats[]'

# 確認特定 job 狀態
curl http://localhost:5080/api/state | jq '.heartbeats[] | select(.job=="my-job")'

# 清理旧记录（手動）
mv /data/heartbeats.jsonl /data/heartbeats.jsonl.bak
echo '[]' > /data/heartbeats.jsonl
```

---

### Issue: Heartbeat file grows too large

**解決方法**: 定期清理舊記錄（例如保留最近 24h）。

```bash
# Python cleanup script (example)
#!/usr/bin/env python3
from datetime import datetime, timedelta, timezone
import json

cutoff = datetime.now(timezone(timedelta(hours=8))) - timedelta(days=7)
with open('/data/heartbeats.jsonl') as f:
    with open('/tmp/hb.jsonl', 'w') as out:
        for line in f:
            hb = json.loads(line)
            if cutoff <= datetime.fromisoformat(hb['ts'][:-1].replace('+08:00','+00:00')):
                out.write(line)

import glob, os
import glob
for fb:
    os.remove(fb)
# move back after cleaning
mv /tmp/hb.jsonl /data/heartbeats.jsonl
```

---

## 🌐 Network & Multi-Platform

### Error: `curl http://localhost:5080/ -> 404 Not Found`

**原因**: 首頁路由尚未註冊或 app 未正確啟動。

**排查方法**:

```bash
# Check app.py routes
grep -n "@app.route" $AJD_HOME/app/app.py | head -n 10

# List open ports
netstat -an | grep LISTEN
```

**解決方法**: 
- 重新啟動 service: `pkill app.py; python3 app.py &`
- 檢查是否有路由錯誤。

---

### Error: CORS preflight failed when calling from browser

AJD default disabled CORS（安全設定）。若需從 web 呼叫 API，需 reverse proxy (nginx):

```nginx
location / {
    proxy_pass http://localhost:5080;
    add_header Access-Control-Allow-Origin *;
}
```

或直接修改 app.py（開發環境）：

```python
@app.after_request
def add_cors_headers(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response
```

---

## 🧪 Testing & Validation Errors

### Error: `tests fail during demo_flow.sh`

**常見原因**: 
- Services 未啟動（如 api-gateway, db-primary）
- Heartbeat endpoint POST body format incorrect
- Port conflict

**排查方法**:

```bash
# Check services state
curl http://localhost:5080/api/services --data json '{"name":"api-gateway"}' | jq .

# Verify heartbeat endpoint
curl -X POST http://localhost:5080/api/heartbeat \\
     -H "Content-Type: application/json" \\
     -d "{\"job\":\"test\",\"status\":\"ok\"}"
```

**預期輸出**:
- Services: `{"up":true,"detail":"..."}`
- Heartbeat: `{"ok":true,"job":"xxx","ts":"..."} `

---

## 📝 General Tips

1. **不要相信 agent 的"完成"宣稱** → 務必查：
   - `/api/state` 的心跳記錄
   - Output file 實際狀態
   
2. **Always use `bash -n` for .sh files**:
   ```bash
   bash -n your_script.sh || echo "syntax error, fix first"
   ```

3. **Always verify .py with `python3 -m py_compile`**:
   ```bash
   python3 -m py_compile app.py && echo "OK"
   ```

4. **No `/Users/` hardcoding in output/logs** → 使用 `$HOME`, `$AJD_HOME`。

5. **No private traces before release**:
   ```bash
   grep -ril "macmima1234|hckytbot" /path/to/repo/app/ | grep -v pycache || echo "clean ✓"
   ```

---

## 📞 Contact & Support

若問題未在上述解答:
- GitHub Issues: [https://github.com/hongchikuo-bot/ajd/issues](https://github.com/hongchikuo-bot/ajd/issues)
- Read docs folder (INSTALL_GUIDE.md, FAQ.md, SCOPE.md)
- Check `AGENTS.md` for agent-specific guidance

---

## 📚 Related Docs

- [INSTALL_GUIDE.md](../docs/INSTALL_GUIDE.md) — 安裝教學
- [FAQ.md](../docs/FAQ.md) — 常見問題集
- [SETUP.md](../SETUP.md) — 手動設定流程
- [README.md](../README.md) — 英文主檔
- [README-zh.md](../README-zh.md) — 中文說明
- [AGENTS.md](../AGENTS.md) — 代理配置指南

---

**Version**: v0.5.0  
**Last Updated**: 2026-10-14