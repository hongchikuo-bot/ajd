#!/usr/bin/env bash
# create_release_package.sh — Create tar.gz release package for AJD
# Usage: ./create_release_package.sh [version]
# Output: ajd-<version>.tar.gz

set -euo pipefail

VERSION="${1:-v0.5.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AJD_ROOT="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="/tmp/ajd-release-$VERSION"
PACKAGE_NAME="ajd-$VERSION.tar.gz"

echo "=== Creating AJD Release Package: $VERSION ==="
echo ""

# Clean previous
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy all release files
echo "Copying release files..."

# Core files
cp "$AJD_ROOT/install.sh" "$RELEASE_DIR/"
cp "$AJD_ROOT/AGENTS.md" "$RELEASE_DIR/"
cp "$AJD_ROOT/SETUP.md" "$RELEASE_DIR/"
cp "$AJD_ROOT/README.md" "$RELEASE_DIR/"
cp "$AJD_ROOT/README-zh.md" "$RELEASE_DIR/"
cp "$AJD_ROOT/LICENSE" "$RELEASE_DIR/"
cp "$AJD_ROOT/Dockerfile" "$RELEASE_DIR/"
cp "$AJD_ROOT/docker-compose.yml" "$RELEASE_DIR/"
cp "$AJD_ROOT/RELEASE_NOTES.md" "$RELEASE_DIR/" 2>/dev/null || true
cp "$AJD_ROOT/WHITEPAPER.md" "$RELEASE_DIR/" 2>/dev/null || true

# App directory
mkdir -p "$RELEASE_DIR/app"
cp -r "$AJD_ROOT/app/app.py" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/harvest.py" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/test_adapters.py" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/requirements.txt" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/projects.example.json" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/adapters" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/static" "$RELEASE_DIR/app/"
cp -r "$AJD_ROOT/app/templates" "$RELEASE_DIR/app/"

# Scripts
mkdir -p "$RELEASE_DIR/scripts"
cp "$AJD_ROOT/scripts/validate.sh" "$RELEASE_DIR/scripts/"
cp "$AJD_ROOT/scripts/push_helper.sh" "$RELEASE_DIR/scripts/"
cp "$AJD_ROOT/scripts/demo_flow.sh" "$RELEASE_DIR/scripts/"
cp "$AJD_ROOT/release_checklist.sh" "$RELEASE_DIR/"

# Docs (screenshots for README)
mkdir -p "$RELEASE_DIR/docs"
cp "$AJD_ROOT/docs/screenshot-desktop.png" "$RELEASE_DIR/docs/"
cp "$AJD_ROOT/docs/screenshot-mobile.png" "$RELEASE_DIR/docs/"

# CI files
mkdir -p "$RELEASE_DIR/.github/workflows"
cp "$AJD_ROOT/.github/workflows/ci.yml" "$RELEASE_DIR/.github/workflows/"

# Remove any unwanted files
find "$RELEASE_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$RELEASE_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$RELEASE_DIR" -name ".DS_Store" -delete 2>/dev/null || true
find "$RELEASE_DIR" -name "heartbeats.jsonl" -delete 2>/dev/null || true
find "$RELEASE_DIR" -name "ideas.jsonl" -delete 2>/dev/null || true
find "$RELEASE_DIR" -name "projects.json" -delete 2>/dev/null || true

# Create tar.gz
echo ""
echo "Creating tar.gz package..."
cd "$(dirname "$RELEASE_DIR")"
tar -czf "$PACKAGE_NAME" "$(basename "$RELEASE_DIR")"

# Move to project root
mv "$PACKAGE_NAME" "$AJD_ROOT/"

# Cleanup
rm -rf "$RELEASE_DIR"

echo ""
echo "✅ Release package created: $AJD_ROOT/$PACKAGE_NAME"
echo ""
echo "Package contents:"
tar -tzf "$AJD_ROOT/$PACKAGE_NAME" | head -50
echo ""
echo "Size: $(du -h "$AJD_ROOT/$PACKAGE_NAME" | cut -f1)"
echo ""
echo "Usage:"
echo "  tar -xzf $PACKAGE_NAME"
echo "  cd ajd-$VERSION"
echo "  ./install.sh"