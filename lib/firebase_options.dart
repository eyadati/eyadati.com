import 'package:flutter/foundation.dart';

class AppFirebaseConfig {
  static const String apiKey = 'AIzaSyD9ckA7tjyEsYldjO98qvwVc-hXBqlyckk';
  static const String projectId = 'eydati-fcd79';
  static const String messagingSenderId = '854748341753';
  static const String appId = '1:854748341753:web:636a79b127eb3d831e4928';

  static const String vapidKey =
      'BE-a13FMcHWXi287vRmw6N0oNIOh9eoP6KOP71eIpTjjUc63Vmi7di_6X-CbT77zAF2-dhKytlE-XTnGIcr685k';

  static bool get isWebSupported =>
      kIsWeb && apiKey.isNotEmpty && projectId.isNotEmpty;
}
