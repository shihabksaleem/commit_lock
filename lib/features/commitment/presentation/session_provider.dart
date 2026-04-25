import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/session_model.dart';
import '../../home/domain/user_stats_model.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/services/notification_service.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionModel?>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<SessionModel?> {
  SessionNotifier() : super(null) {
    _loadActiveSession();
  }

  Timer? _timer;
  late Box<SessionModel> _sessionsBox;
  late Box<UserStatsModel> _statsBox;

  Future<void> _loadActiveSession() async {
    _sessionsBox = Hive.box<SessionModel>(AppConstants.sessionsBox);
    _statsBox = Hive.box<UserStatsModel>(AppConstants.userStatsBox);

    // Find if there's any session with status 'running'
    final activeSession = _sessionsBox.values.cast<SessionModel?>().firstWhere(
      (s) => s?.status == SessionStatus.running,
      orElse: () => null,
    );

    if (activeSession != null) {
      final now = DateTime.now();
      final endTime = activeSession.startTime.add(Duration(minutes: activeSession.plannedDurationMinutes));

      if (now.isAfter(endTime)) {
        // Session should have completed
        await completeSession(activeSession);
      } else {
        state = activeSession;
        _startTimer();
      }
    }
  }

  Future<void> startSession({
    required String category,
    required int durationMinutes,
    required double penaltyAmount,
    required String restrictionLevel,
  }) async {
    final session = SessionModel(
      id: const Uuid().v4(),
      category: category,
      plannedDurationMinutes: durationMinutes,
      penaltyAmount: penaltyAmount,
      restrictionLevel: restrictionLevel,
      startTime: DateTime.now(),
      status: SessionStatus.running,
    );

    await _sessionsBox.add(session);
    state = session;

    // Schedule completion alarm for background/terminated states.
    // We use ID 100 specifically for the end-of-session alarm to distinguish it
    // from the ongoing progress notification (ID 1).
    final endTime = session.startTime.add(Duration(minutes: session.plannedDurationMinutes));
    await NotificationService.scheduleNotification(
      id: 100, // Alarm ID
      title: 'Commitment Kept! 🎉',
      body: 'Your ${session.category} session is complete. Tap to view!',
      scheduledDate: endTime,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final endTime = state!.startTime.add(Duration(minutes: state!.plannedDurationMinutes));

      if (now.isAfter(endTime)) {
        timer.cancel();
        completeSession(state!);
      } else {
        // Update ongoing notification
        final remaining = endTime.difference(now);
        final totalSeconds = state!.plannedDurationMinutes * 60;
        final elapsedSeconds = now.difference(state!.startTime).inSeconds;
        final progress = elapsedSeconds / totalSeconds;

        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        final timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        NotificationService.showOngoingNotification(
          id: 1,
          title: 'Focus: ${state!.category}',
          body: 'Time Remaining: $timeStr',
          progress: progress,
        );

        // Trigger UI update
        state = state;
      }
    });
  }

  Future<void> completeSession(SessionModel session) async {
    session.status = SessionStatus.completed;
    session.endTime = DateTime.now();
    session.actualDurationSeconds = session.plannedDurationMinutes * 60;
    await session.save();

    _timer?.cancel();
    state = null;

    final settingsBox = Hive.box(AppConstants.settingsBox);
    final notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);

    if (notificationsEnabled) {
      await NotificationService.showNotification(
        id: 0,
        title: 'Commitment Kept! 🎉',
        body: 'Great job! You finished your ${session.category} session.',
      );
    }

    // Cancel ongoing and scheduled notifications
    await NotificationService.cancelNotification(1);
    await NotificationService.cancelNotification(100);

    await _updateStats(session);
  }

  Future<void> _updateStats(SessionModel session) async {
    final stats = _statsBox.get('current_stats') ?? UserStatsModel();

    stats.totalSessions++;
    stats.totalCommittedMinutes += session.plannedDurationMinutes;
    if (session.status == SessionStatus.completed) {
      stats.totalCompletedSessions++;
      stats.totalCompletedMinutes += session.plannedDurationMinutes;
    }

    final allSessions = _sessionsBox.values.toList();
    final dailyStats = StreakCalculator.getDailyStats(allSessions);
    final currentStreak = StreakCalculator.calculateStreak(dailyStats);

    stats.currentStreak = currentStreak;
    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }
    stats.lastCompletedDate = DateTime.now();

    await _statsBox.put('current_stats', stats);
  }

  Future<void> breakSession(SessionModel session) async {
    session.status = SessionStatus.broken;
    session.endTime = DateTime.now();
    session.actualDurationSeconds = DateTime.now().difference(session.startTime).inSeconds;
    await session.save();

    _timer?.cancel();
    state = null;

    // Cancel ongoing and scheduled notifications
    await NotificationService.cancelNotification(1);
    await NotificationService.cancelNotification(100);

    await _updateStats(session);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
