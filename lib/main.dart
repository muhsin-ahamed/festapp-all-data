import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: 'https://vkhjgrjntdgwsktjxnrm.supabase.co',
      publishableKey: 'sb_publishable_Q-kwFn0SWM01AvvrEW-l4w_RUzKcwHK',
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: FestApp(),
    ),
  );
}

class FestApp extends ConsumerStatefulWidget {
  const FestApp({super.key});

  @override
  ConsumerState<FestApp> createState() => _FestAppState();
}

class _FestAppState extends ConsumerState<FestApp> {
  @override
  void initState() {
    super.initState();
    // Seed default system users (controller admin and TV display operator) on launch
    Future.microtask(() async {
      final auth = ref.read(authServiceProvider);
      await auth.seedDefaultUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
