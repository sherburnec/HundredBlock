'use strict';
// Generated into build/web/hb_sw.js by scripts/gen_sw.sh (file list + content hash).
const VERSION = '__VERSION__';
const CACHE = 'hb-' + VERSION;
const FILES = __FILES__;
const SCOPE = self.registration.scope;

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await cache.addAll(FILES.map((f) => new Request(f, { cache: 'reload' })));
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((k) => k.startsWith('hb-') && k !== CACHE).map((k) => caches.delete(k)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      let hit = await cache.match(req, { ignoreSearch: true });
      if (!hit && req.mode === 'navigate') hit = await cache.match(SCOPE + 'index.html');
      if (hit) return hit;
      return fetch(req);
    })(),
  );
});
