importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD9ckA7tjyEsYldjO98qvwVc-hXBqlyckk',
  authDomain: 'eydati-fcd79.firebaseapp.com',
  projectId: 'eydati-fcd79',
  storageBucket: 'eydati-fcd79.firebasestorage.app',
  messagingSenderId: '854748341753',
  appId: '1:854748341753:web:636a79b127eb3d831e4928',
  measurementId: 'G-PC4TB4TYD8',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const data = payload.data || {};
  const phone = data.phone || '';
  const name = data.name || '';
  const title = name ? `Call ${name}` : 'Call patient';
  self.registration.showNotification(title, {
    body: phone ? `Tap to call ${phone}` : 'Incoming call request',
    icon: '/icons/Icon-192.png',
    badge: '/favicon.png',
    data: { phone, name, type: 'call_patient' },
    tag: 'call-patient',
    requireInteraction: true,
  });
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const data = event.notification.data || {};
  const phone = data.phone || '';
  const url = phone
    ? `/?call_phone=${encodeURIComponent(phone)}&call_name=${encodeURIComponent(data.name || '')}`
    : '/';
  event.waitUntil(clients.openWindow(url));
});
