import '../../features/commitment/domain/session_model.dart';
import 'package:intl/intl.dart';

class DailyStats {
  final DateTime date;
  final int completed;
  final int total;

  DailyStats({required this.date, required this.completed, required this.total});

  double get successRate => total == 0 ? 0 : (completed / total);
  bool get isSuccessful => successRate >= 0.8;
}

class StreakCalculator {
  static const double threshold = 0.8;

  static List<DailyStats> getDailyStats(List<SessionModel> sessions) {
    final Map<String, List<SessionModel>> grouped = {};
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (var session in sessions) {
      if (session.status == SessionStatus.running) continue;
      final dateStr = dateFormat.format(session.startTime);
      grouped.putIfAbsent(dateStr, () => []).add(session);
    }

    final List<DailyStats> dailyStats = [];
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var dateStr in sortedDates) {
      final daySessions = grouped[dateStr]!;
      final completed = daySessions.where((s) => s.status == SessionStatus.completed).length;
      dailyStats.add(DailyStats(
        date: DateTime.parse(dateStr),
        completed: completed,
        total: daySessions.length,
      ));
    }

    return dailyStats;
  }

  static int calculateStreak(List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Check if we have sessions today
    final todayStats = dailyStats.firstWhere(
      (s) => DateFormat('yyyy-MM-dd').format(s.date) == todayStr,
      orElse: () => DailyStats(date: now, completed: 0, total: 0),
    );

    int startIndex = 0;
    
    // If today has sessions but success rate < threshold, streak is 0
    if (todayStats.total > 0 && todayStats.successRate < threshold) {
      return 0;
    }
    
    // If today has no sessions, we start checking from yesterday
    if (todayStats.total == 0) {
      startIndex = dailyStats.indexWhere((s) => DateFormat('yyyy-MM-dd').format(s.date) != todayStr);
      if (startIndex == -1) return 0; // No historical data
      
      // Check if yesterday is actually yesterday (streak doesn't break if today is empty, but yesterday must be consecutive)
      final lastDate = dailyStats[startIndex].date;
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final lastDateNormalized = DateTime(lastDate.year, lastDate.month, lastDate.day);
      
      if (lastDateNormalized.isBefore(yesterday)) {
        return 0; // Gap of more than one day
      }
    } else {
      // Today is successful (or no sessions), count it
      streak = 1;
      startIndex = 1;
    }

    // Check previous days
    for (int i = startIndex; i < dailyStats.length; i++) {
      final currentDay = dailyStats[i];
      final prevDay = dailyStats[i - 1];
      
      // Check if days are consecutive
      final diff = prevDay.date.difference(currentDay.date).inDays;
      if (diff > 1) break; // Gap found

      if (currentDay.successRate >= threshold) {
        streak++;
      } else {
        break; // Success rate below threshold
      }
    }

    return streak;
  }
}
