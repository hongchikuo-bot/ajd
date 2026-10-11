## 2026-10-11 14:00 ✅ app.py --port 修正 + 端點全驗證通過（11 commits 領先）
### 📦 產出
- 修正 `app/app.py`：`--port` 參數現在正確覆蓋 `AJD_PORT` 環境變數（原本只讀環境變數，忽略 CLI 參數）
- `PUSH_GUIDE.md` 已入庫（commit af934df），含手動 Web UI 推送步驟（Option A）與 token 更新步驟（Option B）、推送後驗證腳本
- 本地 `main` 現領先 `origin/main` **11 個 commits**，等待 kk 推送

### 🔍 驗證結果（本輪完整重跑，AJD_HOME=/Users/macmima1234/root/ajd，port 5405）
- `bash -n install.sh` → Syntax OK
- `python3 -m compileall -q app` → 全部 OK（含 test_adapters.py）
- `python3 app/test_adapters.py` → ✅ All adapter tests passed
- 私人痕跡掃描 → **0 匹配**
- `/Users/` 硬編碼掃描 → **0 匹配**
- 服務啟動 (port 5405, AJD_HOME 指定) → `curl /` 回 **200**
- `/api/state` 載入範例專案 ✅ (`{"projects": {"<YOUR_PROJECT_NAME>": {...}}}`)
- `/api/schedulers` 4 來源 ✅ (crontab, hermes, launchd, systemd)
- `/api/services` 3 來源 ✅ (docker, http, port)
- `/api/heartbeat` POST 寫入 `data/heartbeats.jsonl` ✅ → 回傳 `{"ok": true}`
- UI 品牌一致性：manifest / index.html / projects.json 均為 AJD 通用名稱 ✅

### 📋 完整階段狀態（最終版）
| 階段 | 狀態 | 驗證方式 |
|------|------|----------|
| Phase 0: 抽出引擎 | ✅ | `projects.example.json` 產出、私人痕跡 0 匹配 |
| Phase 1: Adapter 層 | ✅ | 4 scheduler + 3 service adapters，`/api/schedulers` `/api/services` 回傳正確 |
| Phase 2: 一鍵部署 | ✅ | `install.sh` + `AGENTS.md` + agent 偵測，語法檢查通過 |
| Phase 3: 文件 | ✅ | README.md/en/zh, USAGE.md, RELEASE.md, SETUP.md, WHITEPAPER.md |
| Phase 4: 打包與發布 | ✅ | Dockerfile, docker-compose.yml, GitHub Actions CI, LICENSE MIT，**乾淨目錄從零裝驗證通過**、**CI 測試通過** |
| Phase 5: 白皮書 | ✅ | `docs/WHITEPAPER.md` |

### 🟢 下一步（需 kk 決定）
**唯一待辦：GitHub 推送** — 現行 OAuth token 缺少 `workflow` scope，CLI 推送被擋。

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 11 個 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
cd /tmp && rm -rf ajd-verify && mkdir ajd-verify && cd ajd-verify
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-11 13:30 ✅ PUSH_GUIDE.md 入庫 + 本地 commits 9 筆領先 origin/main
### 📦 產出
- `PUSH_GUIDE.md` 已加入 git（commit af934df），含手動 Web UI 推送步驟（Option A）與 token 更新步驟（Option B）、推送後驗證腳本
- 本地 `main` 現領先 `origin/main` **9 個 commits**，等待 kk 推送

### 🔍 驗證結果（本輪完整重跑，AJD_HOME=/Users/macmima1234/root/ajd）
- `bash -n install.sh` → Syntax OK
- `python3 -m compileall -q app` → 全部 OK（含 test_adapters.py）
- `python3 app/test_adapters.py` → ✅ All adapter tests passed
- 私人痕跡掃描 → **0 匹配**
- `/Users/` 硬編碼掃描 → **0 匹配**
- 服務啟動 (port 5400, AJD_HOME 指定) → `curl /` 回 200
- `/api/state` 載入範例專案 ✅ (`{"projects": {"<YOUR_PROJECT_NAME>": {...}}}`)
- `/api/schedulers` 4 來源 ✅ (crontab, hermes, launchd, systemd)
- `/api/services` 3 來源 ✅ (docker, http, port)
- `/api/heartbeat` POST 寫入 `data/heartbeats.jsonl` ✅
- UI 品牌一致性：manifest / index.html / projects.json 均為 AJD 通用名稱 ✅

### 📋 完整階段狀態（最終版）
| 階段 | 狀態 | 驗證方式 |
|------|------|----------|
| Phase 0: 抽出引擎 | ✅ | `projects.example.json` 產出、私人痕跡 0 匹配 |
| Phase 1: Adapter 層 | ✅ | 4 scheduler + 3 service adapters，`/api/schedulers` `/api/services` 回傳正確 |
| Phase 2: 一鍵部署 | ✅ | `install.sh` + `AGENTS.md` + agent 偵測，語法檢查通過 |
| Phase 3: 文件 | ✅ | README.md/en/zh, USAGE.md, RELEASE.md, SETUP.md, WHITEPAPER.md |
| Phase 4: 打包與發布 | ✅ | Dockerfile, docker-compose.yml, GitHub Actions CI, LICENSE MIT，**乾淨目錄從零裝驗證通過**、**CI 測試通過** |
| Phase 5: 白皮書 | ✅ | `docs/WHITEPAPER.md` |

### 🟢 下一步（需 kk 決定）
**唯一待辦：GitHub 推送** — 現行 OAuth token 缺少 `workflow` scope，CLI 推送被擋。

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 9 個 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
cd /tmp && rm -rf ajd-verify && mkdir ajd-verify && cd ajd-verify
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-11 13:05 ✅ GitHub Push Guide 建立 + 完整端點驗證全過（含 AJD_HOME 設定正確性）

### 📦 產出
- 新增 `PUSH_GUIDE.md` — 給 kk 的手動 Web UI 推送步驟（Option A），含推送後驗證指令

### 🔍 驗證結果（本輪完整重跑，AJD_HOME=/Users/macmima1234/root/ajd）
- `bash -n install.sh` → Syntax OK
- `python3 -m compileall -q app` → 全部 OK（含 test_adapters.py）
- `python3 app/test_adapters.py` → ✅ All adapter tests passed
- 私人痕跡掃描 → **0 匹配**
- `/Users/` 硬編碼掃描 → **0 匹配**
- 服務啟動 (port 5400, AJD_HOME 指定) → `curl /` 回 200
- `/api/state` 載入範例專案 ✅ (`{"projects": {"<YOUR_PROJECT_NAME>": {...}}}`)
- `/api/schedulers` 4 來源 ✅ (crontab, hermes, launchd, systemd)
- `/api/services` 3 來源 ✅ (docker, http, port)
- `/api/heartbeat` POST 寫入 `data/heartbeats.jsonl` ✅
- UI 品牌一致性：manifest / index.html / projects.json 均為 AJD 通用名稱 ✅

> **關鍵發現**：`/api/state` 與 `/api/services` 需正確設定 `AJD_HOME` 環境變數（指向含 `projects.json` 的目錄），否則預設讀 `~/.ajd` 導致 500 錯誤。`install.sh` 已正確處理此設定。

### 📋 完整階段狀態（最終版）
| 階段 | 狀態 | 驗證方式 |
|------|------|----------|
| Phase 0: 抽出引擎 | ✅ | `projects.example.json` 產出、私人痕跡 0 匹配 |
| Phase 1: Adapter 層 | ✅ | 4 scheduler + 3 service adapters，`/api/schedulers` `/api/services` 回傳正確 |
| Phase 2: 一鍵部署 | ✅ | `install.sh` + `AGENTS.md` + agent 偵測，語法檢查通過 |
| Phase 3: 文件 | ✅ | README.md/en/zh, USAGE.md, RELEASE.md, SETUP.md, WHITEPAPER.md |
| Phase 4: 打包與發布 | ✅ | Dockerfile, docker-compose.yml, GitHub Actions CI, LICENSE MIT，**乾淨目錄從零裝驗證通過**、**CI 測試通過** |
| Phase 5: 白皮書 | ✅ | `docs/WHITEPAPER.md` |

### 🟢 下一步（需 kk 決定）
**唯一待辦：GitHub 推送** — 現行 OAuth token 缺少 `workflow` scope，CLI 推送被擋。

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 8 個 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
cd /tmp && rm -rf ajd-verify && mkdir ajd-verify && cd ajd-verify
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-11 10:00 ✅ 未追蹤檔案入庫 + 全驗證再跑一次全過
### 📦 產出
- 將 `app/test_adapters.py`、`scripts/push_helper.sh`、`test_clean_install/` 加入 git 並提交 (commit 933ecb1)

### 🔍 驗證結果（本輪完整重跑）
- `bash -n install.sh` → Syntax OK
- `python3 -m compileall -q app` → 全部 OK（含 test_adapters.py）
- `python3 app/test_adapters.py` → ✅ All adapter tests passed
- 私人痕跡掃描 → **0 匹配**
- `/Users/` 硬編碼掃描 → **0 匹配**
- 服務啟動 (port 5299) → `curl /` 回 200
- `/api/state` 載入範例專案 ✅ (`["<YOUR_PROJECT_NAME>"]`)
- `/api/schedulers` 4 來源 ✅ (crontab, hermes, launchd, systemd)
- `/api/services` 3 來源 ✅ (docker, http, port)
- `/api/heartbeat` POST 寫入 `data/heartbeats.jsonl` ✅

### 📋 完整階段狀態（最終版）
| 階段 | 狀態 | 驗證方式 |
|------|------|----------|
| Phase 0: 抽出引擎 | ✅ | `projects.example.json` 產出、私人痕跡 0 匹配 |
| Phase 1: Adapter 層 | ✅ | 4 scheduler + 3 service adapters，`/api/schedulers` `/api/services` 回傳正確 |
| Phase 2: 一鍵部署 | ✅ | `install.sh` + `AGENTS.md` + agent 偵測，語法檢查通過 |
| Phase 3: 文件 | ✅ | README.md/en/zh, USAGE.md, RELEASE.md, SETUP.md, WHITEPAPER.md |
| Phase 4: 打包與發布 | ✅ | Dockerfile, docker-compose.yml, GitHub Actions CI, LICENSE MIT，**乾淨目錄從零裝驗證通過**、**CI 測試通過** |
| Phase 5: 白皮書 | ✅ | `docs/WHITEPAPER.md` |

### 🟢 下一步（需 kk 決定）
**唯一待辦：GitHub 推送** — 現行 OAuth token 缺少 `workflow` scope，CLI 推送被擋。

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 7 個 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-10 22:00 ✅ CI 測試檔補全 + 全階段驗證完整
### 📦 產出
- 新增 `app/test_adapters.py` — 完整的 adapter 層測試（normalization、4 scheduler、3 service adapters、邊界條件）
- CI 現在能跑通：`bash -n install.sh` + `python3 -m compileall -q app` + `python3 test_adapters.py` 全部通過

### 🔍 驗證結果（本輪新增）
- `bash -n install.sh` → Syntax OK
- `python3 -m compileall -q app` → 全部 OK（含新增的 test_adapters.py）
- `python3 app/test_adapters.py` → ✅ All adapter tests passed
- 私人痕跡掃描 → **0 匹配**
- `/Users/` 硬編碼掃描 → **0 匹配**
- 服務啟動 (port 5299) → `curl /` 回 200
- `/api/state` 載入範例專案 ✅
- `/api/schedulers` 4 來源 ✅, `/api/services` 3 來源 ✅
- `/api/heartbeat` POST 寫入 `data/heartbeats.jsonl` ✅
- UI 品牌一致性：manifest / index.html / projects.json 均為 AJD 通用名稱 ✅

### 📋 完整階段狀態（更新版）
| 階段 | 狀態 | 驗證方式 |
|------|------|----------|
| Phase 0: 抽出引擎 | ✅ | `projects.example.json` 產出、私人痕跡 0 匹配 |
| Phase 1: Adapter 層 | ✅ | 4 scheduler + 3 service adapters，`/api/schedulers` `/api/services` 回傳正確 |
| Phase 2: 一鍵部署 | ✅ | `install.sh` + `AGENTS.md` + agent 偵測，語法檢查通過 |
| Phase 3: 文件 | ✅ | README.md/en/zh, USAGE.md, RELEASE.md, SETUP.md, WHITEPAPER.md |
| Phase 4: 打包與發布 | ✅ | Dockerfile, docker-compose.yml, GitHub Actions CI, LICENSE MIT，**乾淨目錄從零裝驗證通過**、**CI 測試通過** |
| Phase 5: 白皮書 | ✅ | `docs/WHITEPAPER.md` |

### 🟢 下一步（需 kk 決定）
**唯一待辦：GitHub 推送** — 現行 OAuth token 缺少 `workflow` scope，CLI 推送被擋。

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-10 14:15 ✅ 全階段完工 — 僅剩 GitHub 推送待 kk 決定

兩方案供選擇：
| 方案 | 說明 | 建議度 |
|------|------|--------|
| **A: 手動 Web UI 推送** | 進 github.com/hongchikuo-bot/ajd，把本地 6 個 commits 推上去（或 force-with-lease） | ⭐ 最快、無需改 token |
| **B: 重新生成 token** | GitHub Settings → Developer settings → Personal access tokens，加入 `workflow` scope，更新 `gh auth setup-git` | 較慢、但之後 CLI 可自動跑 CI |

推送後，**再從 GitHub Raw 驗證一次安裝**：
```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
# verify endpoints:
curl http://localhost:5080/api/state | jq '.registry.projects'
curl http://localhost:5080/api/schedulers | jq '.[].source'
curl http://localhost:5080/api/services | jq '.[].source'
```

### 🚫 卡住
- **GitHub push blocked by OAuth** — 缺 `workflow` scope
- **需 kk 選擇方案 A 或 B**，無其他技術阻擋

---

## 2026-10-10 13:02 ✅ Push Helper Script + GitHub Publish Plan
... (truncated)