#!/usr/bin/env python3
"""Adapter registry — 动态发现所有可用的 scheduler / service adapters。

用法：
    from adapters import discover_schedulers, discover_services
    scheds = discover_schedulers()
    svcs  = discover_services(registry)
"""

import importlib
import os


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


ADAPTER_DIR = os.path.dirname(os.path.abspath(__file__))

# Determine the package name dynamically for relative imports
# This works whether imported as `from adapters import registry` (package="adapters")
# or `from app.adapters import registry` (package="app.adapters")
_REGISTRY_PACKAGE = __package__ or "adapters"
if _REGISTRY_PACKAGE.endswith(".registry"):
    _REGISTRY_PACKAGE = _REGISTRY_PACKAGE[:-9]  # remove ".registry"


def _load_module(name):
    """動態載入 adapters/schedulers/xxx.py 或 adapters/services/xxx.py。"""
    try:
        return importlib.import_module(f".{name}", package=_REGISTRY_PACKAGE)
    except Exception:
        return None


def discover_schedulers():
    """跑所有 scheduler adapter，回传合并后的标准格式列表。"""
    results = []
    sched_dir = os.path.join(ADAPTER_DIR, "schedulers")
    if not os.path.isdir(sched_dir):
        return results
    for fn in sorted(os.listdir(sched_dir)):
        if not fn.endswith(".py") or fn.startswith("_") or fn.startswith("."):
            continue
        mod_name = fn[:-3]
        mod = _load_module(f"schedulers.{mod_name}")
        if not mod or not hasattr(mod, "discover"):
            continue
        try:
            raw = mod.discover()
            results.append(normalize_scheduler(raw))
        except Exception as e:
            results.append({
                "source": mod_name,
                "jobs": [],
                "error": str(e),
            })
    return results


def discover_services(registry):
    """跑所有 service adapter，回传合并后的标准格式列表。

    registry: 从 projects.json 读的完整 registry（含 services 定义）。
    """
    results = []
    svc_dir = os.path.join(ADAPTER_DIR, "services")
    if not os.path.isdir(svc_dir):
        return results
    svc_config = (registry or {}).get("services") or {}
    for fn in sorted(os.listdir(svc_dir)):
        if not fn.endswith(".py") or fn.startswith("_") or fn.startswith("."):
            continue
        mod_name = fn[:-3]
        mod = _load_module(f"services.{mod_name}")
        if not mod or not hasattr(mod, "discover"):
            continue
        try:
            raw = mod.discover(svc_config)
            results.append(normalize_service(raw))
        except Exception as e:
            results.append({
                "source": mod_name,
                "services": [],
                "error": str(e),
            })
    return results