class AppConstants {
  static const String appName = 'CommitLock';

  // Hive Box Names
  static const String sessionsBox = 'sessions_box';
  static const String userStatsBox = 'user_stats_box';
  static const String settingsBox = 'settings_box';
  static const String habitsBox = 'habits_box';

  // SharedPreferences Keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';

  // Habit Categories
  static const List<String> categories = [
    'Reading',
    'Exercise',
    'Language Study',
    'Coding Practice',
    'Meditation',
    'Custom',
  ];

  // Durations (in minutes)
  static const List<int> defaultDurations = [15, 30, 45, 60, 90];

  // Restriction Levels
  static const List<String> restrictionLevels = ['Normal', 'Strict', 'Extreme'];

  // Penalty Amounts
  static const List<double> penaltyAmounts = [1.0, 5.0, 10.0, 25.0, 50.0];

  // Blocked Categories
  static const List<String> blockedCategories = ['Social Media', 'Video Streaming', 'Games', 'News'];
}
