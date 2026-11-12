#!/usr/bin/env python3
"""AJD adapter layer — 把各种排程/服务来源转成统一格式。

核心只认统一格式，不关心底层是 crontab、launchd、systemd 还是 Hermes。
每个 adapter 实现 discover() -> dict，回传标准结构。
"""

from .registry import discover_schedulers, discover_services
from .registry import normalize_scheduler, normalize_service

__all__ = [
    "discover_schedulers",
    "discover_services",
    "normalize_scheduler",
    "normalize_service",
]