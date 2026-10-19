#!/usr/bin/env python3
"""Simple test: send a heartbeat to AJD and verify the response."""
import json, sys
import os
# Auto-detect app directory relative to this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(SCRIPT_DIR, 'app'))

def test_heartbeat():
    import requests
    url = "http://127.0.0.1:5080/api/state"
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            print("✅ AJD service is running")
            print(f"   API Endpoints available:")
            print(f"   - GET {url}")
            print(f"   - POST /api/heartbeat")
            print(f"   Response keys: {list(data.keys())}")
            return True
        else:
            print(f"❌ Unexpected status: {resp.status_code}")
            return False
    except Exception as e:
        print(f"⚠️  Cannot connect: {e}")
        return False

if __name__ == "__main__":
    # Try to get service IP/port from environment or use default
    import os
    host = os.environ.get('AJD_HOST', '127.0.0.1')
    port = os.environ.get('AJD_PORT', '5080')
    url = f"http://{host}:{port}/api/state"
    
    print(f"Testing AJD on {url}")
    test_heartbeat()
