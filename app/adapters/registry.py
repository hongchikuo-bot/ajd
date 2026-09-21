#!/usr/bin/env python3
"""Adapter registry — 动态发现所有可用的 scheduler / service adapters。

用法：
    from adapters import discover_schedulers, discover_services
    scheds = discover_schedulers()
    svcs  = discover_services(registry)
"""

import importlib
import os
from . import normalize_scheduler, normalize_service

ADAPTER_DIR = os.path.dirname(os.path.abspath(__file__))


def _load_module(name):
    """动态载入 adapters/schedulers/xxx.py 或 adapters/services/xxx.py。"""
    try:
        return importlib.import_module(f"adapters.{name}")
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