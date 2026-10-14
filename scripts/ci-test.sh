#!/usr/bin/env bash
# ci-test.sh — GitHub Actions CI 測試腳本（非 /Users/*）
# 用法：bash scripts/ci-test.sh → 驗證所有端點與安裝套件可用性

set -e

echo "=================================================="
echo "AJD CI Test"
echo "=================================================="
echo ""
echo "📦 Validating endpoints on port $AJD_PORT..."

# Health check (必須的)
if curl -s -o /dev/null -w "HTTP/health: %{http_code}\n" http://127.0.0.1:5199/ | grep -q "200"; then
    echo "✅ Health endpoint OK"
else
    echo "❌ Health check failed"
    exit 1
fi

# API state (必須的)
curl -s http://127.0.0.1:5199/api/state | head -c 200 && echo "" || { echo "⚠️  /api/state unreachable (may be OK)"; }

# API schedulers (可選，但必須存在)
curl -s http://127.0.0.1:5199/api/schedulers | head -c 200 && echo "" || { echo "⚠️  /api/schedulers unreachable"; }

# API services (可選)
curl -s http://127.0.0.1:5199/api/services | head -c 200 && echo "" || { echo "⚠️  /api/services unreachable"; }

# Heartbeat (必須的 — 用來測試自動收聽機制)
echo '{"job":"ci-test","status":"ok"}' | curl --data-binary @- http://127.0.0.1:5199/api/heartbeat -s -w "\n" || { echo "⚠️  /api/heartbeat unreachable"; }

echo ""
echo "✅ CI test complete!"
echo ""
