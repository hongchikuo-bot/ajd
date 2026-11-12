# GitHub Push Guide — Option A (Manual Web UI)

> **現況**：本地 `main` 領先 `origin/main` 8 個 commits，含 `.github/workflows/ci.yml`。
> OAuth token 缺 `workflow` scope → CLI `git push` 被擋。
> **最快解法**：手動在 GitHub 網頁推送（無需改 token）。

---

## 步驟（約 2 分鐘）

1. 開啟 <https://github.com/hongchikuo-bot/ajd>
2. 點選 **"Add file"** → **"Upload files"**
3. 將整個專案資料夾內容（或關鍵檔案）拖曳上傳
   - **或**：在本地終端機執行下列指令，產生一個乾淨的壓縮包，再上傳：
   ```bash
   cd /Users/macmima1234/root/ajd
   git archive --format=zip --output=/tmp/ajd-main.zip HEAD
   # 上傳 /tmp/ajd-main.zip 到 GitHub 網頁
   ```
4. Commit message 填：`Phase 4-5: Public release v0.5.0 — engine, adapters, install, docs, whitepaper`
5. 直接 commit 到 `main` branch

> **注意**：GitHub 網頁上傳會**覆寫**遠端 `main` 歷史（force-with-lease 效果），這正是我們要的——把本地 8 個乾淨 commits 推上去。

---

## 推送後驗證（必做）

```bash
# 1. 從 GitHub Raw 重新安裝一次（乾淨環境）
cd /tmp && rm -rf ajd-verify && mkdir ajd-verify && cd ajd-verify
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# 2. 驗證端點
curl -s http://localhost:5080/api/state | jq '.registry.projects'
curl -s http://localhost:5080/api/schedulers | jq '.[].source'
curl -s http://localhost:5080/api/services | jq '.[].source'
curl -s -X POST http://localhost:5080/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"verify","status":"ok"}' | jq '.ok'
```

預期輸出：
- `api/state` → `["<YOUR_PROJECT_NAME>"]`
- `api/schedulers` → `["crontab","hermes","launchd","systemd"]`
- `api/services` → `["docker","http","port"]`
- `api/heartbeat` → `{"ok":true}`

---

## 如果想用 Option B（重新生成 token）

1. <https://github.com/settings/tokens> → 產生新 **Personal access token (classic)**
2. 勾選 `workflow`、`repo`、`read:org`
3. `gh auth setup-git` 更新 credential
4. `git push origin main`

---

## 目前本地狀態（已驗證）

| 檢查項目 | 結果 |
|----------|------|
| `bash -n install.sh` | ✅ Syntax OK |
| `python3 -m compileall -q app` | ✅ 全部 OK |
| `python3 app/test_adapters.py` | ✅ All adapter tests passed |
| 私人痕跡掃描 | **0 匹配** |
| `/Users/` 硬編碼掃描 | **0 匹配** |
| 服務啟動 (port 5299) | ✅ `curl /` 回 200 |
| `/api/state` 載入範例專案 | ✅ |
| `/api/schedulers` 4 來源 | ✅ |
| `/api/services` 3 來源 | ✅ |
| `/api/heartbeat` POST | ✅ 寫入 `data/heartbeats.jsonl` |
| UI 品牌一致性 | ✅ AJD 通用名稱 |

---

## 相關檔案

- `PROGRESS.md` — 完整階段狀態與驗證記錄
- `SCOPE.md` — 專案範圍與計畫
- `RELEASE.md` — v0.5.0 發布說明