#!/usr/bin/env python3
"""AJD 的資料收集器。

每天（或隨時）掃一次所有專案，把「會變的事實」寫成一份快照：
    data/snapshots/YYYY-MM-DD.json

為什麼用快照而不是即時查：
  - 歷史 = 快照的序列。有了每日快照，才能回答「這週推進了什麼」。
  - 只有 4 個專案有 git，所以歷史不能靠 git log，要靠這個。
  - 面板只讀快照 → 與生產線完全解耦（面板掛了不影響任何產線）。

只讀不寫：這支程式不碰任何專案檔案，只讀檔名/時間/大小與 cron 設定。
"""

import json
import os
import re
import socket
import subprocess
import sys
import time
from datetime import datetime, timezone, timedelta

HOME = os.path.expanduser("~")
# AJD_HOME: 安裝目錄（內含 harvest.py / data / projects.json）
# 預設值 = harvest.py 所佢所在目錄，安裝腳本會設成 ~/root/ajd/
DASH = os.environ.get("AJD_HOME") or os.path.dirname(os.path.abspath(__file__))

# ROOT：專案根目錄（用於尋找使用者自己的專案）
ROOT = os.path.join(HOME, "root")

# DEMO_ROOT：demo 環境中的專案根（當沒有設定 AJD_HOME 時fallback）
DEMO_ROOT = DASH

SNAP_DIR = os.path.join(DASH, "data", "snapshots")
REGISTRY = os.path.join(DASH, "projects.json")

# 掃描時跳過的目錄（大又無意義）
SKIP_DIRS = {"venv", ".venv", "node_modules", ".git", "__pycache__", ".mypy_cache",
             ".pytest_cache", "dist", "build", ".next", ".cache", ".DS_Store"}
MAX_DEPTH = 4
TW = timezone(timedelta(hours=8))


def now_tw():
    return datetime.now(TW)


def scan_project(path, max_files=20000):
    """掃一個專案目錄（或單一檔案）→ 檔案活動事實。"""
    if os.path.isfile(path):
        st = os.stat(path)
        age = (time.time() - st.st_mtime) / 3600
        return {"files": {"1d": int(age <= 24), "7d": int(age <= 168),
                          "30d": int(age <= 720), "total": 1},
                "size": f"{st.st_size / 1024:.0f}K",
                "newest": {"path": os.path.basename(path)[:120],
                           "mtime": datetime.fromtimestamp(st.st_mtime, TW).strftime("%m/%d %H:%M")},
                "newest_age_hours": round(age, 1)}
    buckets = {"1d": 0, "7d": 0, "30d": 0, "total": 0}
    newest = None
    size = 0
    now = time.time()
    for dirpath, dirnames, filenames in os.walk(path):
        depth = dirpath[len(path):].count(os.sep)
        if depth >= MAX_DEPTH:
            dirnames[:] = []
            continue
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            if fn.startswith(".") and fn not in (".env",):
                continue
            fp = os.path.join(dirpath, fn)
            try:
                st = os.stat(fp)
            except OSError:
                continue
            buckets["total"] += 1
            age = now - st.st_mtime
            if age <= 86400:
                buckets["1d"] += 1
            if age <= 7 * 86400:
                buckets["7d"] += 1
            if age <= 30 * 86400:
                buckets["30d"] += 1
            size += st.st_size
            if newest is None or st.st_mtime > newest[1]:
                newest = (os.path.relpath(fp, path), st.st_mtime)
            if buckets["total"] >= max_files:
                break
        if buckets["total"] >= max_files:
            break

    def fmt_size(n):
        for unit in ("B", "K", "M", "G"):
            if n < 1024:
                return f"{n:.0f}{unit}"
            n /= 1024
        return f"{n:.0f}T"

    out = {
        "files": buckets,
        "size": fmt_size(size),
        "newest": None,
        "newest_age_hours": None,
    }
    if newest:
        out["newest"] = {"path": newest[0][:120],
                         "mtime": datetime.fromtimestamp(newest[1], TW).strftime("%m/%d %H:%M")}
        out["newest_age_hours"] = round((now - newest[1]) / 3600, 1)
    return out


def git_facts(path):
    if not os.path.isdir(os.path.join(path, ".git")):
        return None
    try:
        n = subprocess.run(["git", "-C", path, "rev-list", "--count", "HEAD"],
                           capture_output=True, text=True, timeout=10).stdout.strip()
        last = subprocess.run(["git", "-C", path, "log", "-1", "--format=%cd|%s", "--date=format:%m/%d"],
                              capture_output=True, text=True, timeout=10).stdout.strip()
        dirty = subprocess.run(["git", "-C", path, "status", "--porcelain"],
                               capture_output=True, text=True, timeout=10).stdout.strip()
        date, _, subj = last.partition("|")
        return {"commits": int(n or 0), "last": date, "last_subject": subj[:80],
                "uncommitted": len([l for l in dirty.splitlines() if l.strip()])}
    except Exception:
        return None


def port_alive(port):
    if not port:
        return None
    with socket.socket() as s:
        s.settimeout(1.0)
        return s.connect_ex(("127.0.0.1", int(port))) == 0


def load_cron_jobs():
    """收集系統 + 所有 profile 的排程。"""
    jobs = []
    paths = [os.path.join(HOME, ".hermes", "cron", "jobs.json")]
    pdir = os.path.join(HOME, ".hermes", "profiles")
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
        try:
            data = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arr = data.get("jobs", data) if isinstance(data, dict) else data
        for j in arr if isinstance(arr, list) else []:
            sch = j.get("schedule") or {}
            if isinstance(sch, str):
                sch = {"expr": sch}
            jobs.append({
                "profile": prof,
                "name": j.get("name") or j.get("id", "?"),
                "schedule": sch.get("expr") or f"{sch.get('kind','')} {sch.get('minutes', sch.get('minute',''))}".strip(),
                "enabled": j.get("enabled", True),
                "last_run": j.get("last_run") or j.get("last_run_at"),
                "next_run": j.get("next_run") or j.get("next_run_at"),
                "prompt": (j.get("prompt") or "")[:300],
            })
    return jobs


def attribute_jobs(projects, jobs):
    """排程歸屬到專案。

    2026-09-20：原本只用關鍵字模糊比對，結果某專案的排程因為 prompt 裡
    提到 <USER_PROJECT>/<example>/ 就被算成新聞產線（先掃到的贏）。改成：
      1) 先看 prompt 裡的工作目錄 /root/<專案>/ —— 這是最精準的歸屬依據
      2) 沒有目錄才退回關鍵字
      3) 都對不上的收進「未歸屬」，寧可露出來也不要藏起來
    """
    by_proj = {k: [] for k in projects}
    by_proj["_unattributed"] = []
    for j in jobs:
        blob = (j["name"] + " " + j["prompt"]).lower()

        # 1) 工作目錄優先
        hit = None
        for d in re.findall(r"/root/([a-z0-9_\-]+)", blob):
            if d in projects:
                hit = d
                break

        # 2) 退回關鍵字
        if not hit:
            for key, meta in projects.items():
                kws = [key.lower(), meta.get("name", "").lower()]
                kws += [w for w in re.split(r"[_\-\s]+", key) if len(w) > 3]
                # 名稱也要拆詞（「在地通 <USER_PROJECT>」→「在地通」）
                kws += [w for w in re.split(r"[_\-\s\.]+", meta.get("name", "").lower()) if len(w) > 1]
                kws += [k.lower() for k in meta.get("keywords") or []]
                if any(k and k in blob for k in kws):
                    hit = key
                    break

        by_proj[hit or "_unattributed"].append(j)
    return by_proj


def infer_status(meta, facts):
    """把事實翻成一句人看得懂的話 + 一個燈號。"""
    ptype = meta.get("type")
    age = facts.get("newest_age_hours")
    alive = facts.get("port_alive")

    if ptype == "服務":
        if alive:
            return "green", "運行中"
        return "red", "未啟動"
    if age is None:
        return "grey", "無活動紀錄"
    if age <= 6:
        return "green", f"{age:.0f} 小時內有動"
    if age <= 24:
        return "green", "今天有動"
    if age <= 48:
        return "yellow", "昨天有動"
    days = age / 24
    if days <= 7:
        return "yellow", f"停滯 {days:.0f} 天"
    return "red", f"停滯 {days:.0f} 天"


def main():
    reg = json.load(open(REGISTRY, encoding="utf-8"))
    projects = reg["projects"]
    jobs = load_cron_jobs()
    job_map = attribute_jobs(projects, jobs)

    snap = {
        "date": now_tw().strftime("%Y-%m-%d"),
        "generated_at": now_tw().strftime("%Y-%m-%d %H:%M:%S"),
        "projects": {},
        "services": {},
        "cron_total": len(jobs),
    }

    for name, meta in projects.items():
        # 專案可能由多個路徑組成（例如維運散在 ~/root/bin 與 ~/.hermes/scripts）
        raw = meta.get("paths")
        if raw:
            paths = [os.path.expanduser(raw[0])] if isinstance(raw, list) else [raw]
        else:
            paths = [os.path.join(ROOT, name)]
        
        # demo 環境 fallback：當沒有 AJD_HOME 或路徑不存在時，搜尋 /tmp/ajd-demo/root/*
        if not os.path.exists(paths[0]):
            dash_root = "/tmp/ajd-demo/root"
            search_pattern = f"{dash_root}/{name.lstrip('/')}"
            # 直接檢查 demo fallback 目錄
            if os.path.exists(search_pattern):
                paths = [search_pattern]

        paths = [x for x in paths if os.path.exists(x)]
        if not paths:
            if "paths" in meta:
                # 明確宣告「這個工作沒有自己的檔案」（例如只剩排程的空殼）
                # → 仍要追蹤，否則它的排程會在面板上憑空消失
                snap["projects"][name] = {
                    "exists": True, "no_files": True, "meta": meta,
                    "files": {"1d": 0, "7d": 0, "30d": 0, "total": 0}, "size": "—",
                    "newest": None, "newest_age_hours": None, "git": None, "docs": [],
                    "jobs": job_map.get(name, []),
                    "level": meta.get("empty_level") or ("grey" if meta.get("remote") else "red"),
                    "status": meta.get("empty_status") or "空殼（無程式檔）",
                }
                continue
            snap["projects"][name] = {"exists": False, "meta": meta}
            continue
        path = paths[0]

        # 多路徑要合併（維運散在 ~/root/bin 與 ~/.hermes/scripts）
        facts = scan_project(paths[0])
        for extra in paths[1:]:
            e = scan_project(extra)
            for k in ("1d", "7d", "30d", "total"):
                facts["files"][k] += e["files"][k]
            if e["newest_age_hours"] is not None and (
                    facts["newest_age_hours"] is None or e["newest_age_hours"] < facts["newest_age_hours"]):
                facts["newest"] = e["newest"]
                facts["newest_age_hours"] = e["newest_age_hours"]
        facts["exists"] = True
        facts["meta"] = meta
        facts["git"] = git_facts(path) if os.path.isdir(path) else None
        docs = [f for f in ("PLAN.md", "README.md", "TODO.md", "DATA_MAP.md")
                if os.path.isdir(path) and os.path.exists(os.path.join(path, f))]
        facts["docs"] = docs
        if meta.get("port"):
            facts["port_alive"] = port_alive(meta["port"])
        facts["jobs"] = job_map.get(name, [])
        level, text = infer_status(meta, facts)
        facts["level"], facts["status"] = level, text
        snap["projects"][name] = facts

    for name, meta in reg.get("services", {}).items():
        snap["services"][name] = {"port": meta["port"], "desc": meta["desc"],
                                  "alive": bool(port_alive(meta["port"]))}

    os.makedirs(SNAP_DIR, exist_ok=True)
    out = os.path.join(SNAP_DIR, f"{snap['date']}.json")
    json.dump(snap, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print(f"✅ 快照寫入 {out}")
    print(f"   專案 {len(snap['projects'])} 個｜排程 {len(jobs)} 個")
    for name, f in snap["projects"].items():
        if not f.get("exists"):
            print(f"   ❌ {name}: 目錄不存在")
            continue
        icon = {"green": "🟢", "yellow": "🟡", "red": "🔴", "grey": "⚪"}[f["level"]]
        print(f"   {icon} {name:26s} {f['status']:14s} 近7天 {f['files']['7d']:4d} 檔")
    print("   服務:", ", ".join(f"{k}{'✅' if v['alive'] else '❌'}" for k, v in snap["services"].items()))

    # 自動提交（2026-09-20）：快照與想法都要有版本歷史。
    # 想法是使用者親自交代「記住就好」的東西 —— 不能只存在一個檔案裡。
    try:
        subprocess.run(["git", "add", "-A"], cwd=DASH, capture_output=True, timeout=60)
        subprocess.run(["git", "commit", "-q", "-m",
                        f"快照 {snap['date']}（{len([1 for f in snap['projects'].values() if f.get('exists')])} 專案）"],
                       cwd=DASH, capture_output=True, timeout=60)
    except Exception as e:
        print(f"   ⚠️ git 提交失敗（不影響快照）: {e}")


if __name__ == "__main__":
    main()
