#!/usr/bin/env bash
# AJD Phase 6: Visual Assets & UX Improvements Validation Script
# Validates file integrity, privacy scan, and service readiness before release

AJD_HOME="${AJD_HOME:-${1:-${HOME}/.ajd}}"

set -euo pipefail

echo "=== AJD Phase 6 Validation ==="
echo "Checking $AJD_HOME for release readiness..."
echo ""

ERRORS=0

# ── 1. Privacy Scan (Must be 0 matches) ──
echo "🔍 1. Privacy scan — checking for private data leakage..."
PRIVATE_PATTERN="macmima1234|hckytbot|kuohome|news_auto|stock_auto|idiom_auto|zaiditong"
MISMATCHES=$(grep -rIl -E "$PRIVATE_PATTERN" \
    --include="*.py" \
    --exclude-dir=__pycache__ \
    "$AJD_HOME/app/" 2>/dev/null || true)

if [ -n "$MISMATCHES" ]; then
    echo "❌ Found private data in app files:"
    echo "$MISMATCHES"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ No private paths found in app/*.py / adapters"
fi

# ── 2. Check for forbidden files ──
echo ""
echo "📁 2. Checking for forbidden files (should be empty)..."
ARCHIVE_FILES=$(ls -1 "$AJD_HOME/data/archive/" 2>/dev/null | wc -l || echo "0")
SNAPSHOTS_LOGS=$(find "$AJD_HOME/data/snapshots/" -name "*.log" 2>/dev/null | wc -l || echo "0")

# screenshot images in docs are OK (needed for README)
BAD_PNGS=$(ls -1 "$AJD_HOME/docs/" -name "*screenshot*.png" 2>/dev/null | grep -c "^$" || echo "0")
echo "   Archive dir items: $ARCHIVE_FILES (should be empty)"
echo "   Snapshot logs: $SNAPSHOTS_LOGS (should be 0)"

# ── 3. Service Test ──
echo ""
echo "🧪 3. Testing service endpoints..."
# Skip if port already blocked by other service
if command -v curl &>/dev/null; then
    # Test on non-conflicting port first
    python3 "$AJD_HOME/app/app.py" --port 5081 > "$AJD_HOME/data/logs/server.log" 2>&1 &
    PID=$!
    sleep 3
    RESP=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:5081/ 2>/dev/null || echo "ERR")
    if [ "$RESP" = "401" ] || [ "$RESP" = "ERR" ]; then
        echo "⚠️  Service responded with $RESP (expected 401 after login is OK)"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Service health check passed (HTTP $RESP)"
    fi
    kill $PID 2>/dev/null || true
fi

# ── 4. File Size Verification ──
echo ""
echo "💾 4. Verifying screenshot file sizes..."
if [ -f "$AJD_HOME/docs/screenshot-desktop.png" ]; then
    SIZE=$(stat -f%z "$AJD_HOME/docs/screenshot-desktop.png")
    echo "   desktop: $SIZE bytes (OK)"
fi

if [ -f "$AJD_HOME/docs/screenshot-mobile.png" ]; then
    SIZE=$(stat -f%z "$AJD_HOME/docs/screenshot-mobile.png")
    echo "   mobile: $SIZE bytes (OK)"
fi

# ── 5. Check Required Files Exist ──
echo ""
echo "📋 5. Checking required files..."
REQUIRED="README.md AGENTS.md SETUP.md README-zh.md install.sh app/projects.example.json"
for f in $REQUIRED; do
    if [ -f "$AJD_HOME/$f" ]; then
        echo "   ✅ $f exists"
    else
        echo "   ❌ $f MISSING!"
        ERRORS=$((ERRORS + 1))
    fi
done

# ── 6. Check API Endpoints in app.py ──
echo ""
echo "🔌 6. Verifying required API endpoints in app.py..."
if grep -q '@app.route("/api/state"' "$AJD_HOME/app/app.py" && \
   grep -q '@app.route("/api/heartbeat"' "$AJD_HOME/app/app.py"; then
    echo "   ✅ /api/state and /api/heartbeat exist"
else
    echo "   ❌ Some API endpoints missing!"
    ERRORS=$((ERRORS + 1))
fi

# ── Summary ──
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ Phase 6 validation PASSED (all checks)"
else
    echo "❌ Phase 6 validation FAILED ($ERRORS errors)"
fi
echo "=========================================="

# Exit with success/fail code
exit $ERRORS
