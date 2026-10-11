#!/usr/bin/env python3
"""Docker adapter — 检查 docker 容器是否存活。

读 docker container list，比对 projects.json 里登记的 container 名。
"""

import subprocess


def _run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return p.stdout
    except Exception:
        return ""


def _list_containers():
    """回传 {container_name: status}。"""
    out = _run(["docker", "ps", "-a", "--format", "{{.Names}}\t{{.Status}}"])
    result = {}
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split("\t", 1)
        if len(parts) == 2:
            result[parts[0]] = parts[1]
    return result


def discover(services_config=None):
    """services_config: dict of {service_key: {container: "...", desc: "..."}}"""
    containers = _list_containers()
    svcs = []
    for key, meta in (services_config or {}).items():
        name = meta.get("container") or key
        status = containers.get(name, "")
        up = bool(status) and "Up" in status and "Exited" not in status
        svcs.append({
            "id": key,
            "name": meta.get("desc") or key,
            "type": "docker",
            "up": up,
            "detail": status or "container not found",
            "checked_at": "",
        })
    return {"source": "docker", "services": svcs}