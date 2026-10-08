#!/usr/bin/env python3
"""AJD Test Utility: Fake Cron Job

Simulates a cron job that runs periodically and posts heartbeats to AJD.
Usage:
    python3 test_fake_cron.py --job "daily-report" --status ok --interval 10
    python3 test_fake_cron.py --job "backup" --status fail --note "disk full" --once
"""
import argparse
import json
import os
import sys
import time
import urllib.request
from datetime import datetime, timezone, timedelta

# Taiwan timezone
TW = timezone(timedelta(hours=8))

def post_heartbeat(url, job, status, note="", project="", duration_s=None, token=None):
    """Post a heartbeat to AJD."""
    data = {
        "job": job,
        "status": status,
        "note": note[:300],
        "project": project[:60],
    }
    if duration_s is not None:
        data["duration_s"] = duration_s

    req_data = json.dumps(data).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if token:
        headers["X-Dash-Token"] = token

    req = urllib.request.Request(url, data=req_data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        return {"ok": False, "error": str(e)}


def main():
    parser = argparse.ArgumentParser(description="Fake cron job for AJD testing")
    parser.add_argument("--job", required=True, help="Job name (e.g., daily-report)")
    parser.add_argument("--status", choices=["ok", "fail", "warn"], default="ok", help="Heartbeat status")
    parser.add_argument("--note", default="", help="Optional note")
    parser.add_argument("--project", default="", help="Project name")
    parser.add_argument("--duration", type=int, help="Duration in seconds")
    parser.add_argument("--interval", type=int, default=10, help="Interval between heartbeats (seconds)")
    parser.add_argument("--count", type=int, default=3, help="Number of heartbeats to send")
    parser.add_argument("--once", action="store_true", help="Send only one heartbeat and exit")
    parser.add_argument("--url", default="http://127.0.0.1:5080/api/heartbeat", help="AJD heartbeat endpoint")
    parser.add_argument("--token", default="", help="Auth token (if AJD_AUTH_REQUIRED=true)")
    args = parser.parse_args()

    if args.once:
        args.count = 1

    print(f"=== AJD Fake Cron: {args.job} ===")
    print(f"Target: {args.url}")
    print(f"Status: {args.status} | Interval: {args.interval}s | Count: {args.count}")
    print()

    for i in range(args.count):
        # Simulate job running
        start = time.time()
        time.sleep(0.1)  # tiny "work"
        duration = time.time() - start

        note = args.note
        if not note:
            note = f"run #{i+1} at {datetime.now(TW).strftime('%H:%M:%S')}"

        result = post_heartbeat(
            args.url,
            job=args.job,
            status=args.status,
            note=note,
            project=args.project,
            duration_s=args.duration or round(duration, 2),
            token=args.token if args.token else None,
        )

        ts = datetime.now(TW).strftime("%Y-%m-%d %H:%M:%S")
        if result.get("ok"):
            print(f"[{ts}] ✅ Heartbeat sent: {result.get('recorded', {}).get('job')} → {result.get('recorded', {}).get('status')}")
        else:
            print(f"[{ts}] ❌ Failed: {result.get('error')}")

        if i < args.count - 1:
            time.sleep(args.interval)

    print("\n=== Done ===")


if __name__ == "__main__":
    main()