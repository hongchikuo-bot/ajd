#!/usr/bin/env python3
"""Port adapter — TCP port 检查。

从 projects.json 的 services 定义读 port，检查是否存活。
"""

import socket


def _check_port(port, timeout=0.6):
    if not port:
        return False, "no port"
    try:
        with socket.create_connection(("127.0.0.1", int(port)), timeout=timeout):
            return True, f"port {port} open"
    except Exception as e:
        return False, f"port {port} closed ({e})"


def discover(services_config=None):
    """services_config: dict of {service_key: {port: N, desc: "..."}}"""
    svcs = []
    for key, meta in (services_config or {}).items():
        port = meta.get("port")
        up, detail = _check_port(port)
        svcs.append({
            "id": key,
            "name": meta.get("desc") or key,
            "type": "port",
            "up": up,
            "detail": detail,
            "checked_at": "",
        })
    return {"source": "port", "services": svcs}