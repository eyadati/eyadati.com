import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Unsupported platform');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9ckA7tjyEsYldjO98qvwVc-hXBqlyckk',
    appId: '1:854748341753:web:636a79b127eb3d831e4928',
    messagingSenderId: '854748341753',
    projectId: 'eydati-fcd79',
    authDomain: 'eydati-fcd79.firebaseapp.com',
    storageBucket: 'eydati-fcd79.firebasestorage.app',
    measurementId: 'G-PC4TB4TYD8',
  );
}
