#!/usr/bin/env bash
# AJD Manual Setup Script
# For users without an AI agent - creates directories and template files

set -euo pipefail

AJD_HOME="${AJD_HOME:-${HOME}/.ajd}"

echo "=== AJD Manual Setup ==="
echo "Install directory: $AJD_HOME"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$AJD_HOME/data/archive"
mkdir -p "$AJD_HOME/data/snapshots"
mkdir -p "$AJD_HOME/scripts"

# Copy projects.example.json to projects.json if not exists
if [ -f "$AJD_HOME/projects.example.json" ] && [ ! -f "$AJD_HOME/projects.json" ]; then
    cp "$AJD_HOME/projects.example.json" "$AJD_HOME/projects.json"
    echo "Created projects.json from template"
elif [ ! -f "$AJD_HOME/projects.example.json" ]; then
    echo "⚠️  projects.example.json not found in $AJD_HOME"
    echo "   Please run install.sh first, or download it from GitHub:"
    echo "   curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/app/projects.example.json -o $AJD_HOME/projects.example.json"
fi

echo ""
echo "Setup complete!"
echo "Next steps:"
echo "1. Edit $AJD_HOME/projects.json with your projects"
echo "2. Start the dashboard: AJD_HOME=$AJD_HOME python3 $AJD_HOME/app/app.py"
echo "3. Open http://localhost:5080/ in your browser"