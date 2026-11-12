#!/usr/bin/env python3
"""
Phase 8: Adapter Validation Suite
Tests that all adapter outputs conform to the unified schema.
"""

import json
import sys
from pathlib import Path


def validate_heartbeat_schema(data):
    """Validate heartbeat JSON against expected schema."""
    required = {"job", "status", "note"}
    if not isinstance(data, dict):
        return False, ["Root must be a JSON object"]
    
    missing = required - set(data.keys())
    if missing:
        return False, [f"Missing required fields: {', '.join(sorted(missing))}"]
    
    allowed_statuses = {"ok", "failed", "timeout", "error"}
    if data["status"] not in allowed_statuses:
        return False, [f"'{data['status']}' is not a valid status (allowed: {', '.join(allowed_statuses)})"]
    
    return True, []


def validate_project_schema(data):
    """Validate project JSON against expected schema."""
    if not isinstance(data, dict):
        return False, ["Root must be a JSON object"]
    
    required = {"name", "path"}
    optional = {"cron", "agent_command", "service_type", "service_port", "description"}
    
    missing = required - set(data.keys())
    if missing:
        return False, [f"Missing required fields: {', '.join(sorted(missing))}"]
    
    unexpected = set(data.keys()) - (required | optional)
    if unexpected:
        return False, [f"Unexpected fields: {', '.join(sorted(unexpected))}"]
    
    # Validate cron format if present
    if "cron" in data and data["cron"]:
        import re
        pattern = r'^\d+( \*\*|-|\d+,\s*)+(\d{1,2}|\*)+(\d+(\/\d+)?|\*|\d+(\/\d+)?)(\s+\d+(\/\d+)?|\*)+(\s+\w+(,\s*\w+)*(/.*)?)?$'
        if not re.match(pattern, data["cron"]):
            return False, ["Invalid cron expression format"]
    
    # Validate agent_command if present
    if "agent_command" in data and data["agent_command"]:
        if len(data["agent_command"]) > 4096:
            return False, ["agent_command must be <= 4096 characters"]
    
    return True, []


def validate_service_health_response(data):
    """Validate service health check response."""
    required = {"status", "port", "latency_ms"}
    optional = {"error_message", "retries"}
    
    missing = required - set(data.keys())
    if missing:
        return False, [f"Missing required fields: {', '.join(sorted(missing))}"]
    
    if data["status"] not in {"ok", "failed", "timeout"}:
        return False, [f"'{data['status']}' is not a valid status"]
    
    if not isinstance(data.get("latency_ms"), (int, float)):
        return False, ["latency_ms must be a number"]
    
    return True, []


def main():
    """Run validation tests."""
    tests_passed = 0
    tests_failed = 0
    
    test_cases = [
        # Heartbeat tests
        ({
            "job": "daily-news-report",
            "status": "ok",
            "note": "Generated 3.2MB PDF"
        }, "Valid heartbeat"),
        
        ({
            "job": "broken-heartbeat",
            "status": "unknown",  # invalid
            "note": ""
        }, "Invalid status"),
        
        # Project schema tests  
        ({
            "name": "<YOUR_PROJECT_NAME>",
            "path": "/<PROJECT_PATH>"
        }, "Valid minimal project"),
        
        ({
            "name": "my-project",
            "path": "/Users/macmima1234/myproj",
            "cron": "0 9 * * *",
            "agent_command": "hermes run my-agent"
        }, "Valid full project"),
        
        # Service health tests
        ({
            "status": "ok",
            "port": 5080,
            "latency_ms": 42
        }, "Valid healthy service"),
        
        ({
            "status": "timeout",
            "port": 9000,
            "latency_ms": None
        }, "Invalid: latency_ms must be numeric")
    ]
    
    for i, (data, description) in enumerate(test_cases, 1):
        if data is None:
            data = {}
            
        try:
            schema_valid, errors = validate_heartbeat_schema(data)
            status_ok = schema_valid and len(errors) == 0
            result = "✅ PASS" if status_ok else "❌ FAIL"
            
            if status_ok:
                tests_passed += 1
            else:
                tests_failed += 1
            
            print(f"[Heartbeat] Test {i}: {description}")
            print(f"{result} - {'OK' if status_ok else ', '.join(errors)}")
            
        except Exception as e:
            tests_failed += 1
            print(f"[Heartbeat] Test {i}: {description}")
            print(f"❌ ERROR - {e}")
    
    print("\n--- Summary ---")
    print(f"Tests passed: {tests_passed}/{len(test_cases)}")
    print(f"Tests failed: {tests_failed}")
    
    return 0 if tests_failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
