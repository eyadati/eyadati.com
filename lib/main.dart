import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/utils/supabase_client.dart';
import 'core/providers/locale_provider.dart';
import 'core/widgets/feedback/update_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseInitializer.initialize();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase unavailable (ad blocker, unsupported browser, etc.)
    // Realtime-only path will still work for call notifications
  }

  runApp(const ProviderScope(child: EyadatiApp()));
}

class EyadatiApp extends ConsumerWidget {
  const EyadatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Eyadati',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
        Locale('ar', ''),
      ],
      builder: (context, child) {
        final isRtl = ref.watch(localeProvider).languageCode == 'ar';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AppWithUpdateBanner(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
