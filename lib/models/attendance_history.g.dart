// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceHistoryAdapter extends TypeAdapter<AttendanceHistory> {
  @override
  final int typeId = 2;

  @override
  AttendanceHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceHistory(
      subjectName: fields[0] as String,
      isPresent: fields[1] as bool,
      dateTime: fields[2] as DateTime,
      timetableKey: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.subjectName)
      ..writeByte(1)
      ..write(obj.isPresent)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.timetableKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
