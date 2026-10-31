import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/display_language_setting.dart';
import 'core/utils/app_router.dart';
import 'data/providers/auth_providers.dart';
import 'domain/models/user_profile.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // ProviderScope is the Riverpod root — analogous to React's <Provider store={store}>
    const ProviderScope(child: SportsCalendarApp()),
  );
}

class SportsCalendarApp extends ConsumerWidget {
  const SportsCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Profile `preferredLanguage` drives which language names use.
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (_, next) {
      if (!next.hasValue) return; // Keep the current mode while loading.
      displayLanguageMode.value = displayLanguageModeFor(
        next.valueOrNull?.preferredLanguage,
      );
    });

    return MaterialApp.router(
      // Rebuild every route when the name language changes. GoRouter keeps
      // the current location, so the visible stack is restored.
      builder: (context, child) => ValueListenableBuilder<DisplayLanguageMode>(
        valueListenable: displayLanguageMode,
        builder: (context, mode, _) =>
            KeyedSubtree(key: ValueKey(mode), child: child!),
      ),
      title: 'スポーツカレンダー',
      debugShowCheckedModeBanner: false,

      // Localization: Japanese primary, English fallback
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      locale: const Locale('ja', 'JP'),

      // Material 3 theme with a sports-inspired color seed
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Deep blue
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,

      // GoRouter integration
      routerConfig: router,
    );
  }
}
