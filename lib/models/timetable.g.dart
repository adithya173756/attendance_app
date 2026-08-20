// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableAdapter extends TypeAdapter<Timetable> {
  @override
  final int typeId = 5;

  @override
  Timetable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Timetable(
      subject: fields[0] as String,
      faculty: fields[1] as String,
      room: fields[2] as String,
      day: fields[3] as String,
      startTime: fields[4] as String,
      endTime: fields[5] as String,
      department: fields[6] as String,
      section: fields[7] as String,
    )
      .._period = fields[8] as int?
      .._effectiveFrom = fields[9] as DateTime?
      .._semester = fields[10] as String?;
  }

  @override
  void write(BinaryWriter writer, Timetable obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.faculty)
      ..writeByte(2)
      ..write(obj.room)
      ..writeByte(3)
      ..write(obj.day)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.department)
      ..writeByte(7)
      ..write(obj.section)
      ..writeByte(8)
      ..write(obj._period)
      ..writeByte(9)
      ..write(obj._effectiveFrom)
      ..writeByte(10)
      ..write(obj._semester);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
