import 'package:commit_lock/features/commitment/domain/session_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// Dummy screens for now
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/commitment/presentation/new_commitment_screen.dart';
import '../../features/commitment/presentation/active_session_screen.dart';
import '../../features/commitment/presentation/result_screen.dart';
import '../../features/commitment/presentation/completion_alarm_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;
      final userName = prefs.getString(AppConstants.userNameKey);

      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // 1. Not logged in? Go to Login (unless already there)
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Logged in but no name? Go to Onboarding (unless already there)
      if (userName == null || userName.isEmpty) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3. Fully set up? Don't allow going back to Login or Onboarding
      if (isLoggingIn || isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/new-commitment', builder: (context, state) => const NewCommitmentScreen()),
      GoRoute(path: '/active-session', builder: (context, state) => const ActiveSessionScreen()),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResultScreen(
            session: extra['session'] as SessionModel,
            fromHistory: extra['fromHistory'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/completion-alarm',
        builder: (context, state) {
          final session = state.extra as SessionModel;
          return CompletionAlarmScreen(session: session);
        },
      ),
      GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
