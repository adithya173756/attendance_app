import 'package:hive/hive.dart';
import '../models/assignment.dart';

class AssignmentService {
  static const String boxName = "assignments";

  static late Box<Assignment> _box;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static Future<void> init() async {
    _box = await Hive.openBox<Assignment>(boxName);
  }

  static bool get isInitialized => Hive.isBoxOpen(boxName);

  // ============================================================
  // ALL ASSIGNMENTS
  // ============================================================

  static List<Assignment> get assignments {
    if (!_box.isOpen) return [];

    final list = _box.values.toList();

    // Upcoming assignments first
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  // ============================================================
  // PENDING ASSIGNMENTS
  // ============================================================

  static List<Assignment> get pendingAssignments {
    return assignments.where((assignment) {
      return !assignment.completed;
    }).toList();
  }

  // ============================================================
  // COMPLETED ASSIGNMENTS
  // ============================================================

  static List<Assignment> get completedAssignments {
    return assignments.where((assignment) {
      return assignment.completed;
    }).toList();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  static int get totalAssignments => _box.length;

  static int get pendingCount => pendingAssignments.length;

  static int get completedCount => completedAssignments.length;

  // ============================================================
  // ADD ASSIGNMENT
  // ============================================================

  static Future<void> addAssignment(Assignment assignment) async {
    await _box.add(assignment);
  }

  // ============================================================
  // UPDATE ASSIGNMENT
  // ============================================================

  static Future<void> updateAssignment(Assignment assignment) async {
    await assignment.save();
  }

  // ============================================================
  // MARK COMPLETED
  // ============================================================

  static Future<void> markCompleted(Assignment assignment) async {
    assignment.completed = true;

    await assignment.save();
  }

  // ============================================================
  // MARK PENDING
  // ============================================================

  static Future<void> markPending(Assignment assignment) async {
    assignment.completed = false;

    await assignment.save();
  }

  // ============================================================
  // DELETE ASSIGNMENT
  // ============================================================

  static Future<void> deleteAssignment(Assignment assignment) async {
    await assignment.delete();
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
