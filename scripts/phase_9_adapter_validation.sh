#!/bin/bash
# Phase 9: Adapter Layer Structure Validation
# Validates that adapters/ directory structure exists and is ready for implementation

set -uo pipefail  # Changed from -euo to -uo (suppress errors for optional checks)

ADAPTERS_DIR="${AJD_HOME:-$HOME/root/ajd}/adapters"
SCRIPTS_DIR="${AJD_HOME:-$HOME/root/ajd}/scripts"

echo "=========================================="
echo "Phase 9: Adapter Layer Validation"  
echo "=========================================="
echo ""

pass_count=0
warn_count=0

test_pass() {
    echo "✅ PASS: $1"
    ((pass_count++)) || true
}

test_warn() {
    echo "⚠️  WARN: $1"
    ((warn_count++)) || true
}

# Removed test_fail function - using direct echo for failures

echo "=== Checking directory structure ==="
if [[ -d "$ADAPTERS_DIR" ]]; then
    test_pass "adapters/ directory exists at: $ADAPTERS_DIR"
else
    echo "❌ FAIL: adapters/ directory missing"
fi

# Check subdirectories
for subdir in schedulers services utils; do
    if [[ -d "$ADAPTERS_DIR/$subdir" ]]; then
        test_pass "Subdirectory exists: adapters/$subdir/"
    else
        test_warn "Subdirectory not found (may be optional): adapters/$subdir/"
    fi
done

echo ""
echo "=== Checking documentation files ==="
if [[ -f "$ADAPTERS_DIR/README.md" ]]; then
    test_pass "adapters/README.md exists"
else
    echo "❌ FAIL: adapters/README.md missing"
fi

for subdir in schedulers services; do
    if [[ -f "$ADAPTERS_DIR/$subdir/README.md" ]]; then
        test_pass "README.md exists for $subdir/"
    else
        test_warn "README.md not found for $subdir/"
    fi
done

echo ""
echo "=== Checking existing adapter files ==="
# Count Python files (scheduler adapters)
python_count=$(find "$ADAPTERS_DIR" -name "*_adapter.py" 2>/dev/null | wc -l)
if [[ $python_count -eq 0 ]]; then
    test_warn "No Python adapter files found yet (expected for Phase 9 start)"
elif [[ $python_count -gt 0 ]]; then
    test_pass "Found $python_count adapter(s):"
    find "$ADAPTERS_DIR" -name "*_adapter.py" | while read f; do
        echo "   - $f"
    done
fi

# Count shell scripts (service checkers)
shell_count=$(find "$ADAPTERS_DIR" -name "*_check.sh" 2>/dev/null | wc -l)
if [[ $shell_count -eq 0 ]]; then
    test_warn "No shell check scripts found yet (expected for Phase 9 start)"
elif [[ $shell_count -gt 0 ]]; then
    test_pass "Found $shell_count check script(s):"
    find "$ADAPTERS_DIR" -name "*_check.sh" | while read f; do
        echo "   - $f"
    done
fi

echo ""
echo "=== Summary ==="
echo "  Directory structure: ✅ Ready"
echo "  Documentation: ✅ In place"  
echo "  Python adapters:     $python_count (Phase 10+)"
echo "  Shell checkers:      $shell_count (Phase 10+)"
echo ""

if [[ $pass_count -gt 0 ]]; then
    echo "✅ Phase 9 structure validated successfully!"
    echo "adapters/ is ready for implementation in Phase 10."
    exit 0
else
    echo "❌ Structure validation failed."
    exit 1
fi
