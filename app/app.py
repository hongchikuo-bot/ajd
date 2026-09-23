#!/usr/bin/env python3
"""AJD dashboard — 監控你的 AI agents、排程與服務。

設計原則（刻意如此）：
  - **只讀**：面板不插在生產線上，面板掛了不影響任何產線。
  - **不重複真實來源**：資料全部來自快照档 + ideas.jsonl,不在面板裡另存一份。
  - **手機優先**：行动裝置操作。
"""

import glob
import json
import os
import re
import secrets
from datetime import datetime, timedelta, timezone

from flask import send_from_directory, Flask, jsonify, request, render_template, redirect, Response

HOME = os.path.expanduser("~")
# AJD_HOME: 安裝目錄（內含 app.py / static / templates / data / projects.json）
# 預設值 = app.py 所在目錄，安裝腳本會設成 ~/root/ajd/
DASH = os.environ.get("AJD_HOME") or os.path.dirname(os.path.abspath(__file__))
SNAP_DIR = os.path.join(DASH, "data", "snapshots")
IDEAS_FILE = os.path.join(DASH, "data", "ideas.jsonl")
BACKLOG_FILE = os.path.join(DASH, "data", "backlog.json")
REGISTRY = os.path.join(DASH, "projects.json")
PORT = int(os.environ.get("AJD_PORT", "5080"))
TW = timezone(timedelta(hours=8))

# 認證開關：通用版預設關閉（AJD_AUTH_REQUIRED=true 才開啟）
# 私人版若架在公開網址需設為 true
AUTH_REQUIRED = os.environ.get("AJD_AUTH_REQUIRED", "false").lower() == "true"

app = Flask(__name__)

# 開發期間一直在改 UI → 不要讓浏览器或 Flask 自己端出舊版（2026-09-20）。
# 症狀：改了 index.html / style.css，畫面卻還是舊的。
app.config["TEMPLATES_AUTO_RELOAD"] = True        # 模板改了就重編，不用重啟
app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0       # 靜態檔不快取


# ── 心跳回報（heartbeat）────────────────────────────────────
# 概念借自 uptime-kuma 的 "Push" 監控：
#   不要用「檔案時間」去猜排程有沒有跑完（那個會誤判），
#   讓每個排程**跑完主動回報**「我做完了 / 我失敗了」。
#
# 用法（任何腳本都可以打）：
#   curl -X POST "http://127.0.0.1:5080/api/heartbeat?k=<token>" \
#        -H 'Content-Type: application/json' \
#        -d '{"job":"daily_news_build","status":"ok","note":"3.1MB"}'
HEARTBEAT_FILE = os.path.join(DASH, "data", "heartbeats.jsonl")
HB_ALLOWED = ("ok", "fail", "warn")


HEARTBEAT_MAP_FILE = os.path.join(DASH, "data", "heartbeat_map.json")


def with_aliases(hbs):
    """讓心跳也能用「cron 排程名稱」查到。

    腳本回報用 id（daily_news_build），cron 排程叫中文顯示名
    （每日新聞影片 階段一: …）—— 兩邊名字不同就對不起來，所以要對照表。
    """
    try:
        m = json.load(open(HEARTBEAT_MAP_FILE, encoding="utf-8"))
    except Exception:
        return hbs
    out = dict(hbs)
    for hid, cron_name in m.items():
        if hid.startswith("_") or not cron_name:
            continue
        if hid in hbs and cron_name not in out:
            out[cron_name] = hbs[hid]
    return out


def load_heartbeats(keep=400):
    """回傳 {job: 最後一筆}，另外帶最近 keep 筆的歷史。"""
    latest, rows = {}, []
    try:
        with open(HEARTBEAT_FILE, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                rows.append(r)
                j = r.get("job")
                if j and (j not in latest or (r.get("ts") or "") > (latest[j].get("ts") or "")):
                    latest[j] = r
    except OSError:
        pass
    return latest, rows[-keep:]


@app.route("/api/heartbeat", methods=["POST"])
def api_heartbeat():
    """排程跑完主動回報。認證用 ?k=<token> 或 X-Dash-Token 標頭（不轉址，POST 才不會掉）。"""
    # 通用版預設不需要認證（AJD_AUTH_REQUIRED=true 才開啟）
    if AUTH_REQUIRED:
        tok = access_token()
        given = (request.args.get("k") or request.headers.get("X-Dash-Token")
                 or request.cookies.get("dash_k"))
        if not tok or given != tok:
            return jsonify({"ok": False, "error": "unauthorized"}), 401

    data = request.get_json(silent=True) or {}
    job = str(data.get("job") or "").strip()
    if not job:
        return jsonify({"ok": False, "error": "job required"}), 400
    status = str(data.get("status") or "ok").strip().lower()
    if status not in HB_ALLOWED:
        status = "warn"

    rec = {
        "ts": datetime.now().astimezone().isoformat(timespec="seconds"),
        "job": job,
        "status": status,
        "note": str(data.get("note") or "")[:300],
        "project": str(data.get("project") or "")[:60],
        "duration_s": data.get("duration_s"),
    }
    os.makedirs(os.path.dirname(HEARTBEAT_FILE), exist_ok=True)
    with open(HEARTBEAT_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    return jsonify({"ok": True, "recorded": rec})


# ── app 模式（PWA）──────────────────────────────────────────
# service worker 一定要從**根目錄**提供，否則它的控制範圍只到自己所在的資料夾，
# 掛在 /static/sw.js 就只能管 /static/，整個 app 模式會失效。
@app.route("/sw.js")
def _sw():
    resp = send_from_directory(os.path.join(DASH, "static"), "sw.js",
                               mimetype="application/javascript")
    resp.headers["Service-Worker-Allowed"] = "/"
    resp.headers["Cache-Control"] = "no-cache"
    return resp


@app.route("/manifest.webmanifest")
def _manifest():
    return send_from_directory(os.path.join(DASH, "static"), "manifest.webmanifest",
                               mimetype="application/manifest+json")


@app.after_request
def _no_cache(resp):
    """這個面板一直在演進 → 一律要求瀏覽器每次回來拿最新的。"""
    # 用 no-cache 而不是 no-store：
    #   no-cache   = 每次都要回伺服器確認（改了馬上看到 ✅）
    #   no-store   = 完全不准存 → service worker 的 cache.put 會被拒，
    #                app 模式（PWA）就裝不起來。所以不能用 no-store。
    resp.headers["Cache-Control"] = "no-cache, must-revalidate, max-age=0"
    resp.headers["Pragma"] = "no-cache"
    return resp

# ── 存取鎖 (2026-09-20) ──────────────────────────────────
# 這個面板掛在公開的 trycloudflare 網址上, 內容包含商業想法與專案細節,
# 所以預設一律擋掉, 只有帶著專屬連結 (?k=<token>) 進來的人能看。
# 用法: 給使用者的連結長這樣 → https://<tunnel>/?k=<token>
#       點一次之後浏览器會記住 cookie, 之後直接開網址就好。
TOKEN_FILE = os.path.join(DASH, "data", "access_token.txt")


def access_token():
    if os.path.exists(TOKEN_FILE):
        t = open(TOKEN_FILE).read().strip()
        if t:
            return t
    t = secrets.token_urlsafe(18)
    os.makedirs(os.path.dirname(TOKEN_FILE), exist_ok=True)
    with open(TOKEN_FILE, "w") as f:
        f.write(t)
    os.chmod(TOKEN_FILE, 0o600)
    return t


@app.before_request
def _gate():
    # 通用版預設不需要認證（AJD_AUTH_REQUIRED=true 才開啟）
    if not AUTH_REQUIRED:
        return None

    tok = access_token()
    # app 模式（PWA）需要的檔案不含敏感資料（圖示 + 一個名稱設定），
    # 而且瀏覽器抓它們是背景請求 —— 必須放行，否則 service worker 裝不起來。
    if (request.path.startswith("/static/")
            or request.path in ("/sw.js", "/manifest.webmanifest")
            # 心跳端點自己驗證（它必須接受 POST，不能走「轉址種 cookie」那條路）
            or request.path == "/api/heartbeat"):
        return None
    if request.args.get("k") == tok:                       # 專屬連結 → 種 cookie 後轉正
        resp = redirect(request.path)
        resp.set_cookie("dash_k", tok, max_age=31536000, samesite="Lax")
        return resp
    if request.cookies.get("dash_k") == tok:
        return None
    # 需要授權 → 給一個可以「貼上專屬代碼」的小頁面。
    # 為什麼需要：手機把這個網頁「加到主畫面」變成 app 之後，
    # iOS 的 app 有**自己的 cookie 空間**（跟 Safari 分開），
    # 所以第一次在 app 裡開啟時會是未授權 → 讓他在 app 裡貼一次就好。
    page = """<!DOCTYPE html><html lang="zh-TW"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#0b0f15">
<title>AJD · 需要授權</title>
<style>
 :root{color-scheme:light dark}
 body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
      background:#f5f7fb;color:#141a24;font:16px -apple-system,system-ui,sans-serif;padding:24px}
 @media (prefers-color-scheme:dark){body{background:#0b0f15;color:#f4f7fb}}
 .box{max-width:380px;width:100%%}
 h1{font-size:1.1rem;margin:0 0 6px}
 p{font-size:.86rem;opacity:.75;line-height:1.6;margin:0 0 16px}
 input{width:100%%;box-sizing:border-box;padding:12px 14px;font-size:16px;border-radius:10px;
       border:1px solid #c3cbd8;background:transparent;color:inherit}
 @media (prefers-color-scheme:dark){input{border-color:#44536a}}
 button{margin-top:12px;width:100%%;padding:13px;font-size:1rem;border:0;border-radius:10px;
        background:#3b82f6;color:#fff;font-weight:600}
 .err{color:#e5484d;font-size:.84rem;margin-top:10px;min-height:1.2em}
</style></head><body><div class="box">
 <h1>🛰 AJD</h1>
 <p>這是鎖起來的面板。貼上你的專屬代碼就能進去（貼一次就好，之後會記住）。</p>
 <form method="get" action="__PATH__">
   <input name="k" placeholder="貼上專屬代碼" autocomplete="off" autocapitalize="off" spellcheck="false" autofocus>
   <button type="submit">進入</button>
 </form>
 <div class="err">__ERR__</div>
</div></body></html>"""
    # API 一律維持 401（JSON 前端才不會把登入頁當成資料）
    if request.path.startswith("/api/"):
        return Response("需要授權\n", 401, mimetype="text/plain; charset=utf-8")

    err = "代碼不對。" if request.args.get("k") else ""
    html = page.replace("__PATH__", request.path).replace("__ERR__", err)
    # 網頁本身用 200 回這個登入頁，而不是 401：
    #   Chrome 的「安裝 app」檢查會去抓 start_url（/），回 401 會判定不能安裝。
    #   這一頁沒有機密（只有一個輸入框），真正的資料都在 /api/* 後面（那裡仍是 401）。
    return Response(html, 200, mimetype="text/html")

IDEA_STATUS = ["new", "thinking", "started", "shelved", "done"]
IDEA_LABEL = {"new": "🆕 新想法", "thinking": "🤔 考慮中", "started": "🚀 已開案",
              "shelved": "📦 擱置", "done": "✅ 完成"}
LEVEL_ICON = {"green": "🟢", "yellow": "🟡", "red": "🔴", "grey": "⚪"}


# ── 資料讀取 ────────────────────────────────────────────────
def resolve_links(links):
    """出入口。標了 src 的是『臨時網址』—— 每次請求都去檔案裡抓最新的，
    因為 trycloudflare 的網址每次 tunnel 重啟都會變。"""
    out = []
    for lk in links or []:
        lk = dict(lk)
        if lk.get("src"):
            url = None
            try:
                txt = open(os.path.expanduser(lk["src"]), encoding="utf-8", errors="ignore").read()
                found = re.findall(r"https://[a-z0-9-]+\.trycloudflare\.com", txt)
                if found:
                    url = found[-1]
            except Exception:
                pass
            lk["url"] = url
            lk["tmp"] = True
            if not url:
                lk["note"] = "讀不到臨時網址（tunnel 可能沒在跑）"
        out.append(lk)
    return out


def port_open(port, timeout=0.6):
    """即時檢查服務是否活著。快照一天只收兩次，服務狀態太舊就沒意義。"""
    import socket
    if not port:
        return False
    try:
        with socket.create_connection(("127.0.0.1", int(port)), timeout=timeout):
            return True
    except Exception:
        return False


def load_snapshots(limit=60):
    files = sorted(glob.glob(os.path.join(SNAP_DIR, "*.json")))
    out = []
    for f in files[-limit:]:
        try:
            out.append(json.load(open(f, encoding="utf-8")))
        except Exception:
            pass
    return out


def load_registry():
    return json.load(open(REGISTRY, encoding="utf-8"))


LOG_KINDS = ["idea", "research", "progress", "blocker", "decision", "concept"]
LOG_LABEL = {"idea": "最初想法", "research": "🔍 研究", "progress": "📈 進展",
             "blocker": "⛔ 卡住", "decision": "⚖️ 決策", "concept": "📄 構想書"}


def load_ideas():
    """讀想法。每筆都保證有 log（時間軸）—— 舊資料的 note 會自動變成第一筆研究紀錄。"""
    if not os.path.exists(IDEAS_FILE):
        return []
    ideas = []
    for line in open(IDEAS_FILE, encoding="utf-8"):
        line = line.strip()
        if line:
            try:
                ideas.append(json.loads(line))
            except Exception:
                pass
    for i in ideas:
        if not i.get("log"):
            i["log"] = []
            if i.get("note"):
                i["log"].append({"ts": i.get("ts", ""), "kind": "research", "text": i["note"]})
            else:
                i["log"].append({"ts": i.get("ts", ""), "kind": "idea", "text": "(最初只有想法，尚無記錄)"})
    ideas.sort(key=lambda x: x.get("ts", ""), reverse=True)
    return ideas


def save_ideas(ideas):
    os.makedirs(os.path.dirname(IDEAS_FILE), exist_ok=True)
    with open(IDEAS_FILE, "w", encoding="utf-8") as f:
        for i in ideas:
            f.write(json.dumps(i, ensure_ascii=False) + "\n")


def add_idea(text, tags=None):
    ideas = load_ideas()
    now = datetime.now(TW)
    iid = now.strftime("%Y%m%d-%H%M%S")
    while any(i["id"] == iid for i in ideas):
        iid += "x"
    ideas.append({"id": iid, "ts": now.strftime("%Y-%m-%d %H:%M"), "text": text,
                  "status": "new", "tags": tags or [], "note": ""})
    save_ideas(ideas)
    return iid


def history_diffs(snaps):
    """把快照序列變成「每天每個專案動了什麼」。"""
    out = []
    for i in range(1, len(snaps)):
        prev, cur = snaps[i - 1], snaps[i]
        changes = []
        for name, f in cur.get("projects", {}).items():
            p = prev.get("projects", {}).get(name)
            if not p or not f.get("exists"):
                continue
            # 確保前一個快照也有 files 結構
            if not p.get("files"):
                continue
            d7 = f["files"]["7d"] - p["files"]["7d"]
            d1 = f["files"]["1d"] - p["files"]["1d"]
            new_files = f["files"]["total"] - p["files"]["total"]
            st_changed = p.get("status") != f.get("status")
            git_new = 0
            if f.get("git") and p.get("git"):
                git_new = f["git"]["commits"] - p["git"]["commits"]
            if d1 or new_files or st_changed or git_new:
                changes.append({"project": name, "new_files": new_files,
                                "files_today": f["files"]["1d"], "git_new": git_new,
                                "status": f.get("status"), "status_changed": st_changed,
                                "prev_status": p.get("status")})
        out.append({"date": cur["date"], "changes": changes,
                    "generated_at": cur.get("generated_at")})
    out.reverse()
    return out


# ── 路由 ────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/state")
def api_state():
    snaps = load_snapshots()
    reg = load_registry()
    latest = snaps[-1] if snaps else {"projects": {}, "services": {}}
    return jsonify({
        "latest": latest,
        "prev": snaps[-2] if len(snaps) > 1 else None,
        "snapshot_count": len(snaps),
        "ideas": load_ideas(),
        "idea_label": IDEA_LABEL,
        "log_label": LOG_LABEL,
        "idea_status": IDEA_STATUS,
        "level_icon": LEVEL_ICON,
        "registry": reg,
        "history": history_diffs(snaps)[:14],
        "heartbeats": with_aliases(load_heartbeats()[0]),
    })


@app.route("/api/project/<name>")
def api_project(name):
    snaps = load_snapshots()
    reg = load_registry()
    meta = reg["projects"].get(name)
    if not meta:
        return jsonify({"error": "unknown project"}), 404
    series = []
    for s in snaps[-30:]:
        f = s.get("projects", {}).get(name)
        if f and f.get("exists"):
            series.append({"date": s["date"], "files_1d": f["files"]["1d"],
                           "files_7d": f["files"]["7d"], "status": f.get("status"),
                           "level": f.get("level")})
    latest = snaps[-1].get("projects", {}).get(name) if snaps else None
    prev = snaps[-2].get("projects", {}).get(name) if len(snaps) > 1 else None

    # 這個專案負責的服務（port / 是否活著）
    svc_meta = reg.get("services") or {}
    services = []
    for sk in meta.get("services", []):
        info = svc_meta.get(sk, {})
        services.append({"key": sk, "port": info.get("port"), "desc": info.get("desc"),
                         "up": port_open(info.get("port"))})

    return jsonify({
        "name": name, "meta": meta, "latest": latest, "prev": prev, "series": series,
        "services": services,
        "depends_on": meta.get("depends_on", []),
        "entry": meta.get("entry", {}),
        "backlog": _load_backlog().get(name, []),
        "links": resolve_links(meta.get("links")),
    })


@app.route("/api/ideas", methods=["GET", "POST"])
def api_ideas():
    if request.method == "POST":
        data = request.get_json(force=True, silent=True) or {}
        text = (data.get("text") or "").strip()
        if not text:
            return jsonify({"error": "empty"}), 400
        iid = add_idea(text, data.get("tags"))
        return jsonify({"ok": True, "id": iid})
    return jsonify(load_ideas())


@app.route("/api/idea/<iid>", methods=["POST"])
def api_idea_update(iid):
    data = request.get_json(force=True, silent=True) or {}
    ideas = load_ideas()
    for i in ideas:
        if i["id"] == iid:
            if data.get("status") in IDEA_STATUS:
                i["status"] = data["status"]
            if "note" in data:
                i["note"] = data["note"]
            if "text" in data and data["text"].strip():
                i["text"] = data["text"].strip()
            save_ideas(ideas)
            return jsonify({"ok": True, "idea": i})
    return jsonify({"error": "not found"}), 404


@app.route("/api/idea/<iid>/log", methods=["POST"])
def api_idea_log(iid):
    """在想法下面追加一筆紀錄（研究 / 進展 / 卡住 / 決策 / 構想書）。
    2026-09-20：有新研究或新進展就要標在下面，點選可看結論與狀態。"""
    data = request.get_json(force=True, silent=True) or {}
    text = (data.get("text") or "").strip()
    if not text:
        return jsonify({"error": "empty"}), 400
    kind = data.get("kind") if data.get("kind") in LOG_KINDS else "progress"
    ideas = load_ideas()
    for i in ideas:
        if i["id"] == iid:
            i.setdefault("log", []).append(
                {"ts": datetime.now(TW).strftime("%Y-%m-%d %H:%M"), "kind": kind, "text": text})
            save_ideas(ideas)
            return jsonify({"ok": True, "logs": len(i["log"])})
    return jsonify({"error": "not found"}), 404


@app.route("/api/idea/<iid>/delete", methods=["POST"])
def api_idea_delete(iid):
    ideas = [i for i in load_ideas() if i["id"] != iid]
    save_ideas(ideas)
    return jsonify({"ok": True})


@app.route("/api/harvest", methods=["POST"])
def api_harvest():
    """手動觸發一次收集（懶得等排程時用）。"""
    import subprocess, sys
    p = subprocess.run([sys.executable, os.path.join(DASH, "harvest.py")],
                       capture_output=True, text=True, timeout=180)
    return jsonify({"ok": p.returncode == 0, "out": p.stdout[-2000:], "err": p.stderr[-500:]})



# ── 專案頁（2026-09-20：每個專案要能看到「做了什麼 + 持續工作 + 還沒做」）──
def _load_backlog():
    if not os.path.exists(BACKLOG_FILE):
        return {}
    try:
        return json.load(open(BACKLOG_FILE, encoding="utf-8"))
    except Exception:
        return {}


def _save_backlog(b):
    json.dump(b, open(BACKLOG_FILE, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


@app.route("/api/backlog/<pid>/add", methods=["POST"])
def api_backlog_add(pid):
    data = request.get_json(force=True, silent=True) or {}
    text = (data.get("text") or "").strip()
    if not text:
        return jsonify({"error": "empty"}), 400
    b = _load_backlog()
    items = b.setdefault(pid, [])
    items.append({"id": datetime.now(TW).strftime("%Y%m%d%H%M%S"), "text": text,
                  "done": False, "ts": datetime.now(TW).strftime("%Y-%m-%d %H:%M")})
    _save_backlog(b)
    return jsonify({"ok": True, "count": len(items)})


@app.route("/api/backlog/<pid>/toggle", methods=["POST"])
def api_backlog_toggle(pid):
    data = request.get_json(force=True, silent=True) or {}
    bid = data.get("id")
    b = _load_backlog()
    for it in b.get(pid, []):
        if it["id"] == bid:
            it["done"] = not it.get("done")
            _save_backlog(b)
            return jsonify({"ok": True, "done": it["done"]})
    return jsonify({"error": "not found"}), 404


@app.route("/api/backlog/<pid>/remove", methods=["POST"])
def api_backlog_remove(pid):
    data = request.get_json(force=True, silent=True) or {}
    bid = data.get("id")
    b = _load_backlog()
    before = len(b.get(pid, []))
    b[pid] = [it for it in b.get(pid, []) if it["id"] != bid]
    _save_backlog(b)
    return jsonify({"ok": True, "removed": before - len(b[pid])})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=False)
