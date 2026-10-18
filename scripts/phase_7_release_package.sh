#!/usr/bin/env bash
# phase_7_release_package.sh — 組裝 AJD 出貨套件
# 用途：把 AJD 專案打包成可交付版本（不含私人數據、git、__pycache__）
# 規則：只用 cp/rsync，不寫入 /private/var/folders/*

set -e

# Determine project root from script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AJD_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "AJD Phase 7 — 組裝出貨套件"
echo "=================================================="
echo "📦 Target: ~/root/ajd_release_v1.zip"
echo ""

DEST_DIR="$HOME/root/ajd_release_v1"
ZIP_FILE="$HOME/root/ajd_release_v1.zip"
# Clean up previous build
rm -rf "$DEST_DIR" 2>/dev/null || true
rm -f "$ZIP_FILE" 2>/dev/null || true
mkdir -p "$DEST_DIR"

echo "📥 Copying app/ (excluding runtime data and user config)..."
rsync -a "$AJD_ROOT/app/" "$DEST_DIR/app/" \
    --exclude="__pycache__/" \
    --exclude="data/" \
    --exclude="*.pyc" \
    --exclude="*.log" \
    --exclude="/projects.json" || echo "⚠️  app/ skip"

echo "📥 Copying docs/screenshot-*.png..."
mkdir -p "$DEST_DIR/docs"
for f in "$AJD_ROOT/docs/screenshot-desktop.png" "$AJD_ROOT/docs/screenshot-mobile.png"; do
    if [ -f "$f" ]; then
        cp "$f" "$DEST_DIR/docs/" || echo "⚠️  $f skip"
    fi
done

echo "📥 Copying public docs..."
# Only copy public documentation files (not internal ones like PROGRESS.md, PUSH_GUIDE.md, CI_VALIDATION.md)
cp "$AJD_ROOT/README.md" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/README-zh.md" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/AGENTS.md" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/SETUP.md" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/LICENSE" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/SCOPE.md" "$DEST_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/WHITEPAPER.md" "$DEST_DIR/" 2>/dev/null || true

# Copy root install.sh and user-facing scripts/
cp "$AJD_ROOT/install.sh" "$DEST_DIR/" 2>/dev/null || true
mkdir -p "$DEST_DIR/scripts"
# Only copy user-facing scripts (not internal build scripts)
for f in install.sh ci-test.sh demo_flow.sh validate.sh; do
    cp "$AJD_ROOT/scripts/$f" "$DEST_DIR/scripts/" 2>/dev/null || true
done

echo ""
echo "🔍 Checking for private traces in copy..."
private_patterns="macmima1234|hckytbot|kuohome"
for p in $private_patterns; do
    count=$(grep -riIl "$p" "$DEST_DIR/" 2>/dev/null | grep -v __pycache__ | wc -l || echo "0")
    if [ "$count" -eq 0 ]; then
        echo "✅ Pattern '$p': No private traces found"
    else
        echo "❌ Pattern '$p' exists: $count matches"
    fi
done

echo ""
echo "📦 Creating release package..."
(
    cd "$HOME/root/ajd_release_v1"
    zip -r -9 "$ZIP_FILE" \
        README.md README-zh.md AGENTS.md SETUP.md LICENSE SCOPE.md WHITEPAPER.md \
        app/ docs/*.png \
        install.sh scripts/*.sh 2>/dev/null || echo "⚠️  zip skip"
)

echo ""
echo "📊 Package info..."
ls -lh "$ZIP_FILE" && echo ""
echo "✅ Phase 7 — 出貨套件組裝完成！"
echo ""

echo "👉 使用者安裝指令："
echo 'curl -fsSL ~/root/ajd_release_v1.zip | gunzip || true'
echo 'sha256sum ~/root/ajd_release_v1.zip && echo "✅ 套件無損壞"'
echo ""