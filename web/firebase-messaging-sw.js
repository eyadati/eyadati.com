importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});

firebase.initializeApp({
  apiKey: "AIzaSyD9ckA7tjyEsYldjO98qvwVc-hXBqlyckk",
  projectId: "eydati-fcd79",
  messagingSenderId: "854748341753",
  appId: "1:854748341753:web:636a79b127eb3d831e4928",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.data?.title || 'Eyadati';
  const notificationOptions = {
    body: payload.data?.body || '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
