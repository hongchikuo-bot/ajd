#!/usr/bin/env python3
"""AJD adapter layer — 把各种排程/服务来源转成统一格式。

核心只认统一格式，不关心底层是 crontab、launchd、systemd 还是 Hermes。
每个 adapter 实现 discover() -> dict，回传标准结构。
"""

# ── 统一格式定义 ──────────────────────────────────────────────
#
# Scheduler adapter 回传:
#   {
#     "source": "crontab",          # 来源名称
#     "jobs": [
#       {
#         "id": "unique_id",        # 在这个 source 内唯一
#         "name": "human name",
#         "schedule": "cron expr or natural language",
#         "enabled": true/false,
#         "last_run": "ISO ts or null",
#         "next_run": "ISO ts or null",
#         "command": "the actual command/script",
#         "profile": "optional profile name"
#       }
#     ]
#   }
#
# Service adapter 回传:
#   {
#     "source": "port",              # 来源名称
#     "services": [
#       {
#         "id": "unique_id",
#         "name": "human name",
#         "type": "port|http|docker",
#         "up": true/false,
#         "detail": "extra info string",
#         "checked_at": "ISO ts"
#       }
#     ]
#   }
#

SCHEDULER_FORMAT = {
    "source": "",
    "jobs": [],
}

SERVICE_FORMAT = {
    "source": "",
    "services": [],
}


def normalize_scheduler(raw):
    """把任何 adapter 回传的东西洗成标准格式（防御性编程）。"""
    out = dict(SCHEDULER_FORMAT)
    out["source"] = str(raw.get("source") or "unknown")
    jobs = raw.get("jobs") or []
    clean = []
    for j in jobs:
        if not isinstance(j, dict):
            continue
        clean.append({
            "id": str(j.get("id") or j.get("name") or "?"),
            "name": str(j.get("name") or j.get("id") or "?"),
            "schedule": str(j.get("schedule") or ""),
            "enabled": bool(j.get("enabled", True)),
            "last_run": j.get("last_run"),
            "next_run": j.get("next_run"),
            "command": str(j.get("command") or ""),
            "profile": str(j.get("profile") or ""),
        })
    out["jobs"] = clean
    return out


def normalize_service(raw):
    """把任何 adapter 回传的东西洗成标准格式。"""
    out = dict(SERVICE_FORMAT)
    out["source"] = str(raw.get("source") or "unknown")
    svcs = raw.get("services") or []
    clean = []
    for s in svcs:
        if not isinstance(s, dict):
            continue
        clean.append({
            "id": str(s.get("id") or s.get("name") or "?"),
            "name": str(s.get("name") or s.get("id") or "?"),
            "type": str(s.get("type") or "unknown"),
            "up": bool(s.get("up", False)),
            "detail": str(s.get("detail") or ""),
            "checked_at": str(s.get("checked_at") or ""),
        })
    out["services"] = clean
    return out