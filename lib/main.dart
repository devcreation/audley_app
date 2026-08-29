import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'data/local_storage.dart';
import 'providers/providers.dart';
import 'screens/main_shell.dart';
import 'screens/landing/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await LocalStorage.init();
  runApp(const ProviderScope(child: AudleyApp()));
}

class AudleyApp extends ConsumerWidget {
  const AudleyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    return MaterialApp(
      title: "Audley Top Performers Incentive",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});
  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loading splash while checking auth
    if (authState.status == AuthStatus.unknown && authState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/logo.png', width: 120, height: 120, fit: BoxFit.contain),
          const SizedBox(height: 32),
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppTheme.teal))),
        ])),
      );
    }

    // If logged in → MainShell with all tabs active
    if (authState.status == AuthStatus.authenticated) {
      return const MainShell();
    }

    // Not logged in → Landing page
    return const LandingScreen();
  }
}
