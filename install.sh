#!/usr/bin/env bash
set -euo pipefail

# AJD — AI Agents Job Dashboard
# One-line install: curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash

# 0. 基本檢查
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ 找不到 python3，請先安裝 Python 3.8+"
  exit 1
fi

# 1. 安裝目錄
AJD_HOME="${AJD_HOME:-$HOME/root/ajd}"
mkdir -p "$AJD_HOME"
cd "$AJD_HOME"

# 2. 虛擬環境與依賴
if [ ! -d "venv" ]; then
  python3 -m venv venv
fi
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet flask

# 3. 專案設定檔（第一次跑才複製）
if [ ! -f "projects.json" ]; then
  if [ -f "app/projects.example.json" ]; then
    cp app/projects.example.json projects.json
    echo "✅ 已建立 projects.json（請自行編輯填入你的專案路徑）"
  else
    echo "❌ 找不到 app/projects.example.json"
    ls app/
    exit 1
  fi
fi

# 4. 資料目錄
mkdir -p data/snapshots

# 5. 啟動服務
DASH_PORT="${DASH_PORT:-5080}"
export AJD_HOME
export AJD_PORT="$DASH_PORT"

# 啟動語法：python 檔名是 app/app.py（不在 venv 內，要指定全稱）
nohup python3 "$AJD_HOME/app/app.py" > "$AJD_HOME/data/app.log" 2>&1 &
DASH_PID=$!

# 等待啟動
sleep 5

# 6. 健康檢查（用實際存在的端點 /）
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$DASH_PORT/" || true)
if [ "$HTTP_CODE" != "200" ]; then
  echo "❌ 服務啟動失敗（HTTP $HTTP_CODE）"
  echo "--- 最近 50 行 log ---"
  tail -50 data/app.log 2>/dev/null || true
  kill "$DASH_PID" 2>/dev/null || true
  exit 1
fi

echo "✅ AJD 安裝完成！Dashboard 運行在 http://127.0.0.1:$DASH_PORT/"
echo ""
echo "=== 下一步：把 AGENTS.md 給你的 AI agent ==="
echo "這一步會調用你自己的 agent（Hermes / Claude / Cursor / Windsurf...）"
echo ""
echo "請把以下內容貼給你的 agent："
echo "----------------------------------------"
cat <<'EOF'
# 請讀取並遵循 ~/root/ajd/app/AGENTS.md
# 內含：如何配置 ai-jobs.dashboard.url、registryPath、allowLocalOnly
# 驗證：curl http://localhost:5080/api/state
EOF
echo "----------------------------------------"
echo ""
echo "💡 記得先編輯 projects.json 填入你自己的專案路徑"
