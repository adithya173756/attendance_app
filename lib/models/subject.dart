import '../utils/attendance_calculator.dart';

class Subject {
  String name;
  String semester;
  String faculty;
  double minimumAttendance;
  int present;
  int absent;

  Subject({
    required this.name,
    required this.semester,
    required this.faculty,
    required this.minimumAttendance,
    this.present = 0,
    this.absent = 0,
  });

  // ============================================================
  // TOTAL CLASSES
  // ============================================================

  int get total => present + absent;

  int get totalClasses => present + absent;

  // ============================================================
  // CURRENT ATTENDANCE
  // ============================================================

  double get percentage {
    return AttendanceCalculator.percentage(present, absent);
  }

  // ============================================================
  // CLASSES NEEDED FOR A TARGET
  // ============================================================

  int classesNeededFor(double target) {
    return AttendanceCalculator.classesNeeded(present, absent, target);
  }

  bool canReachTarget(double target) {
    return AttendanceCalculator.canReachTarget(present, absent, target);
  }

  // ============================================================
  // CLASSES NEEDED FOR SUBJECT MINIMUM
  // ============================================================

  int get classesNeeded {
    return classesNeededFor(minimumAttendance);
  }

  // Backward compatibility
  int get classesNeededFor75 {
    return classesNeeded;
  }

  // ============================================================
  // SAFE BUNKS FOR A TARGET
  // ============================================================

  int safeBunksFor(double target) {
    return AttendanceCalculator.safeBunks(present, absent, target);
  }

  // ============================================================
  // SAFE BUNKS FOR SUBJECT MINIMUM
  // ============================================================

  int get safeBunks {
    return safeBunksFor(minimumAttendance);
  }

  // ============================================================
  // MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'semester': semester,
      'faculty': faculty,
      'minimumAttendance': minimumAttendance,
      'present': present,
      'absent': absent,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory Subject.fromMap(Map<dynamic, dynamic> map) {
    return Subject(
      name: map['name'] ?? '',
      semester: map['semester'] ?? '',
      faculty: map['faculty'] ?? '',
      minimumAttendance: (map['minimumAttendance'] as num?)?.toDouble() ?? 75,
      present: (map['present'] as num?)?.toInt() ?? 0,
      absent: (map['absent'] as num?)?.toInt() ?? 0,
    );
  }
}
