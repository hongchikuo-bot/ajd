# Phase 6: Visual Assets & UX Improvements (0.5 days)
## 目的
製作或優化截圖展示 UI、產生短 GIF 說明關鍵功能（心跳告警、排程狀態），並完成 Release 前的最後驗證。

---

## 交付物清單

| 文件 | 內容 | 驗證方式 |
|------|------|---------|
| `docs/screenshots/` 或現有 `docs/screenshot-*.png` | 高品質截圖（1920x1080） | `ls docs/*.png` + 視覺確認 |
| `docs/GIFs/heartbeat-alert.gif` | 心跳告警動畫 (循環，<3MB) | `file docs/GIFs/*.gif` |
| `phase6_validation.sh` | 驗證腳本（檢查文件完整性、大小限制） | `bash phase6_validation.sh` → 0 errors |
| `AGENTS.md`（更新） | 確保包含心跳 API 範例、`curl http://localhost:5080/api/state` | `cat AGENTS.md \\\ngrep 'heartbeat'` |
| `README.md`（已準備） | 包含截圖連結（GitHub release） | `ls README.md` |

---

## 驗證清單（每項必須通過才能 Release）

### 1. 私人痕跡掃描 —— 必須 0 筆

```bash
grep -rIl -e macmima1234 -e hckytbot -e bot -e zaiditong \
     -e ethubs -e stock_auto -e news_auto \
     ~/root/ajd/app/data install.sh | grep -v __pycache__
# 預期輸出：完全沒有東西
```

### 2. 不該存在的文件（存在就是沒做完）

```bash
cd ~/root/ajd && ls data/archive/ data/snapshots/*.log *.png __pycache__/ 2>&1 || echo "✅ Clean"
# ✅ 這些目錄應該空或不存在（GitHub 公開版）
```

### 3. 真的能跑

```bash
cd ~/root/ajd/app && python3 app.py --port 5081 &
sleep 3
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:5080/ | grep '^2$'
kill %1
# 預期：HTTP 200（如果 port 5080 已有服務就忽略）
```

### 4. GITHUB_RELEASE_SUMMARY 包含完整清單

```bash
cat docs/GITHUB_RELEASE_SUMMARY.md | grep -c '✅'
# 預期：至少 8+ 個 ✅ 標示的交付物
```

### 5. AGENTS.md 正確引用 API 端點

```bash
cd ~/root/ajd && grep '/api/state' AGENTS.md
# 必須存在且 app.py 確實有這個端點
```

---

## 下一步（Phase 7: GitHub Release）

1. **push release/v0.5.0** → `git push origin release/v0.5.0`
2. **Create tag v0.5.0** → `git tag -a v0.5.0 -m "v0.5.0 release" && git push origin v0.5.0`
3. **GitHub UI Create Release** 標籤指向 `v0.5.0`，上傳 assets（截圖放在 docs/screenshots/、GIF 檔）
4. **README.md update** → GitHub Releases auto-includes README

---

## 卡住？

無。此階段為最後視覺化與驗證工作。所有文件已在本地、只待推送到 GitHub。
