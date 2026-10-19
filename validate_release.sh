#!/usr/bin/env bash
# AJD v0.5.0 Release Validation Script
# Runs before GitHub release to verify all Phase 1-6 deliverables are ready.

set -euo pipefail

AJD_HOME="${1:-$(dirname "$0")}"

echo "=== AJD v0.5.0 Pre-Release Validation ==="
echo "Checking: $AJD_HOME\n"

errors=0

# Test 1: File presence
echo "[1/7] Checking required files..."
for f in install.sh AGENTS.md SETUP.md LICENSE Dockerfile docker-compose.yml CHANGELOG.md README.md; do
    if [ -f "$AJD_HOME/$f" ]; then
        echo "  ✅ $f exists"
        continue
    fi
    echo "  ❌ $f MISSING"
    ((errors++))
done

# Test 2: App core files
for f in app/app.py app/harvest.py app/projects.example.json; do
    if [ -f "$AJD_HOME/$f" ]; then
        echo "  ✅ $f exists"
    else
        echo "  ❌ $f MISSING"
        ((errors++))
    fi
done

# Test 3: Syntax checks
echo ""
echo "[2/7] Running syntax validation..."
bash -n "$AJD_HOME/install.sh" 2>/dev/null && echo "  ✅ install.sh (bash -n)" || { echo "  ❌ install.sh syntax error"; ((errors++)); }

python3 -m py_compile "$AJD_HOME/app/app.py" 2>/dev/null && echo "  ✅ app/app.py compiled" || { echo "  ❌ app.py compile error"; ((errors++)); }

# Test 4: API endpoint exists
echo ""
echo "[3/7] Verifying /api/state endpoint..."
if grep -q '"/api/state"' "$AJD_HOME/app/app.py" 2>/dev/null; then
    echo "  ✅ /api/state endpoint found in app.py"
else
    echo "  ❌ /api/state NOT FOUND in app.py"
    ((errors++))
fi

# Test 5: Private trace scan
echo ""
echo "[4/7] Scanning for private data traces..."
traces=$(grep -rIl -E 'macmima1234|hckytbot|kuohome' \
          --include='*.py' --include='*.sh' --include='*.json' \
          "$AJD_HOME/app" "$AJD_HOME/install.sh" 2>/dev/null | grep -v __pycache__ || true)

if [ -z "$traces" ]; then
    echo "  ✅ No private traces found in engine files"
else
    echo "  ⚠️  Found potential traces (check manually):"
    echo "$traces" | head -5
fi

# Test 6: No /Users/ paths leaked in public artifacts
echo ""
echo "[5/7] Checking for /Users/ paths..."
leaked=$(grep -rIl '/Users/macmima1234' \
          --include='*.py' --include='*.sh' --include='*.json' \
          "$AJD_HOME/app" "$AJD_HOME/install.sh" 2>/dev/null | grep -v __pycache__ || true)

if [ -z "$leaked" ]; then
    echo "  ✅ No /Users/ paths in engine files"
else
    echo "  ⚠️  Found /Users/ references (manual review needed):"
    echo "$leaked" | head -3
fi

# Test 7: Documentation sanity check
echo ""
echo "[6/7] Documentation check..."
if [ -s "$AJD_HOME/AGENTS.md" ] && grep -q '/api/state' "$AJD_HOME/AGENTS.md"; then
    echo "  ✅ AGENTS.md is valid and references correct endpoints"
else
    echo "  ❌ AGENTS.md missing or has wrong endpoint ref"
    ((errors++))
fi

# Test 8: ChangeLog exists and mentions v0.5.0
echo ""
echo "[7/7] ChangeLog validation..."
if [ -f "$AJD_HOME/CHANGELOG.md" ] && grep -q '## \[0.5.0\]' "$AJD_HOME/CHANGELOG.md"; then
    echo "  ✅ CHANGELOG.md updated for v0.5.0"
else
    echo "  ⚠️  CHANGELOG.md may need update"
fi

echo ""
echo "=== Summary ==="
if [ $errors -eq 0 ]; then
    echo "✅ Phase 2 validation complete - ready to push to release/v0.5.0"
    exit 0
else
    echo "⚠️  Validation found $errors error(s) - review before pushing"
    exit 1
fi
