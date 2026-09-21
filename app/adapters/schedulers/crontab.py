#!/usr/bin/env python3
"""Crontab adapter — 读 /etc/crontab + 用户 crontab (crontab -l)。

macOS 没有 /etc/crontab（用 launchd），Linux 有。
两边都试试，有就报。
"""

import os
import re
import subprocess


def _run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return p.stdout
    except Exception:
        return ""


def _parse_crontab(text, source, profile=""):
    """把 crontab 文本拆成 job 列表。"""
    jobs = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # 跳过环境变量设定（VAR=value）
        if "=" in line and not re.match(r"^[\d*/,#\s-]+\s", line):
            continue
        # 匹配 cron 表达式开头（5 或 6 段）
        m = re.match(
            r"^([\d*/,#\s-]+(?:\d+/\d+)?(?:\s+[\d*/,#\s-]+)*)\s+(.+)$", line
        )
        if not m:
            continue
        schedule = m.group(1).strip()
        command = m.group(2).strip()
        # 去掉前面的 user 字段（/etc/crontab 格式：min hr dom mon dow user cmd）
        parts = command.split()
        if len(parts) >= 6 and parts[0].isdigit() is False:
            # 粗略判断：如果第 1 个 token 看起来像用户名（不含 / 且非数字）
            if not parts[0].startswith("/") and not parts[0].isdigit():
                command = " ".join(parts[1:])
        # 生成 id
        jid = re.sub(r"[^a-zA-Z0-9_]", "_", command[:60])
        jobs.append({
            "id": f"{source}_{jid}",
            "name": command.split("/")[-1][:60] if "/" in command else command[:60],
            "schedule": schedule,
            "enabled": True,
            "last_run": None,        # crontab 不记录 last_run
            "next_run": None,
            "command": command,
            "profile": profile,
        })
    return jobs


def discover():
    jobs = []
    # /etc/crontab
    etc = _run(["cat", "/etc/crontab"])
    if etc:
        jobs.extend(_parse_crontab(etc, "crontab_etc"))
    # 用户 crontab
    user_cron = _run(["crontab", "-l"])
    if user_cron:
        jobs.extend(_parse_crontab(user_cron, "crontab_user"))
    return {"source": "crontab", "jobs": jobs}