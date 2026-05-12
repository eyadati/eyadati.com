import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/utils/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseInitializer.initialize();

  runApp(const ProviderScope(child: EyadatiApp()));
}

class EyadatiApp extends ConsumerWidget {
  const EyadatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
