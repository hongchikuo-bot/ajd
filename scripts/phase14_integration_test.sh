#!/usr/bin/env bash
# Phase 14 Integration Test: All adapters together with real projects.json config
# Tests end-to-end: registry loads all adapters, discovers data, returns unified format

set -euo pipefail

AJD_ROOT="${1:-/Users/macmima1234/root/ajd}"
OUTPUT_FILE="/tmp/phase14_test_results.json"

echo "=== AJD Phase 14 Integration Test ==="
echo "AJD root: $AJD_ROOT"
echo ""

# Create temp directory for Python test scripts
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Test 1: Registry syntax check
echo "📋 Testing adapter registry syntax..."
if python3 -m py_compile "$AJD_ROOT/app/adapters/registry.py" 2>/dev/null; then
    echo "  ✅ registry.py syntax OK"
else
    echo "  ❌ registry.py syntax error"
    exit 1
fi

if python3 -m py_compile "$AJD_ROOT/app/adapters/__init__.py" 2>/dev/null; then
    echo "  ✅ __init__.py syntax OK"
else
    echo "  ❌ __init__.py syntax error"
    exit 1
fi

# Test 2: All scheduler adapters syntax
echo ""
echo "📋 Testing all scheduler adapters syntax..."
SCHEDULER_FILES=(
    "$AJD_ROOT/app/adapters/schedulers/crontab.py"
    "$AJD_ROOT/app/adapters/schedulers/hermes.py"
    "$AJD_ROOT/app/adapters/schedulers/launchd.py"
    "$AJD_ROOT/app/adapters/schedulers/systemd.py"
)
ALL_SCHED_OK=true
for f in "${SCHEDULER_FILES[@]}"; do
    if python3 -m py_compile "$f" 2>/dev/null; then
        echo "  ✅ $(basename $f) syntax OK"
    else
        echo "  ❌ $(basename $f) syntax error"
        ALL_SCHED_OK=false
    fi
done

# Test 3: All service adapters syntax
echo ""
echo "📋 Testing all service adapters syntax..."
SERVICE_FILES=(
    "$AJD_ROOT/app/adapters/services/port.py"
    "$AJD_ROOT/app/adapters/services/http.py"
    "$AJD_ROOT/app/adapters/services/docker.py"
)
ALL_SVC_OK=true
for f in "${SERVICE_FILES[@]}"; do
    if python3 -m py_compile "$f" 2>/dev/null; then
        echo "  ✅ $(basename $f) syntax OK"
    else
        echo "  ❌ $(basename $f) syntax error"
        ALL_SVC_OK=false
    fi
done

# Test 4: Functional test - discover_schedulers()
echo ""
echo "📋 Testing discover_schedulers() with all adapters..."
cat > "$TMPDIR/test_sched.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd')
from app.adapters import discover_schedulers
import json
try:
    scheds = discover_schedulers()
    print(json.dumps(scheds, ensure_ascii=False))
except Exception as e:
    print('ERROR:', str(e))
    import traceback
    traceback.print_exc()
EOF

SCHED_OUTPUT=$(cd "$AJD_ROOT" && python3 "$TMPDIR/test_sched.py" 2>&1)

if echo "$SCHED_OUTPUT" | grep -q '"source"'; then
    echo "  ✅ discover_schedulers() returned valid JSON"
    # Count schedulers and jobs
    cat > "$TMPDIR/count_sched.py" << 'EOF'
import sys, json
data = json.load(sys.stdin)
print(len(data))
for s in data:
    print(f'  {s.get("source", "?"):15s} : {len(s.get("jobs", []))} jobs')
EOF
    SCHED_COUNT=$(echo "$SCHED_OUTPUT" | python3 "$TMPDIR/count_sched.py" 2>&1)
    echo "$SCHED_COUNT"
else
    echo "  ❌ discover_schedulers() failed"
    echo "  Output: $SCHED_OUTPUT"
    ALL_SCHED_OK=false
fi

# Test 5: Functional test - discover_services() with test config
echo ""
echo "📋 Testing discover_services() with real config..."
cat > "$TMPDIR/test_svc.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd')
from app.adapters import discover_services
import json
try:
    svcs = discover_services({
        'services': {
            'test_port': {'port': 5080, 'desc': 'AJD Dashboard'},
            'test_http': {'url': 'http://localhost:5080/', 'desc': 'AJD HTTP'},
            'test_docker': {'container': 'ajd-test', 'desc': 'AJD Container'}
        }
    })
    print(json.dumps(svcs, ensure_ascii=False))
except Exception as e:
    print('ERROR:', str(e))
    import traceback
    traceback.print_exc()
EOF

SVC_OUTPUT=$(cd "$AJD_ROOT" && python3 "$TMPDIR/test_svc.py" 2>&1)

if echo "$SVC_OUTPUT" | grep -q '"source"'; then
    echo "  ✅ discover_services() returned valid JSON"
    cat > "$TMPDIR/count_svc.py" << 'EOF'
import sys, json
data = json.load(sys.stdin)
print(len(data))
for s in data:
    up = sum(1 for svc in s.get('services', []) if svc.get('up'))
    total = len(s.get('services', []))
    print(f'  {s.get("source", "?"):15s} : {up}/{total} up')
EOF
    SVC_COUNT=$(echo "$SVC_OUTPUT" | python3 "$TMPDIR/count_svc.py" 2>&1)
    echo "$SVC_COUNT"
else
    echo "  ❌ discover_services() failed"
    echo "  Output: $SVC_OUTPUT"
    ALL_SVC_OK=false
fi

# Test 6: Test with projects.json from app directory
echo ""
echo "📋 Testing with projects.json config..."
if [ -f "$AJD_ROOT/app/projects.json" ]; then
    cat > "$TMPDIR/test_projects.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd')
import json
from app.adapters import discover_services
with open('/Users/macmima1234/root/ajd/app/projects.json') as f:
    reg = json.load(f)
svcs = discover_services(reg)
print(json.dumps(svcs, ensure_ascii=False))
EOF

    SVC_FROM_PROJECTS=$(cd "$AJD_ROOT" && python3 "$TMPDIR/test_projects.py" 2>&1)
    
    if echo "$SVC_FROM_PROJECTS" | grep -q '"source"'; then
        echo "  ✅ discover_services() works with projects.json"
        cat > "$TMPDIR/count_svc2.py" << 'EOF'
import sys, json
data = json.load(sys.stdin)
for s in data:
    up = sum(1 for svc in s.get('services', []) if svc.get('up'))
    total = len(s.get('services', []))
    print(f'    {s.get("source", "?"):15s} : {up}/{total} up')
EOF
        echo "$SVC_FROM_PROJECTS" | python3 "$TMPDIR/count_svc2.py" 2>&1
    else
        echo "  ❌ discover_services() failed with projects.json"
        echo "  Output: $SVC_FROM_PROJECTS"
        ALL_SVC_OK=false
    fi
else
    echo "  ⚠️  projects.json not found, skipping"
fi

# Test 7: Validate unified format structure
echo ""
echo "📋 Validating unified format structure..."
FORMAT_VALID=true

# Check scheduler format
cat > "$TMPDIR/validate_sched.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd')
from app.adapters import discover_schedulers
scheds = discover_schedulers()
for s in scheds:
    if 'source' not in s:
        print('MISSING: source in scheduler result')
    if 'jobs' not in s:
        print('MISSING: jobs in scheduler result')
    for j in s.get('jobs', []):
        required = ['id', 'name', 'schedule', 'enabled', 'command', 'profile']
        for r in required:
            if r not in j:
                print(f'MISSING: {r} in job {j.get("id", "?")}')
print('SCHED_FORMAT_OK')
EOF

FORMAT_CHECK=$(cd "$AJD_ROOT" && python3 "$TMPDIR/validate_sched.py" 2>&1)

if echo "$FORMAT_CHECK" | grep -q "MISSING"; then
    echo "  ❌ Scheduler format validation failed:"
    echo "$FORMAT_CHECK" | grep "MISSING"
    FORMAT_VALID=false
else
    echo "  ✅ Scheduler format valid"
fi

# Check service format
cat > "$TMPDIR/validate_svc.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd')
from app.adapters import discover_services
svcs = discover_services({'services': {'test': {'port': 5080}}})
for s in svcs:
    if 'source' not in s:
        print('MISSING: source in service result')
    if 'services' not in s:
        print('MISSING: services in service result')
    for svc in s.get('services', []):
        required = ['id', 'name', 'type', 'up', 'detail', 'checked_at']
        for r in required:
            if r not in svc:
                print(f'MISSING: {r} in service {svc.get("id", "?")}')
print('SVC_FORMAT_OK')
EOF

FORMAT_CHECK=$(cd "$AJD_ROOT" && python3 "$TMPDIR/validate_svc.py" 2>&1)

if echo "$FORMAT_CHECK" | grep -q "MISSING"; then
    echo "  ❌ Service format validation failed:"
    echo "$FORMAT_CHECK" | grep "MISSING"
    FORMAT_VALID=false
else
    echo "  ✅ Service format valid"
fi

# Test 8: Test app.py can import and use adapters
echo ""
echo "📋 Testing app.py integration with adapters..."
cat > "$TMPDIR/test_app.py" << 'EOF'
import sys
sys.path.insert(0, '/Users/macmima1234/root/ajd/app')
from adapters.registry import discover_schedulers, discover_services
print('import OK')
scheds = discover_schedulers()
print(f'schedulers: {len(scheds)}')
svcs = discover_services({})
print(f'services: {len(svcs)}')
EOF

APP_IMPORT=$(cd "$AJD_ROOT" && python3 "$TMPDIR/test_app.py" 2>&1)

if echo "$APP_IMPORT" | grep -q "import OK"; then
    echo "  ✅ app.py imports adapters correctly"
    echo "  $APP_IMPORT" | tail -2
else
    echo "  ❌ app.py import failed"
    echo "  Output: $APP_IMPORT"
    FORMAT_VALID=false
fi

# Summary
echo ""
echo "=== Phase 14 Test Summary ==="

cat > "$OUTPUT_FILE" << EOF
{
  "phase": 14,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "ajd_root": "$AJD_ROOT",
  "registry_syntax": true,
  "all_scheduler_syntax": $ALL_SCHED_OK,
  "all_service_syntax": $ALL_SVC_OK,
  "discover_schedulers_functional": $(echo "$SCHED_OUTPUT" | grep -q '"source"' && echo true || echo false),
  "discover_services_functional": $(echo "$SVC_OUTPUT" | grep -q '"source"' && echo true || echo false),
  "format_validation": $FORMAT_VALID,
  "app_integration": $(echo "$APP_IMPORT" | grep -q "import OK" && echo true || echo false)
}
EOF

if [ "$ALL_SCHED_OK" = true ] && [ "$ALL_SVC_OK" = true ] && [ "$FORMAT_VALID" = true ]; then
    echo "✅ Phase 14 Integration Test: PASSED"
    exit 0
else
    echo "❌ Phase 14 Integration Test: FAILED"
    cat "$OUTPUT_FILE"
    exit 1
fi