import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstallPromptNotifier extends StateNotifier<bool> {
  InstallPromptNotifier() : super(false) {
    if (!kIsWeb) return;
    html.window.addEventListener('pwa-install-available', (_) {
      state = true;
    });
    html.window.addEventListener('pwa-installed', (_) {
      state = false;
    });
    html.window.addEventListener('pwa-install-dismissed', (_) {
      state = false;
    });
  }

  void promptInstall() {
    if (!kIsWeb) return;
    html.window.dispatchEvent(html.CustomEvent('flutter-trigger-install'));
  }
}

final installPromptProvider = StateNotifierProvider<InstallPromptNotifier, bool>((ref) {
  return InstallPromptNotifier();
});
