// AJD service worker
// 原則：**網路優先**，快取只當離線備援。
// （教訓：之前 Flask 範本快取造成「改了看不到」，這裡不要重蹈覆轍）
const CACHE = "dash-v3";
const SHELL = ["/", "/static/style.css", "/static/app.js",
               "/static/icon-192.png", "/static/manifest.webmanifest"];

self.addEventListener("install", (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const u = new URL(req.url);
  if (u.origin !== location.origin) return;   // 只管自己的

  // API 永遠走網路（資料不能吃快取）
  if (u.pathname.startsWith("/api/")) return;

  // 其他：網路優先，失敗才用快取（離線時至少看得到外殼）
  e.respondWith(
    fetch(req)
      .then((r) => {
        if (r && r.status === 200) {
          const copy = r.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        }
        return r;
      })
      .catch(() => caches.match(req).then((m) => m || caches.match("/")))
  );
});
