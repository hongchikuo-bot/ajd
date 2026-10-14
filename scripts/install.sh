#!/usr/bin/env bash
# install.sh — AJD 使用者端安裝腳本
# 用法：curl -fsSL https://raw.githubusercontent.com/hongchikuo-bot/ajd/main/install.sh | bash
set -e

echo ""
echo "=================================================="
echo "📦 AJD (AI Agents Job Dashboard) Installation"
echo "=================================================="
echo ""

# 1. 檢查系統支援度
echo "🔍 Checking system prerequisites..."
if command -v python3 >/dev/null 2>&1; then
    echo "✅ python3 found: $(python3 --version)"
else
    echo "❌ python3 not found — please install from python.org or your package manager"
    exit 1
fi

if command -v pip3 >/dev/null 2>&1; then
    echo "✅ pip3 found, installing dependencies..."
    pip3 install requests -q || { echo "⚠️  requests install failed, may still work"; }
else
    echo "❌ pip3 not found — cannot install dependencies"
    exit 1
fi

# 2. 選擇安裝目錄（無空間）
echo ""
echo "📁 Installation directory: [default: ~/root/ajd]"
read -p "Enter path (or press Enter to use default): " ajd_path
ajd_path="${ajd_path:-$HOME/root/ajd}"

# 確保目錄無空格
if echo "$ajd_path" | grep -q '[[:space:]]'; then
    echo "❌ Error: Installation directory path must not contain spaces"
    exit 1
fi

echo "✅ Creating installation directory: $ajd_path"
mkdir -p "$ajd_path/app data/logs data/snapshots docs" || { echo "⚠️  Some directories may already exist (OK)"; }

cd "$ajd_path"

# 3. 複製核心檔案（從範本或 GitHub）
echo ""
echo "📥 Copying AJD core files..."

if [ -f /tmp/ajd_source_app.zip ]; then
    echo "⚠️  Using local source (from previous phase)"
else
    echo "🔄 Copying AJD core files from source..."
    # Determine source directory (where this script lives)
    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "📂 Source: $SOURCE_DIR"
    
    # Copy app/ directory (includes adapters/, static/, templates/, *.py)
    cp -r "$SOURCE_DIR/app/"* "app/" || { echo "❌ Cannot copy app/"; exit 1; }
    
    # Copy root-level files
    cp "$SOURCE_DIR/AGENTS.md" . 2>/dev/null || true
    cp "$SOURCE_DIR/SETUP.md" . 2>/dev/null || true
    cp "$SOURCE_DIR/README.md" . 2>/dev/null || true
    cp "$SOURCE_DIR/README-zh.md" . 2>/dev/null || true
    cp "$SOURCE_DIR/projects.example.json" . 2>/dev/null || { echo "❌ Cannot copy projects.example.json"; exit 1; }
    cp "$SOURCE_DIR/LICENSE" . 2>/dev/null || true
    cp "$SOURCE_DIR/Dockerfile" . 2>/dev/null || true
    cp "$SOURCE_DIR/docker-compose.yml" . 2>/dev/null || true
    
    # Copy docs screenshots
    mkdir -p docs
    cp "$SOURCE_DIR/docs/screenshot-desktop.png" docs/ 2>/dev/null || echo "⚠️  screenshot-desktop.png not found"
    cp "$SOURCE_DIR/docs/screenshot-mobile.png" docs/ 2>/dev/null || echo "⚠️  screenshot-mobile.png not found"
fi

echo "📊 Current directory contents:"
ls -la "$ajd_path/" | head -10

# 4. projects.json 已在根目錄（從 projects.example.json 複製），提醒使用者編輯
echo ""
echo "🔧 Setting up projects.json (fill it with your project config):"
cp projects.example.json projects.json 2>/dev/null || true
cat projects.json
echo ""
echo "✅ projects.json ready for your configuration"
echo "   (edit it with: nano projects.json)"

# 5. 檢查 Python 依賴
echo ""
echo "🐍 Installing Python dependencies..."
if [ -f app/requirements.txt ]; then
    pip3 install -r app/requirements.txt -q || echo "⚠️  Some packages may fail (non-critical)"
else
    echo "⚠️  requirements.txt not found — installing basic deps..."
    pip3 install requests -q
fi

# 6. 啟動健康檢查
echo ""
echo "🔍 Running health check..."
cd "$ajd_path/app"
python3 app.py --port 5199 > data/logs/server.log 2>&1 & sleep 3
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5199/ | grep -q "200"; then
    echo "✅ Health check passed on port 5199"
    PID=$(pgrep -f "app/app.py --port 5199" || pgrep -f "python.*app.py") && kill "$PID" 2>/dev/null || true
else
    echo "❌ Health check failed — see data/logs/server.log"
    rm -f data/logs/server.log
fi

echo ""
echo "=================================================="
echo "🎉 AJD installation complete!"
echo "=================================================="
echo ""
echo "📖 Next steps:"
echo "1. Configure your project in projects.json"
echo "   - Edit '$ajd_path/projects.json' with your project details"
echo "2. Run your job scripts:"
echo "   cd $ajd_path && nano projects.json"
echo "3. Start the dashboard service:"
echo "   AJD_PORT=5199 python3 app/app.py --port 5199 &"
echo ""
echo "📚 Documentation:"
echo "   - README.md / README-zh.md"
echo "   - AGENTS.md (for AI agent setup)"
echo "   - SETUP.md (manual configuration guide)"
echo ""
sha256sum projects.example.json
echo ""
echo "✅ Your AJD dashboard is ready!"
