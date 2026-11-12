#!/usr/bin/env bash
# phase_5_validate_syntax.sh — AJD 安裝套件語法檢查
# 用途：在說「完成」前驗證所有 .sh / .py 檔案能透過基本語法檢查
# 規則：bash -n <檔名> → exit 0; python3 -m py_compile <檔名> → exit 0

set -e

echo "=================================================="
echo "AJD Phase 5 — 語法檢查"
echo "=================================================="

errors=0

# .sh 檔案
for f in install.sh scripts/*.sh release_checklist.sh; do
    if [ -f "$f" ]; then
        echo -n "$(basename "$f"): "
        if bash -n "$f"; then
            echo "✅ bash -n passed"
        else
            echo "❌ FAILED: $(bash -n "$f" 2>&1)"
            errors=$((errors + 1))
        fi
    fi
done

# .py 檔案
for f in app/app.py app/*.py app/adapters/*.py scripts/*.py; do
    if [ -f "$f" ]; then
        echo -n "$(basename "$f"): "
        if python3 -m py_compile "$f"; then
            echo "✅ python3 -m py_compile passed"
        else
            echo "❌ FAILED: $(python3 -m py_compile "$f" 2>&1)"
            errors=$((errors + 1))
        fi
    fi
done

# JSON / YAML
for f in app/projects.example.json docs/.gitkeep; do
    if [ -f "$f" ]; then
        echo -n "$(basename "$f"): "
        if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
            echo "✅ JSON valid"
        else
            echo "❌ JSON invalid: $(python3 -c "import json,sys;json.load(open('$f'));print('OK')" 2>&1)"
            errors=$((errors + 1))
        fi
    fi
done

echo "=================================================="
if [ "$errors" -eq 0 ]; then
    echo "✅ Phase 5 — 語法檢查通過！所有檔案無錯誤。"
else
    echo "❌ Phase 5 失敗：發現 $errors 個語法錯誤，請修正後再跑一次測試。"
fi
echo "=================================================="

exit "$errors"
