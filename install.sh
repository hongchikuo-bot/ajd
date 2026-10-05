#!/usr/bin/env bash
# AJD · AI agents job dashboard Installation Script
# Install one-command deployment: curl -fsSL <repo>/install.sh | bash
#
# Features:
#   - Universal adapter layer (crontab/launchd/systemd/hermes → unified heartbeat)
#   - No external API, uses user's own agent for setup
#   - Generic templates, no private data leakage
#   - Works on macOS/Linux (tested on macOS 26.6.2)

set -euo pipefail

# Support both AJD_HOME env var and first positional arg
AJD_HOME="${AJD_HOME:-${1:-${HOME}/.ajd}}"
PORT="${PORT:-5080}"
NO_AGENT="${NO_AGENT:-false}"

# GitHub raw base URL (set when installing from GitHub)
GITHUB_RAW="${GITHUB_RAW:-https://raw.githubusercontent.com/hongchikuo-bot/ajd/main}"

echo "=== AJD Installation ===" 
echo "Install directory: $AJD_HOME"
echo "Service port: $PORT"
echo ""

# Create directories
mkdir -p "$AJD_HOME/app" "$AJD_HOME/data/logs" "$AJD_HOME/data/snapshots"

# Download engine files from GitHub
download() {
  local url="$1"
  local dest="$2"
  curl -fsSL "$url" -o "$dest" || { echo "❌ Failed to download $url"; exit 1; }
}

echo "📥 Downloading AJD engine files from GitHub..."
download "$GITHUB_RAW/app/app.py" "$AJD_HOME/app/app.py"
download "$GITHUB_RAW/app/harvest.py" "$AJD_HOME/app/harvest.py"
download "$GITHUB_RAW/app/test_adapters.py" "$AJD_HOME/app/test_adapters.py"
download "$GITHUB_RAW/app/requirements.txt" "$AJD_HOME/app/requirements.txt"

# Download adapters directory (individual files)
mkdir -p "$AJD_HOME/app/adapters/schedulers"
mkdir -p "$AJD_HOME/app/adapters/services"
download "$GITHUB_RAW/app/adapters/__init__.py" "$AJD_HOME/app/adapters/__init__.py"
download "$GITHUB_RAW/app/adapters/registry.py" "$AJD_HOME/app/adapters/registry.py"
download "$GITHUB_RAW/app/adapters/schedulers/__init__.py" "$AJD_HOME/app/adapters/schedulers/__init__.py"
download "$GITHUB_RAW/app/adapters/schedulers/crontab.py" "$AJD_HOME/app/adapters/schedulers/crontab.py"
download "$GITHUB_RAW/app/adapters/schedulers/hermes.py" "$AJD_HOME/app/adapters/schedulers/hermes.py"
download "$GITHUB_RAW/app/adapters/schedulers/launchd.py" "$AJD_HOME/app/adapters/schedulers/launchd.py"
download "$GITHUB_RAW/app/adapters/schedulers/systemd.py" "$AJD_HOME/app/adapters/schedulers/systemd.py"
download "$GITHUB_RAW/app/adapters/services/__init__.py" "$AJD_HOME/app/adapters/services/__init__.py"
download "$GITHUB_RAW/app/adapters/services/docker.py" "$AJD_HOME/app/adapters/services/docker.py"
download "$GITHUB_RAW/app/adapters/services/http.py" "$AJD_HOME/app/adapters/services/http.py"
download "$GITHUB_RAW/app/adapters/services/port.py" "$AJD_HOME/app/adapters/services/port.py"

# Download static and templates (copy whole dirs)
# For static, we need to download key files
mkdir -p "$AJD_HOME/app/static"
mkdir -p "$AJD_HOME/app/templates"
download "$GITHUB_RAW/app/static/app.js" "$AJD_HOME/app/static/app.js"
download "$GITHUB_RAW/app/static/i18n.js" "$AJD_HOME/app/static/i18n.js"
download "$GITHUB_RAW/app/static/style.css" "$AJD_HOME/app/static/style.css"
download "$GITHUB_RAW/app/static/manifest.webmanifest" "$AJD_HOME/app/static/manifest.webmanifest"
download "$GITHUB_RAW/app/static/sw.js" "$AJD_HOME/app/static/sw.js"
download "$GITHUB_RAW/app/static/icon-192.png" "$AJD_HOME/app/static/icon-192.png"
download "$GITHUB_RAW/app/static/icon-512.png" "$AJD_HOME/app/static/icon-512.png"
download "$GITHUB_RAW/app/static/icon-maskable-512.png" "$AJD_HOME/app/static/icon-maskable-512.png"
download "$GITHUB_RAW/app/static/apple-touch-icon-180.png" "$AJD_HOME/app/static/apple-touch-icon-180.png"
download "$GITHUB_RAW/app/templates/index.html" "$AJD_HOME/app/templates/index.html"

# Copy docs for user reference
download "$GITHUB_RAW/AGENTS.md" "$AJD_HOME/AGENTS.md"
download "$GITHUB_RAW/SETUP.md" "$AJD_HOME/SETUP.md"
download "$GITHUB_RAW/README.md" "$AJD_HOME/README.md"
download "$GITHUB_RAW/README-zh.md" "$AJD_HOME/README-zh.md"

# Download docs screenshots
mkdir -p "$AJD_HOME/docs"
download "$GITHUB_RAW/docs/screenshot-desktop.png" "$AJD_HOME/docs/screenshot-desktop.png"
download "$GITHUB_RAW/docs/screenshot-mobile.png" "$AJD_HOME/docs/screenshot-mobile.png"

# Copy projects.example.json as the generic template
download "$GITHUB_RAW/app/projects.example.json" "$AJD_HOME/projects.example.json"

# Create projects.json from example if it doesn't exist
if [ ! -f "$AJD_HOME/projects.json" ]; then
  cp "$AJD_HOME/projects.example.json" "$AJD_HOME/projects.json"
  echo "📝 Created projects.json from template (please edit with your projects)"
fi

# Install Python dependencies
if command -v pip3 &> /dev/null; then
  pip3 install -r "$AJD_HOME/app/requirements.txt" --quiet 2>/dev/null || true
fi

# Start service in background
echo ""
echo "📦 Starting AJD service on port $PORT..."
cd "$AJD_HOME/app/" || exit 1
AJD_HOME="$AJD_HOME" AJD_PORT="$PORT" python3 app.py \
    > "$AJD_HOME/data/logs/server.log" 2>&1 &
SERVER_PID=$!
sleep 2
if kill -0 $SERVER_PID 2>/dev/null; then
  echo "✅ AJD service started (PID: $SERVER_PID)"
else
  echo "❌ Service failed to start. Check $AJD_HOME/data/logs/server.log"
  exit 1
fi

# Wait for health check
echo ""
echo "🔋 Waiting for service to be ready..."
for i in $(seq 10 -1 1); do
  if curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:$PORT/ | grep -q '^2\|^3'; then
    echo "✅ Service is ready (HTTP 2xx/3xx)"
    break
  fi || { echo "   Waiting $i more seconds..."; sleep 2; }
done

# Validate API endpoints with curl 
echo ""
echo "🔍 Validating AJD service endpoints..."
HEALTH_OK=false 
for endpoint in / /api/state /api/heartbeat; do
  resp=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$PORT$endpoint) || resp="ERR"
  if [ "$resp" = "200" ]; then
    HEALTH_OK=true
    echo "✅ $endpoint → HTTP 200"
  elif [ "$resp" != "404" ] && [ "$resp" != "405" ]; then
    HEALTH_OK=false
    echo "❌ $endpoint → HTTP $resp (expected 200, 404, or 405)"
  else
    echo "✅ $endpoint → HTTP $resp (acceptable)"
  fi
done

if [ "$HEALTH_OK" = false ]; then
  echo "⚠️ Some endpoints returned non-200. Check the logs: tail -f $AJD_HOME/data/logs/server.log"
fi

echo ""
echo "🦾 Agent Configuration:"
echo "Copy this to your agent's config (e.g., ~/.hermes/profiles/default/memories/config for Hermes):"
echo "AJD_URL=\"http://127.0.0.1:$PORT/\""
echo ""
echo "Or see AGENTS.md in $AJD_HOME for more agent examples (Claude, Cursor, etc.)"
echo ""
echo "✅ AJD installation complete!"
echo "   Dashboard: http://127.0.0.1:$PORT/"
echo "   Config:    $AJD_HOME/projects.json (edit with your projects)"
