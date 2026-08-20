import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/timetable.dart';
import '../models/subject.dart';
import 'subject_service.dart';
import 'app_refresh_service.dart';

class TimetableService {
  static const String boxName = "timetable";

  static late Box<Timetable> _box;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> init() async {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<Timetable>(boxName);
      return;
    }

    _box = await Hive.openBox<Timetable>(boxName);
  }

  // ============================================================
  // CHECK BOX
  // ============================================================

  static bool get isReady {
    return Hive.isBoxOpen(boxName);
  }

  // ============================================================
  // ALL TIMETABLE CLASSES
  // ============================================================

  static List<Timetable> get timetable {
    if (!isReady) {
      return [];
    }

    return _box.values.toList();
  }

  // ============================================================
  // EMPTY
  // ============================================================

  static bool get isEmpty {
    if (!isReady) {
      return true;
    }

    return _box.isEmpty;
  }

  // ============================================================
  // COUNT
  // ============================================================

  static int get classCount {
    if (!isReady) {
      return 0;
    }

    return _box.length;
  }

  static void debugPrintTimetable() {
    if (!isReady) {
      debugPrint("TIMETABLE DEBUG: Hive box is NOT ready");
      return;
    }

    debugPrint("========== TIMETABLE DEBUG ==========");

    debugPrint("Total classes: ${_box.length}");

    for (final item in _box.values) {
      debugPrint(
        "SUBJECT=${item.subject} | "
        "DAY=${item.day} | "
        "PERIOD=${item.period} | "
        "DEPT=${item.department} | "
        "SEM=${item.semester} | "
        "SECTION=${item.section} | "
        "TIME=${item.startTime}-${item.endTime}",
      );
    }

    debugPrint("====================================");
  }

  // ============================================================
  // GET CLASSES FOR DAY
  // ============================================================

  static List<Timetable> getDayClasses(
    String day, {
    String? department,
    String? section,
    String? semester,
  }) {
    if (!isReady) {
      return [];
    }

    final requestedDay = day.trim().toLowerCase();
    final requestedDepartment = department?.trim().toLowerCase();
    final requestedSection = section?.trim().toLowerCase();
    final requestedSemester = semester?.trim().toLowerCase();

    final classes = _box.values.where((item) {
      // ----------------------------------------------------------
      // DAY
      // ----------------------------------------------------------

      final dayMatch = item.day.trim().toLowerCase() == requestedDay;

      if (!dayMatch) {
        return false;
      }

      // ----------------------------------------------------------
      // DEPARTMENT
      // ----------------------------------------------------------

      if (requestedDepartment != null && requestedDepartment.isNotEmpty) {
        final itemDepartment = item.department.trim().toLowerCase();

        if (itemDepartment != requestedDepartment) {
          return false;
        }
      }

      // ----------------------------------------------------------
      // SECTION
      // ----------------------------------------------------------

      if (requestedSection != null && requestedSection.isNotEmpty) {
        final itemSection = item.section.trim().toLowerCase();

        if (itemSection != requestedSection) {
          return false;
        }
      }

      // ----------------------------------------------------------
      // SEMESTER
      // ----------------------------------------------------------

      if (requestedSemester != null && requestedSemester.isNotEmpty) {
        final itemSemester = item.semester.trim().toLowerCase();

        if (itemSemester != requestedSemester) {
          return false;
        }
      }

      return true;
    }).toList();

    // ==========================================================
    // SORT BY START TIME
    // ==========================================================

    classes.sort((a, b) {
      return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
    });

    return classes;
  }

  // ============================================================
  // GET CLASSES FOR SPECIFIC DATE
  // ============================================================

  static List<Timetable> getClassesForDate(
    DateTime date, {
    required String department,
    required String section,
    required String semester,
  }) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    final day = days[date.weekday - 1];

    final classes = getDayClasses(
      day,
      department: department,
      section: section,
      semester: semester,
    );

    final selectedDate = DateTime(date.year, date.month, date.day);

    return classes.where((item) {
      final effectiveDate = DateTime(
        item.effectiveFrom.year,
        item.effectiveFrom.month,
        item.effectiveFrom.day,
      );

      return !selectedDate.isBefore(effectiveDate);
    }).toList();
  }

  // ============================================================
  // CURRENT CLASS
  // ============================================================

  static Timetable? getCurrentClass({
    required String department,
    required String section,
    required String semester,
  }) {
    final now = DateTime.now();

    final classes = getClassesForDate(
      now,
      department: department,
      section: section,
      semester: semester,
    );

    final currentMinutes = now.hour * 60 + now.minute;

    for (final item in classes) {
      final start = _timeToMinutes(item.startTime);
      final end = _timeToMinutes(item.endTime);

      if (currentMinutes >= start && currentMinutes < end) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // NEXT CLASS
  // ============================================================

  static Timetable? getNextClass({
    required String department,
    required String section,
    required String semester,
  }) {
    final now = DateTime.now();

    final classes = getClassesForDate(
      now,
      department: department,
      section: section,
      semester: semester,
    );

    final currentMinutes = now.hour * 60 + now.minute;

    for (final item in classes) {
      final start = _timeToMinutes(item.startTime);

      if (start > currentMinutes) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // ADD CLASS
  // ============================================================

  static Future<bool> addClass(Timetable value) async {
    if (!isReady) {
      return false;
    }

    await _box.add(value);
    AppRefreshService.refresh();

    return true;
  }

  // ============================================================
  // ADD MULTIPLE CLASSES
  // ============================================================

  static Future<void> addClasses(List<Timetable> values) async {
    if (!isReady || values.isEmpty) {
      return;
    }

    await _box.addAll(values);
    AppRefreshService.refresh();
  }

  // ============================================================
  // UPDATE CLASS
  // ============================================================

  static Future<void> updateClass(Timetable value) async {
    await value.save();
    AppRefreshService.refresh();
  }

  // ============================================================
  // DELETE CLASS
  // ============================================================

  static Future<void> deleteClass(Timetable value) async {
    await value.delete();
    AppRefreshService.refresh();
  }

  // ============================================================
  // CLEAR TIMETABLE
  // ============================================================

  static Future<void> clearTimetable() async {
    if (!isReady) {
      return;
    }

    await _box.clear();
    AppRefreshService.refresh();
  }

  // ============================================================
  // REPLACE TIMETABLE
  // ============================================================

  static Future<void> replaceTimetable(List<Timetable> newTimetable) async {
    if (!isReady) {
      return;
    }

    await _box.clear();

    if (newTimetable.isNotEmpty) {
      await _box.addAll(newTimetable);
    }
    AppRefreshService.refresh();
  }

  // ============================================================
  // REPLACE TIMETABLE + SYNC SUBJECTS
  //
  // Imported timetable becomes the source of truth.
  //
  // Flow:
  //
  // PDF / Timetable Import
  //        ↓
  // List<Timetable>
  //        ↓
  // Save Timetable
  //        ↓
  // Extract unique subjects
  //        ↓
  // SubjectService.replaceSubjects()
  //        ↓
  // My Subjects automatically updated
  //
  // Existing attendance is preserved by replaceSubjects().
  // ============================================================

  static Future<void> replaceTimetableAndSyncSubjects(
    List<Timetable> newTimetable,
  ) async {
    if (!isReady) {
      return;
    }

    // ----------------------------------------------------------
    // 1. REPLACE TIMETABLE
    // ----------------------------------------------------------

    await _box.clear();

    if (newTimetable.isNotEmpty) {
      await _box.addAll(newTimetable);
    }

    // ----------------------------------------------------------
    // 2. EXTRACT UNIQUE SUBJECTS
    // ----------------------------------------------------------

    final Map<String, Subject> uniqueSubjects = {};

    for (final item in newTimetable) {
      final subjectName = item.subject.trim();

      if (subjectName.isEmpty) {
        continue;
      }

      final normalizedName = subjectName.toLowerCase();

      // Keep only one Subject for duplicate timetable entries.
      if (!uniqueSubjects.containsKey(normalizedName)) {
        uniqueSubjects[normalizedName] = Subject(
          name: subjectName,
          semester: item.semester.trim(),
          faculty: item.faculty.trim(),
          minimumAttendance: 75,
          present: 0,
          absent: 0,
        );
      }
    }

    // ----------------------------------------------------------
    // 3. REPLACE SUBJECTS
    //
    // This preserves existing attendance for subjects that
    // already exist.
    // ----------------------------------------------------------

    await SubjectService.replaceSubjects(uniqueSubjects.values.toList());
    AppRefreshService.refresh();
  }

  // ============================================================
  // CHECK OVERLAP
  // ============================================================

  static bool hasOverlap({
    required String day,
    required int startMinutes,
    required int endMinutes,
    required String department,
    required String section,
    required String semester,
    Timetable? excludeClass,
  }) {
    final classes = getDayClasses(
      day,
      department: department,
      section: section,
      semester: semester,
    );

    for (final item in classes) {
      if (excludeClass != null && item.key == excludeClass.key) {
        continue;
      }

      final existingStart = _timeToMinutes(item.startTime);

      final existingEnd = _timeToMinutes(item.endTime);

      final overlaps = startMinutes < existingEnd && endMinutes > existingStart;

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // TIME TO MINUTES
  // ============================================================

  static int _timeToMinutes(String time) {
    final clean = time.trim().toUpperCase();

    final isPM = clean.contains("PM");
    final isAM = clean.contains("AM");

    final value = clean.replaceAll("AM", "").replaceAll("PM", "").trim();

    final parts = value.split(":");

    if (parts.length != 2) {
      return 0;
    }

    int hour = int.tryParse(parts[0]) ?? 0;

    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour != 12) {
      hour += 12;
    }

    if (isAM && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }
}
