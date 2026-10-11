#!/usr/bin/env python3
"""Test adapter layer — verify all adapters load and return standard format."""

import sys
import os

# Ensure app is on path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from adapters.registry import discover_schedulers, discover_services
from adapters import normalize_scheduler, normalize_service


def test_scheduler_adapters():
    """Test all scheduler adapters load and produce valid output."""
    print("Testing scheduler adapters...")
    scheds = discover_schedulers()
    
    # Should have 4 sources: crontab, hermes, launchd, systemd
    sources = [s["source"] for s in scheds]
    print(f"  Found sources: {sources}")
    
    expected = {"crontab", "hermes", "launchd", "systemd"}
    found = set(sources)
    
    if expected == found:
        print(f"  ✅ All 4 scheduler adapters present")
    else:
        missing = expected - found
        extra = found - expected
        if missing:
            print(f"  ⚠️  Missing: {missing}")
        if extra:
            print(f"  ⚠️  Extra: {extra}")
    
    # Validate each adapter output format
    for s in scheds:
        normalized = normalize_scheduler(s)
        assert "source" in normalized
        assert "jobs" in normalized
        assert isinstance(normalized["jobs"], list)
        for job in normalized["jobs"]:
            assert "id" in job
            assert "name" in job
            assert "schedule" in job
            assert "enabled" in job
            assert "command" in job
            assert "profile" in job
    
    return True


def test_service_adapters():
    """Test all service adapters load and produce valid output."""
    print("Testing service adapters...")
    
    # Mock registry with service config
    registry = {
        "services": {
            "web": {"type": "http", "port": 8080, "url": "http://localhost:8080/health"},
            "db": {"type": "port", "port": 5432},
        }
    }
    
    svcs = discover_services(registry)
    sources = [s["source"] for s in svcs]
    print(f"  Found sources: {sources}")
    
    expected = {"port", "http", "docker"}
    found = set(sources)
    
    if expected == found:
        print(f"  ✅ All 3 service adapters present")
    else:
        missing = expected - found
        extra = found - expected
        if missing:
            print(f"  ⚠️  Missing: {missing}")
        if extra:
            print(f"  ⚠️  Extra: {extra}")
    
    # Validate each adapter output format
    for s in svcs:
        normalized = normalize_service(s)
        assert "source" in normalized
        assert "services" in normalized
        assert isinstance(normalized["services"], list)
        for svc in normalized["services"]:
            assert "id" in svc
            assert "name" in svc
            assert "type" in svc
            assert "up" in svc
            assert "detail" in svc
            assert "checked_at" in svc
    
    return True


def test_normalize_functions():
    """Test normalization functions handle edge cases."""
    print("Testing normalization functions...")
    
    # Test scheduler normalization with minimal input
    raw = {"source": "test", "jobs": [{"name": "job1"}]}
    norm = normalize_scheduler(raw)
    assert norm["source"] == "test"
    assert len(norm["jobs"]) == 1
    assert norm["jobs"][0]["id"] == "job1"
    assert norm["jobs"][0]["name"] == "job1"
    assert norm["jobs"][0]["enabled"] is True
    assert norm["jobs"][0]["schedule"] == ""
    assert norm["jobs"][0]["command"] == ""
    
    # Test service normalization with minimal input
    raw = {"source": "test", "services": [{"name": "svc1"}]}
    norm = normalize_service(raw)
    assert norm["source"] == "test"
    assert len(norm["services"]) == 1
    assert norm["services"][0]["id"] == "svc1"
    assert norm["services"][0]["name"] == "svc1"
    assert norm["services"][0]["type"] == "unknown"
    assert norm["services"][0]["up"] is False
    assert norm["services"][0]["detail"] == ""
    assert norm["services"][0]["checked_at"] == ""
    
    # Test empty inputs
    norm = normalize_scheduler({})
    assert norm["source"] == "unknown"
    assert norm["jobs"] == []
    
    norm = normalize_service({})
    assert norm["source"] == "unknown"
    assert norm["services"] == []
    
    print("  ✅ Normalization functions handle edge cases")
    return True


def main():
    print("=" * 50)
    print("AJD Adapter Layer Tests")
    print("=" * 50)
    
    try:
        test_normalize_functions()
        print()
        test_scheduler_adapters()
        print()
        test_service_adapters()
        print()
        print("=" * 50)
        print("✅ All adapter tests passed!")
        print("=" * 50)
        return 0
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())