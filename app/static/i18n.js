// AJD — i18n dictionary (zh-TW / en)
// All UI strings extracted from index.html and app.js
// DO NOT hardcode strings in templates/JS — import from here.

const I18N = {
  "zh-TW": {
    // index.html
    "app.title": "AJD · AI agents job dashboard",
    "app.name": "AJD",
    "header.refresh.title": "重新整理",
    "header.meta.loading": "載入中…",
    "tabs.overview": "總覽",
    "tabs.projects": "專案",
    "tabs.ideas": "想法",
    "tabs.history": "歷史",
    "projects.groupby.bot": "依 bot",
    "projects.groupby.type": "依型態",
    "projects.search.placeholder": "搜尋專案名稱、型態、負責 bot…",
    "ideas.composer.placeholder": "突然想到什麼？先丟進來，不用想清楚…",
    "ideas.composer.add": "記下來",
    "ideas.composer.hint.empty": "",
    "detail.back": "← 回專案目錄",

    // app.js - Overview
    "overview.projects": "專案",
    "overview.healthy": "正常",
    "overview.stalled": "停滯",
    "overview.attention": "要關注",
    "overview.service_down": "服務沒在跑",
    "overview.last_activity": "資料時間 {time}",
    "overview.snapshots": "快照 {count} 份",
    "overview.cron_total": "排程 {count} 個",
    "overview.last_activity_hours": "小時前",
    "overview.last_activity_days": "天前",
    "overview.port_alive": "✅",
    "overview.port_dead": "❌",
    "overview.git_commits": "git",
    "overview.git_uncommitted": "未提交",
    "overview.jobs_count": "排程",

    // app.js - Projects list
    "projects.empty_search": "找不到符合「{query}」的專案",
    "projects.group_empty": "這個 bot 底下還沒有掛專案 —— 它平常處理的是對話與日常事務，不是專案。",
    "projects.last_activity_hours": "小時前",
    "projects.last_activity_days": "天前",
    "projects.jobs_count": "排程",
    "projects.files_7d": "近 7 天 {count} 檔",

    // app.js - Project detail
    "project.detail.back": "← 回專案目錄",
    "project.detail.reminders": "提醒 / 待辦",
    "project.detail.reminder.at": "⏰",
    "project.detail.links": "出入口",
    "project.detail.links.tmp": "臨時",
    "project.detail.links.no_link": "沒有連結",
    "project.detail.links.no_entries": "還沒有登記出入口 —— 跟我說我就補上。",
    "project.detail.status": "現況",
    "project.detail.state": "狀態",
    "project.detail.files_7d_30d": "近 7 天 / 30 天檔案",
    "project.detail.last_activity": "最後活動",
    "project.detail.last_file": "最後動的檔",
    "project.detail.dir_size": "目錄大小",
    "project.detail.git": "git",
    "project.detail.git_commits": "commits",
    "project.detail.git_uncommitted": "未提交",
    "project.detail.git_last_commit": "最後提交",
    "project.detail.git_no_vcs": "沒有版控",
    "project.detail.service_running": "運行中",
    "project.detail.service_stopped": "未啟動",
    "project.detail.service": "服務 {key}",
    "project.detail.jobs": "持續工作",
    "project.detail.jobs_count": "個排程",
    "project.detail.job.enabled_off": "已停用",
    "project.detail.job.last_run": "上次",
    "project.detail.job.next_run": "下次",
    "project.detail.job.heartbeat_ok": "回報",
    "project.detail.job.heartbeat_missed": "⚠️ 這次跑完沒回報",
    "project.detail.job.heartbeat_fail": "❌",
    "project.detail.job.heartbeat_warn": "⚠️",
    "project.detail.backlog": "未開發",
    "project.detail.backlog_count": "項待辦",
    "project.detail.backlog_empty": "還沒記錄待辦。想到什麼隨手加，或叫我幫你整理。",
    "project.detail.backlog.add_placeholder": "這個專案還沒做的事…",
    "project.detail.backlog.add_button": "＋",
    "project.detail.activity": "最近活動",
    "project.detail.activity_spark": "近 {count} 次收集的 7 天活動量",
    "project.detail.activity_delta": "跟上次比：{delta}",
    "project.detail.activity_delta_files": "7 天活動量",
    "project.detail.activity_delta_jobs": "排程",
    "project.detail.activity_delta_none": "無變化",
    "project.detail.activity_none": "還沒有歷史（明天開始累積）",
    "project.detail.dependencies": "依賴",
    "project.detail.dependencies_desc": "這個專案要靠這些東西才成立，動它們會影響這裡：",
    "project.detail.entry": "入口 / 檔案",
    "project.detail.not_found": "找不到這個專案",
    "project.detail.no_jobs": "沒有排程 —— 這是手動專案，不會自己動。",

    // app.js - Ideas
    "ideas.empty": "還沒有想法。<br>突然想到什麼就丟上面那格 👆",
    "ideas.badge_total": "共 {count} 個想法",
    "ideas.badge_fresh": "共 {count} 個想法，其中 {fresh} 個還沒看",
    "ideas.log.toggle": "📋 進度與研究",
    "ideas.log.items": "筆",
    "ideas.composer.hint_saving": "儲存中…",
    "ideas.composer.hint_saved": "✅ 記下來了",
    "ideas.composer.hint_failed": "❌ 失敗",
    "ideas.status.new": "🆕 新想法",
    "ideas.status.thinking": "🤔 考慮中",
    "ideas.status.started": "🚀 已開案",
    "ideas.status.shelved": "📦 擱置",
    "ideas.status.done": "✅ 完成",
    "ideas.delete_confirm": "刪除這個想法？",
    "ideas.log.kind.idea": "最初想法",
    "ideas.log.kind.research": "🔍 研究",
    "ideas.log.kind.progress": "📈 進展",
    "ideas.log.kind.blocker": "⛔ 卡住",
    "ideas.log.kind.decision": "⚖️ 決策",
    "ideas.log.kind.concept": "📄 構想書",

    // app.js - History
    "history.empty": "只有一份快照，明天開始就會有歷史了。<br>（每天自動收集一次）",
    "history.row.new_files": "新增 {count} 檔",
    "history.row.files_today": "今天動 {count} 檔",
    "history.row.git_new": "{count} commits",
    "history.row.status_changed": "（{prev} → {now}）",
    "history.none": "沒有明顯變化",

    // Common
    "common.minutes_ago": "分鐘前",
    "common.hours_ago": "小時前",
    "common.days_ago": "天前",
    "common.none": "—",
    "common.ok": "✅",
    "common.fail": "❌",
    "common.warn": "⚠️",
    "common.loading": "載入中…",
    "lang.switch": "English",
    "lang.current": "中文"
  },

  "en": {
    // index.html
    "app.title": "AJD · AI agents job dashboard",
    "app.name": "AJD",
    "header.refresh.title": "Refresh",
    "header.meta.loading": "Loading…",
    "tabs.overview": "Overview",
    "tabs.projects": "Projects",
    "tabs.ideas": "Ideas",
    "tabs.history": "History",
    "projects.groupby.bot": "By bot",
    "projects.groupby.type": "By type",
    "projects.search.placeholder": "Search project name, type, bot…",
    "ideas.composer.placeholder": "Got a sudden idea? Drop it here, no need to polish…",
    "ideas.composer.add": "Save",
    "ideas.composer.hint.empty": "",
    "detail.back": "← Back to projects",

    // app.js - Overview
    "overview.projects": "Projects",
    "overview.healthy": "Healthy",
    "overview.stalled": "Stalled",
    "overview.attention": "Needs attention",
    "overview.service_down": "Service down",
    "overview.last_activity": "Data time {time}",
    "overview.snapshots": "{count} snapshots",
    "overview.cron_total": "{count} cron jobs",
    "overview.last_activity_hours": "h ago",
    "overview.last_activity_days": "d ago",
    "overview.port_alive": "✅",
    "overview.port_dead": "❌",
    "overview.git_commits": "git",
    "overview.git_uncommitted": "uncommitted",
    "overview.jobs_count": "jobs",

    // app.js - Projects list
    "projects.empty_search": "No projects matching \"{query}\"",
    "projects.group_empty": "This bot has no projects yet — it usually handles chat & daily tasks, not projects.",
    "projects.last_activity_hours": "h ago",
    "projects.last_activity_days": "d ago",
    "projects.jobs_count": "jobs",
    "projects.files_7d": "{count} files / 7d",

    // app.js - Project detail
    "project.detail.back": "← Back to projects",
    "project.detail.reminders": "Reminders / Todos",
    "project.detail.reminder.at": "⏰",
    "project.detail.links": "Links",
    "project.detail.links.tmp": "temp",
    "project.detail.links.no_link": "No link",
    "project.detail.links.no_entries": "No links registered yet — tell me and I'll add them.",
    "project.detail.status": "Status",
    "project.detail.state": "State",
    "project.detail.files_7d_30d": "Files 7d / 30d",
    "project.detail.last_activity": "Last activity",
    "project.detail.last_file": "Last modified file",
    "project.detail.dir_size": "Directory size",
    "project.detail.git": "git",
    "project.detail.git_commits": "commits",
    "project.detail.git_uncommitted": "uncommitted",
    "project.detail.git_last_commit": "Last commit",
    "project.detail.git_no_vcs": "No version control",
    "project.detail.service_running": "Running",
    "project.detail.service_stopped": "Stopped",
    "project.detail.service": "Service {key}",
    "project.detail.jobs": "Active Jobs",
    "project.detail.jobs_count": "jobs",
    "project.detail.job.enabled_off": "Disabled",
    "project.detail.job.last_run": "Last run",
    "project.detail.job.next_run": "Next run",
    "project.detail.job.heartbeat_ok": "Reported",
    "project.detail.job.heartbeat_missed": "⚠️ Ran but no heartbeat",
    "project.detail.job.heartbeat_fail": "❌",
    "project.detail.job.heartbeat_warn": "⚠️",
    "project.detail.backlog": "Backlog",
    "project.detail.backlog_count": "items",
    "project.detail.backlog_empty": "No backlog items yet. Add anything, or ask me to organise.",
    "project.detail.backlog.add_placeholder": "What's not done for this project…",
    "project.detail.backlog.add_button": "＋",
    "project.detail.activity": "Recent Activity",
    "project.detail.activity_spark": "Last {count} snapshots · 7d activity",
    "project.detail.activity_delta": "vs last: {delta}",
    "project.detail.activity_delta_files": "7d activity",
    "project.detail.activity_delta_jobs": "jobs",
    "project.detail.activity_delta_none": "no change",
    "project.detail.activity_none": "No history yet (starts accumulating tomorrow)",
    "project.detail.dependencies": "Dependencies",
    "project.detail.dependencies_desc": "This project relies on these — changing them affects here:",
    "project.detail.entry": "Entries / Files",
    "project.detail.not_found": "Project not found",
    "project.detail.no_jobs": "No jobs — this is a manual project.",

    // app.js - Ideas
    "ideas.empty": "No ideas yet.<br>Drop a sudden thought in the box above 👆",
    "ideas.badge_total": "{count} ideas total",
    "ideas.badge_fresh": "{count} ideas total, {fresh} unread",
    "ideas.log.toggle": "📋 Progress & Research",
    "ideas.log.items": "items",
    "ideas.composer.hint_saving": "Saving…",
    "ideas.composer.hint_saved": "✅ Saved",
    "ideas.composer.hint_failed": "❌ Failed",
    "ideas.status.new": "🆕 New",
    "ideas.status.thinking": "🤔 Thinking",
    "ideas.status.started": "🚀 Started",
    "ideas.status.shelved": "📦 Shelved",
    "ideas.status.done": "✅ Done",
    "ideas.delete_confirm": "Delete this idea?",
    "ideas.log.kind.idea": "Initial idea",
    "ideas.log.kind.research": "🔍 Research",
    "ideas.log.kind.progress": "📈 Progress",
    "ideas.log.kind.blocker": "⛔ Blocker",
    "ideas.log.kind.decision": "⚖️ Decision",
    "ideas.log.kind.concept": "📄 Concept",

    // app.js - History
    "history.empty": "Only one snapshot so far — history starts tomorrow.<br>(Auto-collected daily)",
    "history.row.new_files": "+{count} files",
    "history.row.files_today": "{count} files today",
    "history.row.git_new": "{count} commits",
    "history.row.status_changed": "({prev} → {now})",
    "history.none": "No significant changes",

    // Common
    "common.minutes_ago": "min ago",
    "common.hours_ago": "h ago",
    "common.days_ago": "d ago",
    "common.none": "—",
    "common.ok": "✅",
    "common.fail": "❌",
    "common.warn": "⚠️",
    "common.loading": "Loading…",
    "lang.switch": "中文",
    "lang.current": "English"
  }
};

// Language detection & switching logic
const I18N_LANG_KEY = "ajd_lang";

function getBrowserLang() {
  const navLang = navigator.language || navigator.userLanguage || "en";
  if (navLang.startsWith("zh")) return "zh-TW";
  return "en";
}

function getCurrentLang() {
  const stored = localStorage.getItem(I18N_LANG_KEY);
  if (stored && I18N[stored]) return stored;
  return getBrowserLang();
}

function setCurrentLang(lang) {
  if (!I18N[lang]) lang = "en";
  localStorage.setItem(I18N_LANG_KEY, lang);
  document.documentElement.lang = lang === "zh-TW" ? "zh-TW" : "en";
  applyI18n(lang);
}

function t(key, params = {}) {
  const lang = getCurrentLang();
  let str = I18N[lang][key] || I18N.en[key] || key;
  // Simple placeholder replacement {key}
  Object.entries(params).forEach(([k, v]) => {
    str = str.replace(new RegExp(`\\{${k}\\}`, "g"), v);
  });
  return str;
}

function applyI18n(lang) {
  // Update document title
  document.title = t("app.title");

  // Update elements with data-i18n attribute
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.dataset.i18n;
    const params = el.dataset.i18nParams ? JSON.parse(el.dataset.i18nParams) : {};
    const text = t(key, params);
    if (el.tagName === "INPUT" || el.tagName === "TEXTAREA") {
      if (el.type === "search" || el.type === "text" || el.tagName === "TEXTAREA") {
        el.placeholder = text;
      } else {
        el.value = text;
      }
    } else {
      el.innerHTML = text;
    }
  });

  // Update elements with data-i18n-title (for title attributes)
  document.querySelectorAll("[data-i18n-title]").forEach(el => {
    el.title = t(el.dataset.i18nTitle);
  });

  // Update language switcher button text
  const langBtn = document.getElementById("langSwitch");
  if (langBtn) {
    langBtn.textContent = t("lang.switch");
    langBtn.setAttribute("aria-label", t("lang.switch"));
  }

  // Re-render dynamic content if STATE exists
  if (typeof STATE !== "undefined" && STATE) {
    if (typeof renderOverview === "function") renderOverview();
    if (typeof renderProjects === "function") renderProjects();
    if (typeof renderIdeas === "function") renderIdeas();
    if (typeof renderHistory === "function") renderHistory();
    // Project detail page needs special handling - re-open if on that view
    if (!document.getElementById("view-project").hidden) {
      const pid = location.hash.replace(/^#\/?p\//, "");
      if (pid) openProjectPage(decodeURIComponent(pid));
    }
  }
}

// Initialize on load
document.addEventListener("DOMContentLoaded", () => {
  const lang = getCurrentLang();
  document.documentElement.lang = lang === "zh-TW" ? "zh-TW" : "en";
  applyI18n(lang);

  // Language switcher click handler
  const langBtn = document.getElementById("langSwitch");
  if (langBtn) {
    langBtn.addEventListener("click", () => {
      const newLang = getCurrentLang() === "zh-TW" ? "en" : "zh-TW";
      setCurrentLang(newLang);
    });
  }
});