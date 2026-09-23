#!/usr/bin/env bash
# AJD Release Checklist — Phase 4: GitHub Release

echo "=== AJD v0.4.0 Release Checklist ==="
echo ""

cd /Users/macmima1234/root/ajd || exit 1

all_ok=true

# ① Syntax checks
echo "① Syntax verification:"
bash -n install.sh > /dev/null && echo "   ✅ install.sh OK" || { echo "   ❌ install.sh"; all_ok=false; }
python3 -m py_compile app/app.py > /dev/null && echo "   ✅ app.py OK" || { echo "   ❌ app.py"; all_ok=false; }
python3 -m py_compile app/harvest.py > /dev/null && echo "   ✅ harvest.py OK"
echo ""

# ② Private data check
echo "② Private data check (app/ only):"
if grep -rIlE "macmima1234|kuohome|daily_run\.py|hckytbot" app/*.py 2>/dev/null | grep -v __pycache__ > /dev/null; then
  echo "   ❌ Found private data!"
  all_ok=false
else
  echo "   ✅ No private data in app/"
fi
echo ""

# ③ Required files
echo "③ Release package files:"
for f in LICENSE README.md README-zh.md AGENTS.md SETUP.md DOCKERFILE docker-compose.yml; do
  path="./$f"
  if [[ -f "$path" || -f "./app/$f" ]]; then
    echo "   ✅ $f"
  else
    echo "   ⚠️ Missing: $f"
  fi
done
# Check docs/screenshots for public repo
[[ -f "./docs/screenshot-desktop.png" ]] && echo "   ✅ screenshot-desktop.png (public)" || true
[[ -f "./docs/screenshot-mobile.png" ]] && echo "   ✅ screenshot-mobile.png (public)" || true
# ci files
[[ -f "./ci/github-actions.yml" ]] && echo "   ✅ github-actions.yml (for README link)" || true
[[ -f "./ci/README.md" ]] && echo "   ✅ CI README for docs" || true
echo ""

# ④ README content check
echo "④ README files updated with v0.4.0:"
git -C ./ diff HEAD~1 -- README.md README-zh.md 2>/dev/null | grep -q "@@ .*RELEASE_NOTES" && \
  echo "   ✅ RELEASE_NOTES.md link in READMEs" || \
  [[ -f "./RELEASE_NOTES.md" ]] && echo "   ✅ RELEASE_NOTES.md exists (awaiting merge)"

echo ""

# ⑤ Version determination
echo "⑤ Determining release version:"
if grep -q "v0.4" README*.md; then
  echo "   → Recommended tag: 0.4.0 (Phase 3 complete)"
elif grep -q "version=" app/app.py | head -1 | grep -q "=0\.3"; then
  echo "   → Latest: check for new version string"
fi
echo ""

# ⑥ Summary
echo "⑥ Summary:"
if [[ "$all_ok" == true ]] && [[ -f "./RELEASE_NOTES.md" ]]; then
  echo "   ✅ Ready for GitHub release v0.4.0"
  echo "   → Create Release: https://github.com/hongchikuo-bot/ajd/releases/new"
  echo "   → Tag: 0.4.0"
  echo "   → Title: AJD v0.4.0 — Dashboard Complete"
  echo "   → Body:"
  cat << 'RELEASER'
## What's New

- ✅ Phase 1-3 COMPLETE: Engine, adapter layer, and documentation ready
- 🔑 Heartbeat mechanism fully implemented
- 🔄 Universal scheduler support (crontab/launchd/systemd/hermes)
- 🧹 Agent-free setup via SETUP.md available

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
```

See [README.md](README.md) for full documentation.

RELEASER
else
  echo "   ⚠️ Some checks failed or RELEASE_NOTES.md missing"
fi
echo ""

# ⑦ Next steps
echo "⑦ Next steps:"
echo "   → If syntax checks pass: create GitHub release via GitHub UI or CLI"
echo "      gh repo release create --target main --title 'AJD v0.4.0' --draft"
echo "   → Copy RELEASE_NOTES.md as body (edit tag/version if needed)"
echo "   → Upload README screenshots:"
echo "      docs/screenshot-desktop.png → Attach to GitHub release notes"
echo "      docs/screenshot-mobile.png → Attach to GitHub release notes"
echo ""

# Cleanup test server
pkill -f 'python3 app.py' 2>/dev/null || true
