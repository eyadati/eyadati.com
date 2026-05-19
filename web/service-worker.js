
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open('eyadati-cache-v1').then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/flutter_bootstrap.js',
        '/favicon.png',
        '/manifest.json'
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request).catch(() => {
        // Fallback for navigation requests
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
        cacheNames.filter((name) => name !== 'eyadati-cache-v1').map((name) => caches.delete(name))
      );
    })
  );
});
