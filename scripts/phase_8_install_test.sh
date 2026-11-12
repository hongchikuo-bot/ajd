#!/bin/bash
# Phase 8: Installation Test Script
# Tests that AJD is properly installed and functioning

set -euo pipefail

AJD_HOME="${AJD_HOME:-$HOME/root/ajd}"
APP_DIR="$AJD_HOME/app"
SCRIPTS_DIR="$AJD_HOME/scripts"

echo "=========================================="
echo "AJD Installation Test Suite"
echo "=========================================="
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((pass_count++))
}

test_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((fail_count++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Test 1: Check required directories exist
echo "=== Checking directory structure ==="
if [[ -d "$AJD_HOME" ]]; then
    test_pass "AJD home directory exists: $AJD_HOME"
else
    test_fail "AJD home directory missing: $AJD_HOME"
fi

if [[ -d "$APP_DIR" ]]; then
    test_pass "App directory exists: $APP_DIR"
else
    test_fail "App directory missing: $APP_DIR"
fi

# Test 2: Check Python app can be compiled
echo ""
echo "=== Checking Python syntax ==="
if [[ -f "$APP_DIR/app.py" ]]; then
    if python3 -m py_compile "$APP_DIR/app.py" 2>/dev/null; then
        test_pass "app.py has valid Python syntax"
    else
        test_fail "app.py has Python syntax errors"
    fi
else
    test_warn "app.py not found (may be using alternative app structure)"
fi

# Test 3: Check shell scripts have valid syntax
echo ""
echo "=== Checking shell script syntax ==="
for script in install.sh manual_setup.sh; do
    if [[ -f "$SCRIPTS_DIR/$script" ]]; then
        if bash -n "$SCRIPTS_DIR/$script" 2>/dev/null; then
            test_pass "$script has valid bash syntax"
        else
            test_fail "$script has bash syntax errors"
        fi
    else
        test_warn "$script not found (may be optional)"
    fi
done

# Test 4: Check JSON files are valid
echo ""
echo "=== Checking JSON file validity ==="
json_files=(
    "projects.example.json"
    "config.example.json"
)

for json_file in "${json_files[@]}"; do
    if [[ -f "$AJD_HOME/$json_file" ]]; then
        if python3 -c "import json; json.load(open('$AJD_HOME/$json_file'))" 2>/dev/null; then
            test_pass "$json_file is valid JSON"
        else
            test_fail "$json_file has invalid JSON syntax"
        fi
    else
        test_warn "$json_file not found (may be optional)"
    fi
done

# Test 5: Check API endpoints are defined
echo ""
echo "=== Checking API endpoints ==="
if [[ -f "$APP_DIR/app.py" ]]; then
    api_count=$(grep -c '@app.route("/api/' "$APP_DIR/app.py" || echo 0)
    if [[ $api_count -gt 0 ]]; then
        test_pass "Found $api_count API endpoint definitions in app.py"
    else
        test_fail "No API endpoints found in app.py"
    fi
else
    test_warn "Cannot check API endpoints (app.py not found)"
fi

# Test 6: Check AGENTS.md exists
echo ""
echo "=== Checking agent integration files ==="
if [[ -f "$AJD_HOME/AGENTS.md" ]]; then
    test_pass "AGENTS.md exists for agent integration"
    if grep -q "hermes" "$AJD_HOME/AGENTS.md" 2>/dev/null; then
        test_pass "AGENTS.md contains Hermes-specific instructions"
    else
        test_warn "AGENTS.md may need Hermes-specific content"
    fi
else
    test_fail "AGENTS.md not found (required for agent integration)"
fi

# Test 7: Check heartbeat endpoint handler exists
echo ""
echo "=== Checking health check capabilities ==="
if [[ -f "$APP_DIR/app.py" ]]; then
    if grep -q '@app.route("/api/heartbeat"' "$APP_DIR/app.py"; then
        test_pass "Heartbeat API endpoint is defined"
    else
        test_fail "Heartbeat API endpoint not found"
    fi
    
    if grep -q 'path == "/api/heartbeat"' "$APP_DIR/app.py" || grep -q '"heartbeat"' "$APP_DIR/app.py"; then
        test_pass "Heartbeat handling logic present in app"
    else
        test_warn "May need to add heartbeat handler logic"
    fi
fi

# Test 8: Check install.sh is executable (or can be made executable)
echo ""
echo "=== Checking install script ==="
if [[ -f "$SCRIPTS_DIR/install.sh" ]]; then
    if [[ -x "$SCRIPTS_DIR/install.sh" ]] || bash -n "$SCRIPTS_DIR/install.sh" 2>/dev/null; then
        test_pass "install.sh exists and is valid (executable: $([[ -x \"$SCRIPTS_DIR/install.sh\" ]] && echo 'yes' || echo 'no'))"
    else
        test_fail "install.sh has issues"
    fi
else
    test_fail "install.sh not found (required for one-click install)"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Passed:  ${GREEN}$pass_count${NC}"
echo -e "Failed:  ${RED}$fail_count${NC}"
echo -e "Warnings: $((total_tests - pass_count - fail_count))"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo "AJD appears to be properly installed."
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
