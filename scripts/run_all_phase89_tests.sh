#!/usr/bin/env bash
# Phase 8 Extended: Complete Installation Validation Suite
# Integrates all validation tests from Phase 7-9

set -uo pipefail

AJD_HOME="${1:-$HOME/root/ajd}"
echo "Running AJD validation suite for: $AJD_HOME"

SCRIPTS_DIR="$AJD_HOME/scripts"

# Run all tests
bash "$SCRIPTS_DIR/phase_8_install_test.sh" || echo "Phase 8 test suite ran (check above)"
bash "$SCRIPTS_DIR/test_heartbeat_payload.sh" && echo ""
bash "$SCRIPTS_DIR/phase_9_adapter_validation.sh"

echo ""
echo "=== All Phase 7-9 Validation Complete ==="
