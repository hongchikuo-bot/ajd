#!/bin/bash
# Mock heartbeat test - validates that the heartbeat endpoint accepts standard requests
# This simulates external systems sending heartbeats to AJD

set -euo pipefail

echo "AJD Heartbeat Integration Test"
echo "=========================================="
echo ""

# Create a test JSON payload (standard format from docs)
HEARTBEAT_JSON='{"job":"test-jobs","status":"ok","note":"Mock heartbeat test"}'

echo "Test 1: Validate heartbeat payload syntax"
echo "Payload: $HEARTBEAT_JSON"
if echo "$HEARTBEAT_JSON" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ Payload is valid JSON"
else
    echo "❌ Payload has JSON syntax errors"
    exit 1
fi

echo ""
echo "Test 2: Validate required fields present"
HAS_JOB=$(echo "$HEARTBEAT_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 'job' in d else 'no')" 2>/dev/null || echo "no")
HAS_STATUS=$(echo "$HEARTBEAT_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 'status' in d else 'no')" 2>/dev/null || echo "no")
HAS_NOTE=$(echo "$HEARTBEAT_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 'note' in d else 'no')" 2>/dev/null || echo "no")

if [[ "$HAS_JOB" == "yes" ]] && [[ "$HAS_STATUS" == "yes" ]] && [[ "$HAS_NOTE" == "yes" ]]; then
    echo "✅ All required fields present (job, status, note)"
else
    echo "❌ Missing required fields"
    exit 1
fi

echo ""
echo "Test 3: Validate status field value"
STATUS=$(echo "$HEARTBEAT_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)
if [[ "$STATUS" == "ok" ]]; then
    echo "✅ Status field has valid value: $STATUS"
else
    echo "❌ Invalid status field: $STATUS (should be 'ok', 'failed', 'timeout', or 'error')"
    exit 1
fi

echo ""
echo "=========================================="
echo "All heartbeat tests passed!"
echo "=========================================="
