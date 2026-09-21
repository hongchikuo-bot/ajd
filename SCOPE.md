# AJD 專案範圍與計畫

> 這份是 kk 與總管（default profile）討論後的定案。AJD 開發者照這份做，不要重新討論。

## 一句話

把 kk 私人在用的「總管監控台」變成**任何人都能下載、一鍵部署**的開源專案。

## 為什麼值得開源

現在的 dashboard 是 **kk 個人版**：它讀 kk 的檔案、cron、服務。
AJD 要做的是**拆成「引擎」＋「設定」**，讓別人填自己的設定就能用。

## 為什麼要通用（kk 2026-09-21 追加）

「不是只有給 Hermes，是需要通用到其他的。」

所以 **AJD 不能假設使用者用 Hermes**：

| 面向 | 要支援 |
|---|---|
| 排程來源 | crontab、launchd、systemd timers、Hermes cron |
| 服務監控 | port 檢查、HTTP health、Docker 容器 |
| 心跳回報 | 純 HTTP POST（任何語言、任何框架都能打） |
| Agent 設定 | 使用者自己的 agent（Hermes / Claude / Cursor / 其他） |
| 完全沒有 agent | 手動設定範本 |

## 核心設計決定

### ① 一鍵部署 + 借使用者的 agent 來設定（kk 定案）

**不做外掛 API**（那要花好幾天，而且會變成另一個工程）。
改成：

1. `curl -fsSL <github raw>/install.sh | bash`
2. 裝好、起服務、面板可用
3. 安裝程式把 **`AGENTS.md`** 放進安裝目錄（跨 agent 的共通約定，很多 agent 會自己讀）
4. 同時**印出可直接複製的指令**，請使用者貼給自己的 agent
5. **明確告知**使用者：這一步會調用你自己電腦上的 agent，AJD 不上傳任何東西
6. 偵測使用者用哪種 agent（`~/.hermes/`、`CLAUDE.md`、`.cursor/`…）→ 給對應的講法
7. 沒有偵測到 agent → 指向手動範本

**理由**：會用這個功能的人一定已經有 agent，借他的 agent 最省雙方的時間。

### ② 安全寫進指令裡

給 agent 的指令必須明寫：
- **只讀取**專案路徑，**不要修改**使用者的任何專案檔案
- 全部在本機執行，不上傳

### ③ 設定一定要有驗證

`ajd --check`：路徑不存在、排程來源讀不到、port 打不通，都要講清楚哪裡錯。
（弱一點的 agent 可能填出壞設定，驗證是安全網。）

### ④ 心跳是通用化的關鍵

不要讓 AJD 去猜別人的系統怎麼運作，而是**讓別人用固定格式回報**：

```
curl -X POST http://localhost:5080/api/heartbeat -H 'Content-Type: application/json' \
     -d '{"job":"我的每日報表","status":"ok","note":"3.2MB"}'
```

只要回報格式固定，AJD 核心永遠不用改。

**為什麼心跳重要**：cron 說「我跑過了」不等於真的跑完。
最有價值的訊號是「**跑了但沒回報**」= 死在半路 —— 看檔案時間看不出來。

## 分階段計畫

### 階段 0：抽出引擎（0.5 天）
- 從 `~/root/dashboard/` 複製出乾淨引擎
- 把 `projects.json` → `projects.example.json`（範例專案，不含 kk 的資料）
- 移除所有個人痕跡（實測：app.py 0 處、app.js 1 處註解、harvest.py 2 處註解）
- 排除清單：`access_token.txt`、`ideas.jsonl`、`heartbeats.jsonl`、`heartbeat_map.json`、
  `projects.json`、`tunnel_url.txt`、`data/archive/`

### 階段 1：通用 adapter 層（2 天）
- 排程來源：`adapters/schedulers/`（crontab / launchd / systemd / hermes）
- 服務檢查：`adapters/services/`（port / http / docker）
- 每個 adapter 輸出**統一的標準格式**，核心只認這個格式

### 階段 2：一鍵部署 + agent 交接（1.5 天）
- `install.sh`（macOS + Linux）
- `AGENTS.md`（給使用者的 agent 讀的設定任務書）
- agent 偵測 + 對應的指令範本
- `SETUP.md`（手動路線）

### 階段 3：文件（1 天）
- 英文 README（主要）
- 中文 README
- 截圖 / 短 GIF
- 「為什麼要心跳」的說明（這是本專案的靈魂）

### 階段 4：打包與發布（1 天）
- Dockerfile + docker-compose
- GitHub Actions（lint + 測試）
- LICENSE（MIT）
- 潔淨新 repo（**不要沿用私人版的 git 歷史**）
- **在乾淨的目錄環境照文件從零裝一次**（最重要的一步）

### 階段 5：白皮書（1 天，選配但建議）
- 一份「多 agent 系統怎麼切」的文件（kk 那套 11 bot 架構的抽象版）
- 不含任何個人資料，只講設計原則

**合計約 6.5 個工作日**（不含白皮書）

## 成本

- GitHub 公開 repo：**0**
- GitHub Actions：公開 repo 免費
- Demo 站（可選）：免費方案 0；VPS 約 USD 5/月
- 網域（可選）：USD 10–15/年

## 現況

- 狀態：**等 kk 說「開始」**
- 已定案：名稱 AJD、MIT、GitHub raw 安裝、macOS+Linux、一鍵部署 + agent 交接、通用 adapter
- 私人版仍在 `~/root/dashboard/` 正常運作（**不可動**）
