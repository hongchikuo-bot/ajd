#!/usr/bin/env python3
"""Hermes cron adapter — 讀 Hermes profile 的 cron jobs。

這支 adapter 也支援 Hermes 系統（通用化的一部分）。
讀 ~/.hermes/cron/jobs.json + 各 profile 的。
"""

import glob
import json
import os
import re


def _load_jobs(path):
    try:
        data = json.load(open(path, encoding="utf-8"))
    except Exception:
        return []
    arr = data.get("jobs", data) if isinstance(data, dict) else data
    if not isinstance(arr, list):
        return []
    out = []
    for j in arr:
        if not isinstance(j, dict):
            continue
        sch = j.get("schedule") or {}
        if isinstance(sch, str):
            sch = {"expr": sch}
        out.append({
            "id": str(j.get("id") or j.get("name") or "?"),
            "name": str(j.get("name") or j.get("id") or "?"),
            "schedule": str(sch.get("expr") or f"{sch.get('kind','')} {sch.get('minutes', sch.get('minute',''))}".strip()),
            "enabled": bool(j.get("enabled", True)),
            "last_run": j.get("last_run") or j.get("last_run_at"),
            "next_run": j.get("next_run") or j.get("next_run_at"),
            "command": str(j.get("prompt") or "")[:300],
            "profile": str(j.get("profile") or ""),
        })
    return out


def discover():
    jobs = []
    home = os.path.expanduser("~")
    paths = [os.path.join(home, ".hermes", "cron", "jobs.json")]
    pdir = os.path.join(home, ".hermes", "profiles")
    if os.path.isdir(pdir):
        for p in sorted(os.listdir(pdir)):
            paths.append(os.path.join(pdir, p, "cron", "jobs.json"))
    for p in paths:
        if not os.path.exists(p):
            continue
        prof = "default"
        m = re.search(r"profiles/([^/]+)/cron", p)
        if m:
            prof = m.group(1)
        for j in _load_jobs(p):
            j["profile"] = j.get("profile") or prof
            jobs.append(j)
    return {"source": "hermes", "jobs": jobs}