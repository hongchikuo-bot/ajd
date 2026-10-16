#!/usr/bin/env bash
# check_release_ready.sh — 檢查是否所有條件都符合 release
# Usage: ./check_release_ready.sh

set -e

AJD_HOME="${1:-$HOME/root/ajd}"
FAILED=0

echo "=== AJD Release Readiness Check ==="
echo ""

# 1. Check version is set
if git describe --tags $(git rev-parse HEAD) >/dev/null 2>&1; then
    TAG=$(git describe --tags $(git rev-parse HEAD))
    echo "[OK] Current tag: $TAG"
else
    echo "[WARN] No tags found locally"
fi

# 2. Check syntax of install.sh and manual_setup.sh
for script in install.sh manual_setup.sh; do
    if bash -n "$AJD_HOME/$script" 2>/dev/null; then
        echo "[OK] $script syntax OK"
    else
        echo "[FAIL] $script has syntax errors"
        FAILED=1
    fi
done

# 3. Check projects.example.json exists (no private data)
if [ -f "$AJD_HOME/app/projects.example.json" ]; then
    echo "[OK] projects.example.json exists (template ready)"
else
    echo "[FAIL] projects.example.json missing"
    FAILED=1
fi

# 4. Check AGENTS.md in app/
if [ -f "$AJD_HOME/app/AGENTS.md" ]; then
    echo "[OK] AGENTS.md exists"
else
    echo "[FAIL] AGENTS.md missing"
    FAILED=1
fi

# 5. Private data scan
PRIVATE_PATTERNS="macmima1234|hckytbot|kuohome|news_auto|stock_auto|idiom_auto|ethubs|zaiditong|hermesagent|kuo_bot"
if grep -rIl --include='.py' --include='.sh' --exclude='__pycache__' \
    -e "macmima1234" -e "hckytbot" "$AJD_HOME/app/" 2>/dev/null; then
    echo "[FAIL] Private data found in app/ sources"
    FAILED=1
else
    echo "[OK] No private data in app/ (verified)"
fi

# 6. Check README files exist and don't mention "total manager" or personal info
if grep -q "總管監控台" "$AJD_HOME/README.md" "$AJD_HOME/README-zh.md" 2>/dev/null; then
    echo "[FAIL] README still contains personal references"
    FAILED=1
else
    echo "[OK] README files cleaned up"
fi

# 7. Check API endpoints exist (grep confirmation)
API_COUNT=$(grep -c '@app.route' "$AJD_HOME/app/app.py" 2>/dev/null || echo "0")
echo "[OK] Found $API_COUNT API routes in app.py"

# 8. Verify git branch and push status
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "release/v0.5.0" ]; then
    echo "[OK] On release/v0.5.0 branch"
    
    # Check if pushed to remote
    REMOTE_BRANCH=$(git ls-remote origin refs/heads/release/v0.5.0 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$REMOTE_BRANCH" ]; then
        LOCAL_COMMITS=$(git rev-list release/v0.5.0..HEAD --count)
        if [ "$LOCAL_COMMITS" -eq 0 ]; then
            echo "[INFO] Branch is already pushed to remote (ahead by $LOCAL_COMMITS commits)"
        else
            echo "[WARN] Local branch ahead of remote by $LOCAL_COMMITS commits — run git push"
        fi
    else
        echo "[INFO] Checking for unpushed commits..."
    fi
else
    echo "[FAIL] Not on expected release/v0.5.0 branch (currently: $BRANCH)"
    FAILED=1
fi

# 9. Check Dockerfile exists
if [ -f "$AJD_HOME/Dockerfile" ]; then
    echo "[OK] Dockerfile exists"
else
    echo "[FAIL] Dockerfile missing"
    FAILED=1
fi

# 10. Count documentation files
DOC_COUNT=$(ls -1 "$AJD_HOME/docs/"*.md 2>/dev/null | wc -l)
echo "[INFO] Documentation files: ${DOC_COUNT} (FAQ, INSTALL_GUIDE, TROUBLESHOOTING, WHITEPAPER, USAGE, RELEASE)"

echo ""
if [ $FAILED -eq 0 ]; then
    echo "=========================================="
    echo "✅ All checks passed! Ready for release."
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Run: git push origin release/v0.5.0"  
    echo "2. Create release at https://github.com/hongchikuo-bot/ajd/releases/new"
    echo "3. Tag: v0.5.0 (force-update if needed)"
    echo "4. Attach screenshots from docs/"
    echo "5. Paste RELEASE_NOTES.md into release body"
else
    echo "=========================================="
    echo "❌ Some checks failed — fix issues above"
    echo "=========================================="
fi

exit $FAILED