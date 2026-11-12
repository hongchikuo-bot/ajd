#!/usr/bin/env python3
"""HTTP health adapter — GET 一个 URL，看返回码。

从 projects.json 的 services 定义读 url，检查是否存活。
"""

import urllib.request


def _check(url, timeout=3):
    if not url:
        return False, "no url"
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status < 500, f"HTTP {resp.status}"
    except urllib.error.HTTPError as e:
        return e.code < 500, f"HTTP {e.code}"
    except Exception as e:
        return False, f"HTTP error ({e})"


def discover(services_config=None):
    """services_config: dict of {service_key: {url: "...", desc: "..."}}"""
    svcs = []
    for key, meta in (services_config or {}).items():
        url = meta.get("url")
        up, detail = _check(url)
        svcs.append({
            "id": key,
            "name": meta.get("desc") or key,
            "type": "http",
            "up": up,
            "detail": detail,
            "checked_at": "",
        })
    return {"source": "http", "services": svcs}