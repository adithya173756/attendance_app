import 'package:hive/hive.dart';

part 'timetable.g.dart';

@HiveType(typeId: 5)
class Timetable extends HiveObject {
  @HiveField(0)
  String subject;

  @HiveField(1)
  String faculty;

  @HiveField(2)
  String room;

  @HiveField(3)
  String day;

  @HiveField(4)
  String startTime;

  @HiveField(5)
  String endTime;

  @HiveField(6)
  String department;

  @HiveField(7)
  String section;

  // Stored as nullable so old Hive records are supported.
  @HiveField(8)
  int? _period;

  // Stored as nullable so old Hive records are supported.
  @HiveField(9)
  DateTime? _effectiveFrom;

  // Semester of this timetable.
  //
  // Nullable internally so old Hive records that were created
  // before semester support was added will not cause problems.
  @HiveField(10)
  String? _semester;

  // ============================================================
  // PERIOD
  // ============================================================

  int get period => _period ?? 0;

  set period(int value) {
    _period = value;
  }

  // ============================================================
  // EFFECTIVE FROM
  // ============================================================

  DateTime get effectiveFrom => _effectiveFrom ?? DateTime(2026, 6, 15);

  set effectiveFrom(DateTime value) {
    _effectiveFrom = value;
  }

  // ============================================================
  // SEMESTER
  // ============================================================

  String get semester => _semester ?? "";

  set semester(String value) {
    _semester = value;
  }

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  Timetable({
    required this.subject,
    required this.faculty,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.department = "CSIT",
    this.section = "A",
    String semester = "3-1",
    int period = 0,
    DateTime? effectiveFrom,
  }) {
    _period = period;
    _effectiveFrom = effectiveFrom ?? DateTime(2026, 6, 15);
    _semester = semester;
  }
}
