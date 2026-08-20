import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import '../services/attendance_goal_service.dart';
import '../services/attendance_history_service.dart';
import '../utils/app_colors.dart';
import 'edit_subject_screen.dart';
import 'attendance_trend_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;
  final int subjectIndex;

  const SubjectDetailsScreen({
    super.key,
    required this.subject,
    required this.subjectIndex,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  // ============================================================
  // MARK PRESENT
  // ============================================================

  Future<void> _markPresent() async {
    final subject = SubjectService.getSubject(widget.subjectIndex);

    if (subject == null) {
      return;
    }

    final alreadyMarked = AttendanceHistoryService.hasMarkedToday(subject.name);

    if (alreadyMarked) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance already marked for this subject today"),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final success = await AttendanceHistoryService.markAttendance(
      subjectName: subject.name,
      isPresent: true,
      semester: subject.semester,
      faculty: subject.faculty,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marked Present"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to mark attendance. It may already be marked today.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ============================================================
  // MARK ABSENT
  // ============================================================

  Future<void> _markAbsent() async {
    final subject = SubjectService.getSubject(widget.subjectIndex);

    if (subject == null) {
      return;
    }

    final alreadyMarked = AttendanceHistoryService.hasMarkedToday(subject.name);

    if (alreadyMarked) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance already marked for this subject today"),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final success = await AttendanceHistoryService.markAttendance(
      subjectName: subject.name,
      isPresent: false,
      semester: subject.semester,
      faculty: subject.faculty,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marked Absent"),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to mark attendance. It may already be marked today.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ============================================================
  // RESET ATTENDANCE
  // ============================================================

  Future<void> _resetAttendance() async {
    final subject = SubjectService.getSubject(widget.subjectIndex);

    if (subject == null) {
      return;
    }

    if (subject.total == 0) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance is already empty")),
      );

      return;
    }

    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Reset Attendance"),
          content: Text(
            "Reset attendance for ${subject.name}?\n\n"
            "Present: ${subject.present}\n"
            "Absent: ${subject.absent}\n\n"
            "Both values will be set to 0.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Reset"),
            ),
          ],
        );
      },
    );

    if (reset != true) return;

    // Attendance history is the source of truth. Remove the records first,
    // then rebuild the visible subject state from storage.
    final success = await AttendanceHistoryService.deleteSubjectHistory(
      subject.name,
    );
    if (success) {
      await SubjectService.resetAttendance(widget.subjectIndex);
    }

    if (!mounted) return;

    if (success) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance reset successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to reset attendance"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  Future<void> _deleteSubject() async {
    final subject = SubjectService.getSubject(widget.subjectIndex);

    if (subject == null) {
      return;
    }

    final delete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Subject"),
          content: Text("Are you sure you want to delete ${subject.name}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (delete != true) return;

    await SubjectService.deleteSubject(widget.subjectIndex);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ============================================================
  // EDIT SUBJECT
  // ============================================================

  Future<void> _editSubject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSubjectScreen(
          subject: widget.subject,
          subjectIndex: widget.subjectIndex,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Always get the latest subject from Hive.
    final subject = SubjectService.getSubject(widget.subjectIndex);

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Subject")),
        body: const Center(child: Text("Subject not found")),
      );
    }

    final double attendanceGoal = AttendanceGoalService.goal;

    final int totalClasses = subject.total;

    final double percentage = subject.percentage;

    final bool isStarted = totalClasses > 0;

    final bool isSafe = isStarted && percentage >= attendanceGoal;

    final int safeBunks = subject.safeBunksFor(attendanceGoal);

    final int classesNeeded = subject.classesNeededFor(attendanceGoal);

    // ----------------------------------------------------------
    // PREDICTIONS
    // ----------------------------------------------------------

    final double predictedAttendance = totalClasses == 0
        ? 0
        : ((subject.present + 5) / (totalClasses + 5)) * 100;

    final double nextBunkAttendance = totalClasses == 0
        ? 0
        : (subject.present / (totalClasses + 1)) * 100;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: "Attendance Trend",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceTrendScreen(subject: subject),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Subject",
            onPressed: _editSubject,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Reset Attendance",
            onPressed: _resetAttendance,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Delete Subject",
            onPressed: _deleteSubject,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // ATTENDANCE CIRCLE
            // ==================================================

            if (isStarted)
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 10,
              )
            else
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(value: 0, strokeWidth: 10),
              ),

            const SizedBox(height: 20),

            Text(
              isStarted ? "${percentage.toStringAsFixed(1)}%" : "Not Started",
              style: TextStyle(
                fontSize: isStarted ? 34 : 26,
                fontWeight: FontWeight.bold,
                color: isStarted ? AppColors.primary : Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isStarted
                  ? "Current Attendance"
                  : "Attendance tracking has not started",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SUBJECT INFORMATION
            // ==================================================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text("Semester"),
                      subtitle: Text(subject.semester),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text("Faculty"),
                      subtitle: Text(
                        subject.faculty.isEmpty
                            ? "Not Available"
                            : subject.faculty,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.flag),
                      title: const Text("Required Attendance"),
                      subtitle: Text("${attendanceGoal.toStringAsFixed(0)}%"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.percent),
                      title: const Text("Subject Minimum"),
                      subtitle: Text(
                        "${subject.minimumAttendance.toStringAsFixed(0)}%",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRESENT / ABSENT
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${subject.present}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("Present"),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "${subject.absent}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("Absent"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TOTAL CLASSES
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.class_),
                title: const Text("Total Classes"),
                trailing: Text(
                  "$totalClasses",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ATTENDANCE STATUS
            // ==================================================
            Card(
              color: !isStarted
                  ? Colors.grey.shade100
                  : isSafe
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      !isStarted
                          ? Icons.menu_book
                          : isSafe
                          ? Icons.celebration
                          : Icons.warning_amber_rounded,
                      color: !isStarted
                          ? Colors.grey
                          : isSafe
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        !isStarted
                            ? "Attendance tracking has not started yet."
                            : isSafe
                            ? "You can bunk $safeBunks more "
                                  "class(es) and stay above "
                                  "${attendanceGoal.toStringAsFixed(0)}%."
                            : "Attend $classesNeeded more "
                                  "class(es) continuously to reach "
                                  "${attendanceGoal.toStringAsFixed(0)}%.",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ATTENDANCE INSIGHTS
            // ==================================================
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attendance Insights",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isStarted
                                ? "Attendance: "
                                      "${percentage.toStringAsFixed(1)}%"
                                : "Attendance: Not Started",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.class_, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Classes Attended: "
                            "${subject.present}/$totalClasses",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          !isStarted
                              ? Icons.menu_book
                              : isSafe
                              ? Icons.verified
                              : Icons.error,
                          color: !isStarted
                              ? Colors.grey
                              : isSafe
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            !isStarted
                                ? "No attendance has been "
                                      "recorded yet."
                                : isSafe
                                ? "You are above the "
                                      "required "
                                      "${attendanceGoal.toStringAsFixed(0)}%."
                                : "You are below the "
                                      "required "
                                      "${attendanceGoal.toStringAsFixed(0)}%.",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ATTENDANCE PREDICTION
            // ==================================================
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attendance Prediction",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (!isStarted)
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Prediction will be available "
                              "after attendance is recorded.",
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "If you attend next 5 classes: "
                              "${predictedAttendance.toStringAsFixed(1)}%",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.trending_down, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "If you bunk next class: "
                              "${nextBunkAttendance.toStringAsFixed(1)}%",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // MARK PRESENT
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Mark Present"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _markPresent,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // MARK ABSENT
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Mark Absent"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _markAbsent,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
