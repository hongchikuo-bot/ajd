#!/usr/bin/env python3
"""Systemd timer adapter — Linux 用。

读 /etc/systemd/system/*.timer + ~/.config/systemd/user/*.timer。
每个 timer 对应一个 .service，timer 是排程，service 是執行。
"""

import glob
import os
import subprocess


def _run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return p.stdout
    except Exception:
        return ""


def _parse_timer(path):
    """读 .timer 檔，回传 (schedule, enabled)。"""
    schedule = ""
    enabled = True
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if line.startswith("OnCalendar="):
                    schedule = line.split("=", 1)[1]
                elif line.startswith("OnBootSec="):
                    schedule = f"boot + {line.split('=', 1)[1]}"
                elif line.startswith("OnUnitActiveSec="):
                    schedule = f"every {line.split('=', 1)[1]}"
                elif line.startswith("Enabled="):
                    enabled = line.split("=", 1)[1].lower() in ("yes", "true", "1")
    except Exception:
        pass
    return schedule, enabled


def _service_name(timer_path):
    """foo.timer → foo.service"""
    base = os.path.basename(timer_path)
    if base.endswith(".timer"):
        return base[:-6] + ".service"
    return base


def _service_command(service_path):
    """从 .service 檔读 ExecStart。"""
    try:
        with open(service_path, encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if line.startswith("ExecStart="):
                    return line.split("=", 1)[1]
    except Exception:
        pass
    return ""


def discover():
    jobs = []
    search_dirs = [
        "/etc/systemd/system",
        os.path.expanduser("~/.config/systemd/user"),
    ]
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        for path in sorted(glob.glob(os.path.join(d, "*.timer"))):
            schedule, enabled = _parse_timer(path)
            svc = _service_name(path)
            svc_path = os.path.join(d, svc)
            command = _service_command(svc_path) if os.path.exists(svc_path) else ""
            label = os.path.basename(path)[:-6]
            jobs.append({
                "id": f"systemd_{label}",
                "name": label,
                "schedule": schedule or "timer",
                "enabled": enabled,
                "last_run": None,
                "next_run": None,
                "command": command,
                "profile": "system" if d.startswith("/etc") else "user",
            })
    return {"source": "systemd", "jobs": jobs}