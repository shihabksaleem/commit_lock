// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = 1;

  @override
  SessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionModel(
      id: fields[0] as String,
      category: fields[1] as String,
      plannedDurationMinutes: fields[2] as int,
      penaltyAmount: fields[3] as double,
      restrictionLevel: fields[4] as String,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
      status: fields[7] as SessionStatus,
      actualDurationSeconds: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.plannedDurationMinutes)
      ..writeByte(3)
      ..write(obj.penaltyAmount)
      ..writeByte(4)
      ..write(obj.restrictionLevel)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.actualDurationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final int typeId = 0;

  @override
  SessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatus.running;
      case 1:
        return SessionStatus.completed;
      case 2:
        return SessionStatus.broken;
      default:
        return SessionStatus.running;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatus obj) {
    switch (obj) {
      case SessionStatus.running:
        writer.writeByte(0);
        break;
      case SessionStatus.completed:
        writer.writeByte(1);
        break;
      case SessionStatus.broken:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
