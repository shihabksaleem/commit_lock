import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 0)
enum SessionStatus {
  @HiveField(0)
  running,
  @HiveField(1)
  completed,
  @HiveField(2)
  broken,
}

@HiveType(typeId: 1)
class SessionModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String category;
  
  @HiveField(2)
  final int plannedDurationMinutes;
  
  @HiveField(3)
  final double penaltyAmount;
  
  @HiveField(4)
  final String restrictionLevel;
  
  @HiveField(5)
  final DateTime startTime;
  
  @HiveField(6)
  DateTime? endTime;
  
  @HiveField(7)
  SessionStatus status;
  
  @HiveField(8)
  int? actualDurationSeconds;

  SessionModel({
    required this.id,
    required this.category,
    required this.plannedDurationMinutes,
    required this.penaltyAmount,
    required this.restrictionLevel,
    required this.startTime,
    this.endTime,
    this.status = SessionStatus.running,
    this.actualDurationSeconds,
  });
}
