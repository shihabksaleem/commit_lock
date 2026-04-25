import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'features/commitment/domain/session_model.dart';
import 'features/home/domain/user_stats_model.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/commitment/presentation/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SessionStatusAdapter());
  Hive.registerAdapter(SessionModelAdapter());
  Hive.registerAdapter(UserStatsModelAdapter());

  // Open Boxes
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox<String>(AppConstants.habitsBox);
  await Hive.openBox<SessionModel>(AppConstants.sessionsBox);
  await Hive.openBox<UserStatsModel>(AppConstants.userStatsBox);

  runApp(const ProviderScope(child: CommitLockApp()));
}

class CommitLockApp extends ConsumerWidget {
  const CommitLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    // Global listener for session completion to trigger the alarm UI.
    // This handles the transition from active work to the completion screen
    // regardless of where the user is currently located in the app.
    ref.listen<SessionModel?>(sessionProvider, (previous, next) {
      // If a session was running (previous != null) and is now finished (next == null)
      if (previous != null && next == null) {
        final box = Hive.box<SessionModel>(AppConstants.sessionsBox);
        if (box.isNotEmpty) {
          final lastSession = box.values.last;
          // Only trigger if the session actually completed successfully (timer reached zero)
          if (lastSession.status == SessionStatus.completed) {
            router.go('/completion-alarm', extra: lastSession);
          }
        }
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
