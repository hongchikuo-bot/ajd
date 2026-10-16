#!/usr/bin/env bash
# AJD Verify Installation Files Script
# 驗證 install.sh 所需的所有檔案都能被下載或複製

set -euo pipefail

GITHUB_RAW="${GITHUB_RAW:-https://raw.githubusercontent.com/hongchikuo-bot/ajd/main}"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "=== AJD Installation Files Verification ==="
echo ""

TOTAL=0
PASSED=0
FAILED=0

check_file() {
  local desc="$1"
  local check_cmd="$2"
  
  TOTAL=$((TOTAL + 1))
  echo "[Check $TOTAL] $desc..."
  
  if eval "$check_cmd"; then
    PASSED=$((PASSED + 1))
    echo "   ✅ Verified"
  else
    FAILED=$((FAILED + 1))
    echo "   ❌ Failed"
  fi
}

# Check local exists (used for static/assets)
check_file "projects.example.json (local template)" \
  "test -f app/projects.example.json && head -3 app/projects.example.json"

check_file "AGENTS.md (local copy)" \
  "test -f AGENTS.md && head -3 AGENTS.md"

check_file "SETUP.md (local copy)" \
  "test -f SETUP.md && head -2 SETUP.md"

check_file "README.md (local copy)" \
  "test -f README.md && head -3 README.md"

echo ""
echo "=== GitHub Raw URLs Check ==="

TOTAL=$((TOTAL + 1))
echo "[Check $TOTAL] Testing GitHub raw access for projects.example.json..."

if curl -sL "${GITHUB_RAW}/app/projects.example.json" -o /dev/null; then
  PASSED=$((PASSED + 1))
  echo "   ✅ GitHub raw accessible for projects.example.json"
else
  FAILED=$((FAILED + 1))
  echo "   ❌ Cannot access GitHub raw URL (HTTP error or timeout)"
fi

TOTAL=$((TOTAL + 1))
echo "[Check $TOTAL] Testing README.md download with content check..."

if curl -sL "${GITHUB_RAW}/README.md" -o /tmp/readme_check.txt && \
   grep -q "AJD" /tmp/readme_check.txt; then
  PASSED=$((PASSED + 1))
  echo "   ✅ README.md downloadable with content"
else
  FAILED=$((FAILED + 1))
  echo "   ❌ README.md download failed or empty content"
fi

TOTAL=$((TOTAL + 1))
echo "[Check $TOTAL] Testing AGENTS.md download..."

if curl -sL "${GITHUB_RAW}/AGENTS.md" -o /tmp/agents_check.txt; then
  PASSED=$((PASSED + 1))
  echo "   ✅ AGENTS.md downloadable"
else
  FAILED=$((FAILED + 1))
  echo "   ❌ AGENTS.md download failed"
fi

TOTAL=$((TOTAL + 1))
echo "[Check $TOTAL] Testing SETUP.md download..."

if curl -sL "${GITHUB_RAW}/SETUP.md" -o /tmp/setup_check.txt; then
  PASSED=$((PASSED + 1))
  echo "   ✅ SETUP.md downloadable"
else
  FAILED=$((FAILED + 1))
  echo "   ❌ SETUP.md download failed"
fi

echo ""
echo "=== Summary ==="
echo "Total checks: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ "$FAILED" -eq 0 ]; then
  echo ""
  echo "✅ All installation files are ready for deployment!"
else
  echo ""
  echo "⚠️ Some checks failed. Please review the errors above."
  exit 1
fi
