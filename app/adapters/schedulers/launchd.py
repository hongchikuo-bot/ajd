#!/usr/bin/env python3
"""Launchd adapter — macOS 用。

读 ~/Library/LaunchAgents/ + /Library/LaunchDaemons/ 下的 .plist。
每个 plist 是一个排程 job。
"""

import glob
import os
import plistlib
import re


def _load_plist(path):
    try:
        with open(path, "rb") as f:
            return plistlib.load(f)
    except Exception:
        return None


def _interval_to_cron(plist):
    """把 launchd 的 Schedule / StartCalendarInterval 转成可读字串。"""
    # StartCalendarInterval: {Hour: 8, Minute: 30}
    sci = plist.get("StartCalendarInterval")
    if sci:
        parts = []
        for k in ("Hour", "Minute", "Day", "Month", "Weekday"):
            if k in sci:
                parts.append(f"{k}={sci[k]}")
        return " ".join(parts) if parts else "定時"
    # Schedule: "30 8 * * *" 或 "5/10"
    sch = plist.get("Schedule")
    if sch:
        return str(sch)
    # StartInterval: 每 N 秒
    si = plist.get("StartInterval")
    if si:
        return f"every {si}s"
    return ""


def discover():
    jobs = []
    search_dirs = [
        os.path.expanduser("~/Library/LaunchAgents"),
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
    ]
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        for path in sorted(glob.glob(os.path.join(d, "*.plist"))):
            plist = _load_plist(path)
            if not plist:
                continue
            label = plist.get("Label", os.path.basename(path))
            program = plist.get("Program") or plist.get("ProgramArguments", ["?"])[0]
            jobs.append({
                "id": f"launchd_{label}",
                "name": label,
                "schedule": _interval_to_cron(plist),
                "enabled": not plist.get("Disabled", False),
                "last_run": None,       # launchd 不直接记录
                "next_run": None,
                "command": program,
                "profile": "system" if d.startswith("/Library") else "user",
            })
    return {"source": "launchd", "jobs": jobs}