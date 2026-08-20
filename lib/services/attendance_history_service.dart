import 'package:hive/hive.dart';

import '../models/attendance_history.dart';
import 'subject_service.dart';
import 'app_refresh_service.dart';

class AttendanceHistoryService {
  static const String boxName = "attendance_history";

  static late Box<AttendanceHistory> _box;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> init() async {
    _box = await Hive.openBox<AttendanceHistory>(boxName);
  }

  static bool get isInitialized => Hive.isBoxOpen(boxName);

  // ============================================================
  // HISTORY
  // ============================================================

  static List<AttendanceHistory> get history {
    if (!_box.isOpen) {
      return [];
    }

    final list = _box.values.toList();

    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return list;
  }

  // ============================================================
  // SAME DAY
  // ============================================================

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ============================================================
  // CHECK WHETHER MARKED TODAY
  // ============================================================

  static bool hasMarkedToday(String subjectName, {int? timetableKey}) {
    if (!_box.isOpen) {
      return false;
    }

    final now = DateTime.now();

    final normalizedName = subjectName.trim().toLowerCase();

    for (final record in _box.values) {
      if (!_isSameDay(record.dateTime, now)) {
        continue;
      }

      // --------------------------------------------------------
      // Exact timetable class matching
      // --------------------------------------------------------

      if (timetableKey != null && record.timetableKey != null) {
        if (record.timetableKey == timetableKey) {
          return true;
        }

        continue;
      }

      // --------------------------------------------------------
      // Legacy records without timetableKey
      // --------------------------------------------------------

      if (record.subjectName.trim().toLowerCase() == normalizedName) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  static bool isSubjectMarkedToday(String subjectName) {
    return hasMarkedToday(subjectName);
  }

  // ============================================================
  // TODAY RECORD
  // ============================================================

  static AttendanceHistory? getTodayRecord(
    String subjectName, {
    int? timetableKey,
  }) {
    if (!_box.isOpen) {
      return null;
    }

    final now = DateTime.now();

    final normalizedName = subjectName.trim().toLowerCase();

    for (final record in _box.values) {
      if (!_isSameDay(record.dateTime, now)) {
        continue;
      }

      // Exact timetable record
      if (timetableKey != null && record.timetableKey != null) {
        if (record.timetableKey == timetableKey) {
          return record;
        }

        continue;
      }

      // Legacy record
      if (record.subjectName.trim().toLowerCase() == normalizedName) {
        return record;
      }
    }

    return null;
  }

  // ============================================================
  // MARK ATTENDANCE
  //
  // AttendanceHistory + Subject counters are updated together.
  // ============================================================

  static Future<bool> markAttendance({
    required String subjectName,
    required bool isPresent,
    int? timetableKey,
    String semester = "",
    String faculty = "",
  }) async {
    if (!_box.isOpen) {
      return false;
    }

    final normalizedName = subjectName.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // DUPLICATE PROTECTION
    // ----------------------------------------------------------

    if (hasMarkedToday(subjectName, timetableKey: timetableKey)) {
      return false;
    }

    // ----------------------------------------------------------
    // ENSURE SUBJECT
    // ----------------------------------------------------------

    final subjectCreated = await SubjectService.ensureSubjectExists(
      subjectName: subjectName,
      semester: semester,
      faculty: faculty,
    );

    if (!subjectCreated) {
      return false;
    }

    // ----------------------------------------------------------
    // FIND SUBJECT
    // ----------------------------------------------------------

    final subjectIndex = SubjectService.getSubjectIndexByName(subjectName);

    if (subjectIndex == -1) {
      return false;
    }

    final subject = SubjectService.getSubject(subjectIndex);

    if (subject == null) {
      return false;
    }

    // ----------------------------------------------------------
    // SAVE OLD VALUES
    // ----------------------------------------------------------

    final oldPresent = subject.present;
    final oldAbsent = subject.absent;

    // ----------------------------------------------------------
    // UPDATE COUNTERS
    // ----------------------------------------------------------

    if (isPresent) {
      subject.present++;
    } else {
      subject.absent++;
    }

    final subjectUpdated = await SubjectService.updateAttendance(
      subjectIndex,
      subject,
      notify: false,
    );

    if (!subjectUpdated) {
      return false;
    }

    // ----------------------------------------------------------
    // SAVE HISTORY
    // ----------------------------------------------------------

    try {
      final record = AttendanceHistory(
        subjectName: subject.name,
        isPresent: isPresent,
        dateTime: DateTime.now(),
        timetableKey: timetableKey,
      );

      await _box.add(record);

      AppRefreshService.refresh();

      return true;
    } catch (_) {
      // --------------------------------------------------------
      // ROLLBACK SUBJECT COUNTER
      // --------------------------------------------------------

      subject.present = oldPresent;
      subject.absent = oldAbsent;

      await SubjectService.updateAttendance(subjectIndex, subject);

      return false;
    }
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  static Future<void> addHistory({
    required String subjectName,
    required bool isPresent,
  }) async {
    await markAttendance(subjectName: subjectName, isPresent: isPresent);
  }

  // ============================================================
  // DELETE HISTORY + SYNC SUBJECT
  // ============================================================

  static Future<bool> deleteHistoryAndSync(AttendanceHistory record) async {
    if (!_box.isOpen) {
      return false;
    }

    try {
      await record.delete();

      await _recalculateSubjectCounts(record.subjectName);

      AppRefreshService.refresh();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RECALCULATE ONE SUBJECT
  // ============================================================

  static Future<void> _recalculateSubjectCounts(String subjectName) async {
    final subjectIndex = SubjectService.getSubjectIndexByName(subjectName);

    if (subjectIndex == -1) {
      return;
    }

    final normalized = subjectName.trim().toLowerCase();

    int present = 0;
    int absent = 0;

    for (final record in _box.values) {
      if (record.subjectName.trim().toLowerCase() != normalized) {
        continue;
      }

      if (record.isPresent) {
        present++;
      } else {
        absent++;
      }
    }

    final subject = SubjectService.getSubject(subjectIndex);

    if (subject == null) {
      return;
    }

    subject.present = present;
    subject.absent = absent;

    await SubjectService.updateAttendance(subjectIndex, subject, notify: false);
  }

  // ============================================================
  // CLEAR HISTORY + RESET SUBJECT COUNTERS
  // ============================================================

  static Future<bool> clearHistoryAndSync() async {
    if (!_box.isOpen) {
      return false;
    }

    try {
      await _box.clear();

      final count = SubjectService.subjectCount;

      for (int i = 0; i < count; i++) {
        final subject = SubjectService.getSubject(i);

        if (subject == null) {
          continue;
        }

        subject.present = 0;
        subject.absent = 0;

        await SubjectService.updateAttendance(i, subject, notify: false);
      }

      AppRefreshService.refresh();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REBUILD ALL SUBJECT COUNTS
  //
  // Useful for repairing old data.
  // ============================================================

  static Future<void> rebuildAllSubjectCounts() async {
    if (!_box.isOpen) {
      return;
    }

    final allSubjects = SubjectService.subjects;

    for (int i = 0; i < allSubjects.length; i++) {
      final subject = allSubjects[i];

      final normalized = subject.name.trim().toLowerCase();

      int present = 0;
      int absent = 0;

      for (final record in _box.values) {
        if (record.subjectName.trim().toLowerCase() != normalized) {
          continue;
        }

        if (record.isPresent) {
          present++;
        } else {
          absent++;
        }
      }

      subject.present = present;
      subject.absent = absent;

      await SubjectService.updateAttendance(i, subject, notify: false);
    }

    AppRefreshService.refresh();
  }

  // ============================================================
  // DELETE ALL HISTORY FOR SUBJECT
  // ============================================================

  static Future<bool> deleteSubjectHistory(String subjectName) async {
    if (!_box.isOpen) {
      return false;
    }

    final normalized = subjectName.trim().toLowerCase();

    final records = _box.values
        .where(
          (record) => record.subjectName.trim().toLowerCase() == normalized,
        )
        .toList();

    for (final record in records) {
      await record.delete();
    }

    AppRefreshService.refresh();

    return true;
  }

  // ============================================================
  // OLD METHODS
  // ============================================================

  static Future<void> deleteHistory(AttendanceHistory record) async {
    await deleteHistoryAndSync(record);
  }

  static Future<void> clearHistory() async {
    await clearHistoryAndSync();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  static int get totalPresent {
    if (!_box.isOpen) {
      return 0;
    }

    return _box.values.where((record) => record.isPresent).length;
  }

  static int get totalAbsent {
    if (!_box.isOpen) {
      return 0;
    }

    return _box.values.where((record) => !record.isPresent).length;
  }

  static int get totalRecords {
    if (!_box.isOpen) {
      return 0;
    }

    return _box.length;
  }
}
