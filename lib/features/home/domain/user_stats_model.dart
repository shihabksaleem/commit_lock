import 'package:hive/hive.dart';

part 'user_stats_model.g.dart';

@HiveType(typeId: 2)
class UserStatsModel extends HiveObject {
  @HiveField(0)
  int currentStreak;
  
  @HiveField(1)
  int longestStreak;
  
  @HiveField(2)
  int totalSessions;
  
  @HiveField(3)
  int totalCompletedSessions;
  
  @HiveField(4)
  int totalCommittedMinutes;
  
  @HiveField(5)
  int totalCompletedMinutes;
  
  @HiveField(6)
  DateTime? lastCompletedDate;

  UserStatsModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.totalCompletedSessions = 0,
    this.totalCommittedMinutes = 0,
    this.totalCompletedMinutes = 0,
    this.lastCompletedDate,
  });
}
