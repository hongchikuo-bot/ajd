# 📝 SETUP.md — AI Agents Job Dashboard (AJD)

## 關於心跳（heartbeat）回報

AJD 的核心設計是讓你的 cron job 在執行完畢後回傳 heartbeat，以表明：「我已經跑過了」。這可幫助你即時發現失敗的排程任務。

**範例**:
```bash
curl -X POST http://localhost:5080/api/heartbeat -H "Content-Type: application/json" -d "{\"job\":\"my-job\",\"status\":\"ok\"}"
```

## 快速開始：無 agent 手動模式

1. **安裝**：執行 `bash ~/root/ajd/app/install.sh`
2. **設定環境變數**:
   ```bash
   export AJD_URL="http://localhost:5080/"
   export AJD_REGISTRY="$HOME/.hermes/projects.json"
   ```
3. **在 cron/job 尾端加上 heartbeat**：
   ```bash
   /my-cron.sh && curl -X POST $AJD_URL/api/heartbeat -d "{\"job\":\"cron\",\"status\":\"ok\"}" || echo "heartbeat pending"
   ```
4. **測試**: `curl http://localhost:5080/health`

## Customization Tips

- 自訂 heartbeat timeout：在 `projects.json` 設定 `"heartbeatTimeoutMinutes": 60`
- Docker 環境：設 `AJD_PORT=5080` 並於 `docker-compose.yml` 暴露 port

## 故障排查

| 現象 | 原因 | 對策 |
|---|---|---|
| `/health → 401` | 未 auth | `/api/heartbeat` 需要驗證；設定 token。 |
| job 成功但心跳失敗 | network/firewall | 檢查 firewall rule。 |

## 相關文件

- `README.md` — 完整英文說明
- `AGENTS.md` — AI agent 設定指南  
- [SCOPE.md](/root/ajd/SCOPE.md) — AJD 設計原則
