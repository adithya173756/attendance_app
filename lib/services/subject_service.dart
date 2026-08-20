import 'package:hive_flutter/hive_flutter.dart';

import '../models/subject.dart';
import 'student_service.dart';
import 'attendance_goal_service.dart';
import '../utils/attendance_calculator.dart';
import 'app_refresh_service.dart';

class SubjectService {
  static const String boxName = "subjects";

  static late Box _box;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  static bool get isInitialized => Hive.isBoxOpen(boxName);

  // ============================================================
  // SUBJECT LIST
  // ============================================================

  static List<Subject> get subjects {
    if (!_box.isOpen) {
      return [];
    }

    return _box.values
        .map((e) => Subject.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  static int get subjectCount => subjects.length;

  // ============================================================
  // GET SUBJECT
  // ============================================================

  static Subject? getSubject(int index) {
    final list = subjects;

    if (index < 0 || index >= list.length) {
      return null;
    }

    return list[index];
  }

  // ============================================================
  // GET SUBJECT BY NAME
  // ============================================================

  static Subject? getSubjectByName(String subjectName) {
    final normalizedName = subjectName.trim().toLowerCase();

    for (final subject in subjects) {
      if (subject.name.trim().toLowerCase() == normalizedName) {
        return subject;
      }
    }

    return null;
  }

  // ============================================================
  // GET SUBJECT INDEX BY NAME
  // ============================================================

  static int getSubjectIndexByName(String subjectName) {
    final normalizedName = subjectName.trim().toLowerCase();

    final list = subjects;

    for (int i = 0; i < list.length; i++) {
      if (list[i].name.trim().toLowerCase() == normalizedName) {
        return i;
      }
    }

    return -1;
  }

  // ============================================================
  // ADD SUBJECT
  // ============================================================

  static Future<bool> addSubject(Subject subject) async {
    if (!_box.isOpen) {
      return false;
    }

    final exists = subjects.any(
      (item) =>
          item.name.trim().toLowerCase() == subject.name.trim().toLowerCase(),
    );

    if (exists) {
      return false;
    }

    await _box.add(subject.toMap());

    AppRefreshService.refresh();

    return true;
  }

  // ============================================================
  // ENSURE SUBJECT EXISTS
  // ============================================================

  static Future<bool> ensureSubjectExists({
    required String subjectName,
    String semester = "",
    String faculty = "",
  }) async {
    final normalizedName = subjectName.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      return false;
    }

    final existing = subjects.any(
      (subject) => subject.name.trim().toLowerCase() == normalizedName,
    );

    if (existing) {
      return true;
    }

    String finalSemester = semester.trim();

    if (finalSemester.isEmpty) {
      final student = await StudentService.getStudent();

      if (student != null) {
        finalSemester = student.semester;
      }
    }

    final newSubject = Subject(
      name: subjectName.trim(),
      semester: finalSemester,
      faculty: faculty.trim(),
      minimumAttendance: 75,
      present: 0,
      absent: 0,
    );

    return addSubject(newSubject);
  }

  // ============================================================
  // ADD MULTIPLE SUBJECTS
  // ============================================================

  static Future<void> addMultipleSubjects(List<Subject> newSubjects) async {
    for (final subject in newSubjects) {
      await addSubject(subject);
    }
  }

  // ============================================================
  // UPDATE SUBJECT
  // ============================================================

  static Future<bool> updateSubject(int index, Subject subject) async {
    if (!_box.isOpen) {
      return false;
    }

    if (index < 0 || index >= _box.length) {
      return false;
    }

    final currentSubjects = subjects;

    for (int i = 0; i < currentSubjects.length; i++) {
      if (i == index) {
        continue;
      }

      if (currentSubjects[i].name.trim().toLowerCase() ==
          subject.name.trim().toLowerCase()) {
        return false;
      }
    }

    await _box.putAt(index, subject.toMap());

    AppRefreshService.refresh();

    return true;
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  static Future<bool> deleteSubject(int index) async {
    if (!_box.isOpen) {
      return false;
    }

    if (index < 0 || index >= _box.length) {
      return false;
    }

    await _box.deleteAt(index);

    AppRefreshService.refresh();

    return true;
  }

  // ============================================================
  // DELETE ALL SUBJECTS
  // ============================================================

  static Future<void> clearAllSubjects() async {
    if (!_box.isOpen) {
      return;
    }

    await _box.clear();

    AppRefreshService.refresh();
  }

  // ============================================================
  // REPLACE SUBJECTS FROM IMPORTED TIMETABLE
  // ============================================================

  static Future<void> replaceSubjects(List<Subject> newSubjects) async {
    if (!_box.isOpen) {
      return;
    }

    final oldSubjects = subjects;

    final List<Subject> finalSubjects = [];

    for (final newSubject in newSubjects) {
      final normalizedName = newSubject.name.trim().toLowerCase();

      Subject? oldSubject;

      for (final oldSubjectItem in oldSubjects) {
        if (oldSubjectItem.name.trim().toLowerCase() == normalizedName) {
          oldSubject = oldSubjectItem;
          break;
        }
      }

      if (oldSubject != null) {
        finalSubjects.add(
          Subject(
            name: newSubject.name,
            semester: newSubject.semester,
            faculty: newSubject.faculty,
            minimumAttendance: newSubject.minimumAttendance,
            present: oldSubject.present,
            absent: oldSubject.absent,
          ),
        );
      } else {
        finalSubjects.add(newSubject);
      }
    }

    await _box.clear();

    for (final subject in finalSubjects) {
      await _box.add(subject.toMap());
    }

    AppRefreshService.refresh();
  }

  // ============================================================
  // PROFILE SYNC
  // ============================================================

  static Future<void> syncWithStudentProfile() async {
    if (!_box.isOpen) {
      return;
    }

    // Intentionally empty.
    //
    // Subjects come from timetable/PDF import.
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  static Future<void> addDefaultSubjects() async {
    await syncWithStudentProfile();
  }

  // ============================================================
  // MARK PRESENT
  // ============================================================

  static Future<bool> markPresent(int index) async {
    final subject = getSubject(index);

    if (subject == null) {
      return false;
    }

    subject.present++;

    return updateAttendance(index, subject);
  }

  // ============================================================
  // MARK ABSENT
  // ============================================================

  static Future<bool> markAbsent(int index) async {
    final subject = getSubject(index);

    if (subject == null) {
      return false;
    }

    subject.absent++;

    return updateAttendance(index, subject);
  }

  // ============================================================
  // UNDO PRESENT
  // ============================================================

  static Future<bool> undoPresent(int index) async {
    final subject = getSubject(index);

    if (subject == null || subject.present <= 0) {
      return false;
    }

    subject.present--;

    return updateAttendance(index, subject);
  }

  // ============================================================
  // UNDO ABSENT
  // ============================================================

  static Future<bool> undoAbsent(int index) async {
    final subject = getSubject(index);

    if (subject == null || subject.absent <= 0) {
      return false;
    }

    subject.absent--;

    return updateAttendance(index, subject);
  }

  // ============================================================
  // RESET ATTENDANCE
  // ============================================================

  static Future<bool> resetAttendance(int index) async {
    final subject = getSubject(index);

    if (subject == null) {
      return false;
    }

    subject.present = 0;
    subject.absent = 0;

    return updateAttendance(index, subject);
  }

  // ============================================================
  // INTERNAL ATTENDANCE UPDATE
  // ============================================================

  static Future<bool> updateAttendance(
    int index,
    Subject subject, {
    bool notify = true,
  }) async {
    if (!_box.isOpen) {
      return false;
    }

    if (index < 0 || index >= _box.length) {
      return false;
    }

    await _box.putAt(index, subject.toMap());

    if (notify) {
      AppRefreshService.refresh();
    }

    return true;
  }

  // ============================================================
  // TOTAL PRESENT
  // ============================================================

  static int get totalPresent {
    return subjects.fold(0, (sum, subject) => sum + subject.present);
  }

  // ============================================================
  // TOTAL ABSENT
  // ============================================================

  static int get totalAbsent {
    return subjects.fold(0, (sum, subject) => sum + subject.absent);
  }

  // ============================================================
  // TOTAL CLASSES
  // ============================================================

  static int get totalClasses {
    return subjects.fold(0, (sum, subject) => sum + subject.total);
  }

  // ============================================================
  // OVERALL ATTENDANCE
  // ============================================================

  static double get overallAttendance {
    final classes = totalClasses;

    if (classes == 0) {
      return 0.0;
    }

    return (totalPresent / classes) * 100.0;
  }

  // ============================================================
  // LOWEST ATTENDANCE
  // ============================================================

  static Subject? get lowestAttendanceSubject {
    final list = [...subjects];

    if (list.isEmpty) {
      return null;
    }

    list.sort((a, b) => a.percentage.compareTo(b.percentage));

    return list.first;
  }

  // ============================================================
  // HIGHEST ATTENDANCE
  // ============================================================

  static Subject? get highestAttendanceSubject {
    final list = [...subjects];

    if (list.isEmpty) {
      return null;
    }

    list.sort((a, b) => b.percentage.compareTo(a.percentage));

    return list.first;
  }

  // ============================================================
  // TOTAL SAFE BUNKS
  // ============================================================

  static int get totalSafeBunks {
    return subjects.fold(0, (sum, subject) => sum + subject.safeBunks);
  }

  // ============================================================
  // TOTAL CLASSES NEEDED
  // ============================================================

  static int get totalClassesNeededForGoal {
    return subjects.fold(
      0,
      (sum, subject) => sum + _classesNeededForGoal(subject),
    );
  }

  static int _classesNeededForGoal(Subject subject) {
    return AttendanceCalculator.classesNeeded(
      subject.present,
      subject.absent,
      AttendanceGoalService.goal,
    );
  }
}
