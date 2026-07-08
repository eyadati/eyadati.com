
const DEFAULT_CACHE = 'eyadati-precache-v1';
let CACHE_NAME = DEFAULT_CACHE;
const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/manifest.json',
  '/flutter_bootstrap.js',
  '/favicon.png',
  '/icons/Icon-48.png',
  '/icons/Icon-72.png',
  '/icons/Icon-96.png',
  '/icons/Icon-128.png',
  '/icons/Icon-144.png',
  '/icons/Icon-192.png',
  '/icons/Icon-256.png',
  '/icons/Icon-384.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

// Load version from version.json at install time
async function initCacheName() {
  try {
    const resp = await fetch('/version.json');
    const data = await resp.json();
    CACHE_NAME = `eyadati-v${data.version}+${data.build_number}`;
  } catch (_) {
    CACHE_NAME = DEFAULT_CACHE;
  }
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    initCacheName().then(() =>
      caches.open(CACHE_NAME).then((cache) => {
        return cache.addAll(ASSETS_TO_CACHE);
      })
    )
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        fetch(event.request).then((networkResponse) => {
          if (networkResponse.ok) {
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, networkResponse.clone());
            });
          }
        }).catch(() => {});
        return cachedResponse;
      }

      return fetch(event.request).then((networkResponse) => {
        if (networkResponse.ok) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch(() => {
        if (event.request.mode === 'navigate') {
          return caches.match('/index.html');
        }
      });
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== DEFAULT_CACHE)
          .map((name) => caches.delete(name))
      );
    }).then(() => self.clients.claim())
  );
});
