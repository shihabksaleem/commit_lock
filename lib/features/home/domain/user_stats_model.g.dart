// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatsModelAdapter extends TypeAdapter<UserStatsModel> {
  @override
  final int typeId = 2;

  @override
  UserStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStatsModel(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      totalSessions: fields[2] as int,
      totalCompletedSessions: fields[3] as int,
      totalCommittedMinutes: fields[4] as int,
      totalCompletedMinutes: fields[5] as int,
      lastCompletedDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStatsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.totalSessions)
      ..writeByte(3)
      ..write(obj.totalCompletedSessions)
      ..writeByte(4)
      ..write(obj.totalCommittedMinutes)
      ..writeByte(5)
      ..write(obj.totalCompletedMinutes)
      ..writeByte(6)
      ..write(obj.lastCompletedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
