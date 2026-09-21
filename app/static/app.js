// AJD — 前端
let STATE = null;

const $ = (id) => document.getElementById(id);
const esc = (s) => String(s == null ? "" : s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

async function load() {
  const r = await fetch("/api/state");
  STATE = await r.json();
  $("hdMeta").textContent =
    `資料時間 ${STATE.latest.generated_at || "—"}｜快照 ${STATE.snapshot_count} 份｜排程 ${STATE.latest.cron_total || 0} 個`;
  renderOverview();
  renderIdeas();
  renderHistory();
}

// ── 總覽 ───────────────────────────────────────────────
function renderOverview() {
  const P = STATE.latest.projects || {};
  const order = { red: 0, yellow: 1, grey: 2, green: 3 };
  const names = Object.keys(P).sort((a, b) => {
    const la = order[P[a].level] ?? 9, lb = order[P[b].level] ?? 9;
    return la - lb || a.localeCompare(b);
  });
  const counts = { green: 0, yellow: 0, red: 0, grey: 0 };
  names.forEach(n => counts[P[n].level] = (counts[P[n].level] || 0) + 1);

  const svc = STATE.latest.services || {};
  const svcBad = Object.entries(svc).filter(([, v]) => !v.alive).map(([k]) => k);

  let html = `
  <div class="summary">
    <div class="sum-item"><div class="sum-num">${names.length}</div><div class="sum-lbl">專案</div></div>
    <div class="sum-item"><div class="sum-num" style="color:var(--green)">${counts.green || 0}</div><div class="sum-lbl">正常</div></div>
    <div class="sum-item"><div class="sum-num" style="color:var(--yellow)">${counts.yellow || 0}</div><div class="sum-lbl">停滯</div></div>
    <div class="sum-item"><div class="sum-num" style="color:var(--red)">${counts.red || 0}</div><div class="sum-lbl">要關注</div></div>
  </div>`;

  if (svcBad.length) html += `<div class="card line-red"><div class="c-name">⚠️ 服務沒在跑</div><div class="c-status">${esc(svcBad.join("、"))}</div></div>`;

  for (const n of names) {
    const f = P[n], m = f.meta || {};
    const icon = STATE.level_icon[f.level] || "⚪";
    const days = f.newest_age_hours == null ? "" : f.newest_age_hours < 24 ? `${f.newest_age_hours} 小時前` : `${(f.newest_age_hours / 24).toFixed(1)} 天前`;
    const port = m.port ? `<span class="${f.port_alive ? "" : "c-flag"}">port ${m.port} ${f.port_alive ? "✅" : "❌"}</span>` : "";
    const git = f.git ? `<span>git ${f.git.commits}${f.git.uncommitted ? ` (+${f.git.uncommitted} 未提交)` : ""}</span>` : "";
    const jobs = (f.jobs && f.jobs.length) ? `<span>⏰ ${f.jobs.length} 排程</span>` : "";
    html += `
    <div class="card line-${f.level}" onclick="openProjectPage('${n}')">
      <div class="c-top">
        <div class="c-name">${icon} ${esc(n)}</div>
        <div class="c-type">${esc(m.type || "")}</div>
      </div>
      <div class="c-status">${esc(m.name || "")} · <b>${esc(f.status)}</b></div>
      <div class="c-facts">
        <span>近 7 天 ${f.files ? f.files["7d"] : 0} 檔</span>
        ${days ? `<span>最後活動 ${days}</span>` : ""}
        ${port}${git}${jobs}
      </div>
    </div>`;
  }
  $("view-overview").innerHTML = html;
}

// ── 專案目錄（第一層用 bot 分，因為你是透過 bot 跟系統講話）────
const TYPE_ORDER = ["產線", "專案", "服務", "基礎", "其他"];
let GROUP_BY = "bot";

function renderProjects() {
  const P = (STATE.latest && STATE.latest.projects) || {};
  const profs = (STATE.registry && STATE.registry.profiles) || {};
  const q = ($("projSearch").value || "").trim().toLowerCase();

  const groups = {};
  // 目錄 = 「我所有的 bot」，即使底下还没掛專案也要出現
  if (GROUP_BY === "bot") for (const k of Object.keys(profs)) groups[k] = [];
  for (const pid of Object.keys(P)) {
    const f = P[pid], m = f.meta || {};
    const hay = [pid, m.name, m.type, m.bot, m.profile, m.desc].filter(Boolean).join(" ").toLowerCase();
    if (q && !hay.includes(q)) continue;
    const key = GROUP_BY === "bot" ? (m.profile || "?") : (m.type || "其他");
    (groups[key] = groups[key] || []).push([pid, f]);
  }
  const keys = Object.keys(groups)
    .filter(k => !q || groups[k].length)
    .sort((a, b) => {
      if (GROUP_BY === "bot") return groups[b].length - groups[a].length || a.localeCompare(b);
      return (TYPE_ORDER.indexOf(a) + 99) - (TYPE_ORDER.indexOf(b) + 99);
    });

  if (!keys.length) {
    $("projList").innerHTML = `<div class="empty">找不到符合「${esc(q)}」的專案</div>`;
    return;
  }

  $("projList").innerHTML = keys.map(k => {
    const info = profs[k] || {};
    const head = GROUP_BY === "bot"
      ? `<span class="pg-bot">🤖 ${esc(info.handle || k)}</span><span class="pg-count">${groups[k].length}</span><span class="pg-sub">${esc(k)} profile${info.label ? " · " + esc(info.label) : ""}</span>`
      : `<span class="pg-bot">${esc(k)}</span><span class="pg-count">${groups[k].length}</span>`;
    const rows = groups[k].sort((a, b) => a[0].localeCompare(b[0])).map(([pid, f]) => {
      const m = f.meta || {};
      const icon = STATE.level_icon[f.level] || "⚪";
      const days = f.newest_age_hours == null ? "" :
        (f.newest_age_hours < 24 ? `${Math.round(f.newest_age_hours)} 小時前` : `${(f.newest_age_hours / 24).toFixed(1)} 天前`);
      return `
      <div class="prow" onclick="openProjectPage('${pid}')">
        <div class="prow-l">
          <div class="prow-name">${icon} ${esc(m.name || pid)}<span class="prow-type">${esc(m.type || "")}</span></div>
          <div class="prow-desc">${esc(m.desc || "")}</div>
          <div class="prow-facts">
            ${days ? `<span>最後活動 ${days}</span>` : ""}
            ${(f.jobs && f.jobs.length) ? `<span>⏰ ${f.jobs.length} 排程</span>` : ""}
            ${f.files && f.files["7d"] ? `<span>近 7 天 ${f.files["7d"]} 檔</span>` : ""}
          </div>
        </div>
        <div class="prow-r">›</div>
      </div>`;
    }).join("");
    const empty = groups[k].length ? "" :
      `<div class="pg-empty">這個 bot 底下還沒有掛專案 —— 它平常處理的是對話與日常事務，不是專案。</div>`;
    return `<div class="pg-group">
      <div class="pg-title">${head}</div>
      ${rows}${empty}</div>`;
  }).join("");
}

// ── 專案頁（進去看到「做了什麼 + 持續工作 + 還沒做」）──────
function hoursAgo(iso) {
  if (!iso) return null;
  const t = Date.parse(iso);
  if (isNaN(t)) return null;
  return (Date.now() - t) / 3600000;
}

function fmtAge(h) {
  if (h === null || h === undefined) return "—";
  if (h < 1) return Math.round(h * 60) + " 分鐘前";
  if (h < 24) return Math.round(h) + " 小時前";
  return Math.round(h / 24) + " 天前";
}

async function openProjectPage(pid) {
  // 直接開帶 #/p/xxx 的網址時，routeFromHash() 可能比 load() 先跑，
  // 那時 STATE 還是 null → 讀 STATE.level_icon 會炸掉，畫面卡在「載入中…」。
  if (!STATE) {
    try { await load(); } catch (e) { /* 下面自然會顯示找不到 */ }
  }
  location.hash = "#/p/" + encodeURIComponent(pid);
  showView("project");
  $("view-project").innerHTML = `<div class="empty">載入中…</div>`;

  const r = await fetch("/api/project/" + encodeURIComponent(pid));
  const d = await r.json();
  if (d.error) { $("view-project").innerHTML = `<div class="empty">找不到這個專案</div>`; return; }

  const f = d.latest || {}, pv = d.prev, m = d.meta || {};
  const icon = STATE.level_icon[f.level] || "⚪";
  const max = Math.max(1, ...(d.series || []).map(x => x.files_7d || 0));
  const spark = (d.series || []).map(x =>
    `<i style="height:${Math.round((x.files_7d || 0) / max * 100)}%" title="${x.date}: ${x.files_7d}"></i>`).join("");

  // 跟上一份快照比
  let delta = "";
  if (pv) {
    const d7 = (f.files ? f.files["7d"] : 0) - (pv.files ? pv.files["7d"] : 0);
    const dJobs = (f.jobs || []).length - (pv.jobs || []).length;
    const bits = [];
    if (d7) bits.push(`7 天活動量 ${d7 > 0 ? "+" : ""}${d7}`);
    if (dJobs) bits.push(`排程 ${dJobs > 0 ? "+" : ""}${dJobs}`);
    delta = bits.join("、") || "無變化";
  }

  // 持續工作（排程）+ 心跳回報
  //   心跳的價值：不要用「檔案時間」猜排程有沒有跑完 —— 讓排程自己回報。
  //   最有用的一種狀態是「cron 說它跑了，但心跳沒回來」= 跑完卻沒回報（可能失敗在半路）。
  const jobs = (f.jobs || []).map(j => {
    const hb = (STATE.heartbeats || {})[j.name];
    let hbHtml = "";
    if (hb) {
      const age = hoursAgo(hb.ts);
      const icon = hb.status === "ok" ? "✅" : (hb.status === "fail" ? "❌" : "⚠️");
      // cron 說這次跑過（last_run）但心跳比它舊 → 這次沒回報
      const missed = j.last_run && hb.ts && (Date.parse(j.last_run) > Date.parse(hb.ts));
      hbHtml = `<div class="hb ${missed ? "hb-miss" : ""}">
        ${missed ? "⚠️ 這次跑完沒回報" : `${icon} 回報 ${fmtAge(age)}`}
        ${hb.note ? ` · ${esc(hb.note)}` : ""}</div>`;
    }
    return `
    <div class="job">
      <div class="job-name">${esc(j.name || "(未命名)")} ${j.enabled === false ? '<span class="job-off">已停用</span>' : ""}</div>
      <div class="job-meta">
        <span class="mono">${esc(j.schedule || "")}</span>
        <span>${esc(j.profile || "")}</span>
        ${j.last_run ? `<span>上次 ${esc(String(j.last_run).slice(5, 16).replace("T", " "))}</span>` : ""}
        ${j.next_run ? `<span>下次 ${esc(String(j.next_run).slice(5, 16).replace("T", " "))}</span>` : ""}
      </div>
      ${hbHtml}
    </div>`;
  }).join("") || `<div class="none">沒有排程 —— 這是手動專案，不會自己動。</div>`;

  // 未開發
  const bl = (d.backlog || []).map(b => `
    <div class="bl ${b.done ? "bl-done" : ""}">
      <span class="bl-box" onclick="toggleBacklog('${pid}','${b.id}')">${b.done ? "☑" : "☐"}</span>
      <span class="bl-text">${esc(b.text)}</span>
      <span class="bl-del" onclick="delBacklog('${pid}','${b.id}')">✕</span>
    </div>`).join("") || `<div class="none">還沒記錄待辦。想到什麼隨手加，或叫我幫你整理。</div>`;

  const svc = (d.services || []).map(s => `
    <div class="kv"><span>服務 ${esc(s.key)}</span>
      <span>${s.port ? "port " + s.port + " " : ""}${s.up ? "✅ 運行中" : "❌ 未啟動"}</span></div>`).join("");

  const entry = Object.entries(d.entry || {}).map(([k, v]) =>
    `<div class="kv"><span>${esc(k)}</span><span class="mono small">${esc(v)}</span></div>`).join("");

  // 出入口（忘記就可以自己進去，不用每次都問 bot）
  const links = (d.links || []).map(l => {
    if (l.url) {
      return `<a class="lnk" href="${esc(l.url)}" target="_blank" rel="noopener noreferrer">
        <span class="lnk-l">${esc(l.label)}${l.tmp ? ' <span class="lnk-tmp">臨時</span>' : ""}</span>
        <span class="lnk-u">${esc(l.url.replace(/^https?:\/\//, ""))}</span></a>`;
    }
    if (l.path) {
      return `<div class="lnk lnk-plain"><span class="lnk-l">${esc(l.label)}</span>
        <span class="lnk-u mono">${esc(l.path)}</span></div>`;
    }
    return `<div class="lnk lnk-off"><span class="lnk-l">${esc(l.label)}</span>
      <span class="lnk-u">${esc(l.note || "沒有連結")}</span></div>`;
  }).join("") || `<div class="none">還沒有登記出入口 —— 跟我說我就補上。</div>`;

  // 提醒 / 待辦（專案自己帶的，例如某專案「上線前要改密碼」）
  const rems = (m.reminders || []).map(x => `
    <div class="rem">
      <div class="rem-when">⏰ ${esc(x.when || "")}${x.status ? ` · <span class="rem-st">${esc(x.status)}</span>` : ""}</div>
      <div class="rem-what">${esc(x.what || "")}</div>
      ${x.why ? `<div class="rem-why">${esc(x.why)}</div>` : ""}
    </div>`).join("");

  const deps = (d.depends_on || []).map(x =>
    `<span class="dep" onclick="openProjectPage('${x}')">${esc(x)} →</span>`).join("");

  $("view-project").innerHTML = `
  <button class="back" onclick="showView('projects')">← 回專案目錄</button>

  <div class="card line-${f.level}" style="cursor:default">
    <div class="c-top">
      <div class="c-name">${icon} ${esc(m.name || pid)}</div>
      <div class="c-type">${esc(m.type || "")}</div>
    </div>
    <div class="c-status">${esc(m.desc || "")}</div>
    <div class="c-facts">
      <span class="mono">${esc(pid)}</span>
      ${m.bot ? `<span>${esc(m.bot)}</span>` : ""}
      ${m.profile ? `<span>profile ${esc(m.profile)}</span>` : ""}
      <span><b>${esc(f.status || "—")}</b></span>
    </div>
  </div>

  ${rems ? `<section class="pp-sec rem-sec">
    <h3>⏰ 提醒 / 待辦</h3>
    ${rems}
  </section>` : ""}

  <section class="pp-sec">
    <h3>🔗 出入口</h3>
    ${links}
  </section>

  <section class="pp-sec">
    <h3>📌 現況</h3>
    <div class="kv"><span>狀態</span><span><b>${esc(f.status || "—")}</b></span></div>
    <div class="kv"><span>近 7 天 / 30 天檔案</span><span>${f.files ? f.files["7d"] : 0} / ${f.files ? f.files["30d"] : 0}（共 ${f.files ? f.files.total : 0}）</span></div>
    <div class="kv"><span>最後活動</span><span>${f.newest ? esc(f.newest.mtime) : "—"}</span></div>
    ${f.newest ? `<div class="kv"><span>最後動的檔</span><span class="mono small">${esc(f.newest.path)}</span></div>` : ""}
    <div class="kv"><span>目錄大小</span><span>${esc(f.size || "—")}</span></div>
    ${f.git ? `<div class="kv"><span>git</span><span>${f.git.commits} commits · ${esc(f.git.last || "")}${f.git.uncommitted ? ` · <b>${f.git.uncommitted} 未提交</b>` : ""}</span></div>` : `<div class="kv"><span>git</span><span>沒有版控</span></div>`}
    ${f.git && f.git.last_subject ? `<div class="kv"><span>最後提交</span><span class="small">${esc(f.git.last_subject)}</span></div>` : ""}
    ${svc}
  </section>

  <section class="pp-sec">
    <h3>⏰ 持續工作 <span class="pp-n">${(f.jobs || []).length} 個排程</span></h3>
    ${jobs}
  </section>

  <section class="pp-sec">
    <h3>📝 未開發 <span class="pp-n">${(d.backlog || []).filter(b => !b.done).length} 項待辦</span></h3>
    ${bl}
    <div class="bl-add">
      <input id="blInput" placeholder="這個專案還沒做的事…" onkeydown="if(event.key==='Enter')addBacklog('${pid}')">
      <button onclick="addBacklog('${pid}')">＋</button>
    </div>
  </section>

  <section class="pp-sec">
    <h3>📈 最近活動</h3>
    ${spark ? `<div class="spark">${spark}</div>
      <div class="none">近 ${(d.series || []).length} 次收集的 7 天活動量${delta ? `｜跟上次比：${esc(delta)}` : ""}</div>`
      : `<div class="none">還沒有歷史（明天開始累積）</div>`}
    ${(f.docs || []).length ? `<div style="margin-top:10px">${f.docs.map(x => `<span class="doc">${esc(x)}</span>`).join("")}</div>` : ""}
  </section>

  ${deps ? `<section class="pp-sec"><h3>🔗 依賴</h3>
    <div class="none">這個專案要靠這些東西才成立，動它們會影響這裡：</div>
    <div style="margin-top:8px">${deps}</div></section>` : ""}

  ${entry ? `<section class="pp-sec"><h3>📂 入口 / 檔案</h3>${entry}</section>` : ""}

  <button class="back" style="margin-top:10px" onclick="showView('projects')">← 回專案目錄</button>`;
}

// ── 未開發清單 ────────────────────────────────────────
async function addBacklog(pid) {
  const el = $("blInput");
  const t = (el && el.value || "").trim();
  if (!t) return;
  await fetch(`/api/backlog/${encodeURIComponent(pid)}/add`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ text: t }) });
  await openProjectPage(pid);
}
async function toggleBacklog(pid, id) {
  await fetch(`/api/backlog/${encodeURIComponent(pid)}/toggle`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
  await openProjectPage(pid);
}
async function delBacklog(pid, id) {
  await fetch(`/api/backlog/${encodeURIComponent(pid)}/remove`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
  await openProjectPage(pid);
}

// ── 分頁切換／路由 ────────────────────────────────────
function showView(v) {
  ["overview", "projects", "project", "ideas", "history"].forEach(x => $("view-" + x).hidden = (x !== v));
  document.querySelectorAll(".tab").forEach(t =>
    t.classList.toggle("active", t.dataset.view === v || (v === "project" && t.dataset.view === "projects")));
  window.scrollTo(0, 0);
  if (v === "projects") renderProjects();
}

// ── 想法收件匣 ─────────────────────────────────────────
function renderIdeas() {
  const ideas = STATE.ideas || [];
  // 徽章顯示「總數」—— 原本顯示「新想法數」，會誤以為總共只有 1 個想法
  const fresh = ideas.filter(i => i.status === "new").length;
  const b = $("ideaBadge");
  b.hidden = !ideas.length;
  b.textContent = ideas.length;
  b.title = fresh ? `共 ${ideas.length} 個想法，其中 ${fresh} 個還沒看` : `共 ${ideas.length} 個想法`;
  b.classList.toggle("has-new", fresh > 0);

  if (!ideas.length) {
    $("ideaList").innerHTML = `<div class="empty">還沒有想法。<br>突然想到什麼就丟上面那格 👆</div>`;
    return;
  }
  $("ideaList").innerHTML = ideas.map(i => {
    const log = i.log || [];
    const items = log.map(e => `
      <div class="upd">
        <div class="upd-head"><span class="upd-kind k-${e.kind}">${(STATE.log_label && STATE.log_label[e.kind]) || e.kind}</span>${esc(e.ts)}</div>
        <div class="upd-text">${esc(e.text)}</div>
      </div>`).join("");
    return `
    <div class="idea">
      <div class="idea-text">${esc(i.text)}</div>
      ${(i.tags && i.tags.length) ? `<div class="idea-foot">${i.tags.map(t => `<span class="tag">${esc(t)}</span>`).join("")}</div>` : ""}
      ${log.length ? `<button class="dd-toggle" onclick="toggleLog('${i.id}')">
          <span>📋 進度與研究</span><span>${log.length} 筆 ▾</span></button>
        <div class="dd-body" id="log-${i.id}" hidden>${items}</div>` : ""}
      <div class="idea-foot">
        <span class="idea-time">${esc(i.ts)}</span>
        ${STATE.idea_status.map(s => `<span class="chip ${i.status === s ? "on" : ""}" onclick="setIdea('${i.id}','${s}')">${STATE.idea_label[s]}</span>`).join("")}
        <span class="chip chip-del" onclick="delIdea('${i.id}')">刪除</span>
      </div>
    </div>`;
  }).join("");
}

function toggleLog(id) {
  const el = document.getElementById("log-" + id);
  if (!el) return;
  el.hidden = !el.hidden;
  const btn = el.previousElementSibling;
  if (btn) {
    const n = btn.querySelectorAll("span")[1].textContent.replace(/[^0-9]/g, "");
    btn.querySelectorAll("span")[1].textContent = n + " 筆 " + (el.hidden ? "▾" : "▴");
  }
}

async function addIdea() {
  const t = $("ideaInput").value.trim();
  if (!t) return;
  $("composerHint").textContent = "儲存中…";
  const r = await fetch("/api/ideas", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ text: t }) });
  if ((await r.json()).ok) {
    $("ideaInput").value = "";
    $("composerHint").textContent = "✅ 記下來了";
    setTimeout(() => $("composerHint").textContent = "", 2000);
    await load();
  } else { $("composerHint").textContent = "❌ 失敗"; }
}

async function setIdea(id, status) {
  await fetch("/api/idea/" + id, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ status }) });
  await load();
}
async function delIdea(id) {
  if (!confirm("刪除這個想法？")) return;
  await fetch("/api/idea/" + id + "/delete", { method: "POST" });
  await load();
}

// ── 歷史 ───────────────────────────────────────────────
function renderHistory() {
  const h = STATE.history || [];
  if (!h.length) {
    $("view-history").innerHTML = `<div class="empty">只有一份快照，明天開始就會有歷史了。<br>（每天自動收集一次）</div>`;
    return;
  }
  $("view-history").innerHTML = h.map(day => {
    const rows = day.changes.map(c => {
      const bits = [];
      if (c.new_files) bits.push(`新增 ${c.new_files} 檔`);
      if (c.files_today) bits.push(`今天動 ${c.files_today} 檔`);
      if (c.git_new) bits.push(`${c.git_new} commits`);
      return `<div class="hist-row">• <b>${esc(c.project)}</b>：${bits.join("，") || "狀態變更"}${c.status_changed ? `（${esc(c.prev_status)} → ${esc(c.status)}）` : ""}</div>`;
    }).join("");
    return `<div class="hist"><div class="hist-date">${esc(day.date)}</div>${rows || `<div class="hist-none">沒有明顯變化</div>`}</div>`;
  }).join("");
}

// ── 事件綁定 ───────────────────────────────────────────
document.querySelectorAll(".tab").forEach(t => t.addEventListener("click", () => {
  location.hash = t.dataset.view === "overview" ? "" : "#/" + t.dataset.view;
  showView(t.dataset.view);
}));
$("projSearch").addEventListener("input", renderProjects);
document.querySelectorAll("#groupBy .seg-b").forEach(b => b.addEventListener("click", () => {
  document.querySelectorAll("#groupBy .seg-b").forEach(x => x.classList.remove("on"));
  b.classList.add("on");
  GROUP_BY = b.dataset.g;
  renderProjects();
}));

function routeFromHash() {
  const h = location.hash.replace(/^#\/?/, "");
  if (h.startsWith("p/")) { openProjectPage(decodeURIComponent(h.slice(2))); return; }
  if (["projects", "ideas", "history"].includes(h)) { showView(h); return; }
  showView("overview");
}
window.addEventListener("hashchange", routeFromHash);
$("ideaAdd").addEventListener("click", addIdea);
$("refresh").addEventListener("click", load);
$("ideaInput").addEventListener("keydown", e => { if ((e.metaKey || e.ctrlKey) && e.key === "Enter") addIdea(); });

load().then(routeFromHash);
setInterval(load, 60000);

// ── app 模式：註冊 service worker ───────────────────────────
// 掛在根目錄 /sw.js（掛 /static/sw.js 的話控制範圍只到 /static/，app 模式會失效）
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js", { scope: "/" })
      .then((r) => console.log("[app] service worker 已註冊，範圍 =", r.scope))
      .catch((e) => console.warn("[app] service worker 註冊失敗:", e));
  });
}
