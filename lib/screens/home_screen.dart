import 'dart:async';

import 'package:flutter/material.dart';

import 'timetable_screen.dart';
import 'assignment_screen.dart';
import 'profile_screen.dart';

import '../services/subject_service.dart';
import '../services/timetable_service.dart';
import '../services/pdf_service.dart';
import '../services/attendance_notification_service.dart';
import '../services/student_service.dart';
import '../services/attendance_goal_service.dart';
import '../services/attendance_history_service.dart';

import '../widgets/dashboard_insights.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primary = Color(0xFF386A92);
  static const Color darkText = Color(0xFF18212B);
  static const Color mutedText = Color(0xFF69727D);
  @override
  void initState() {
    super.initState();
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  Future<void> _markAttendanceFromHome(
    String subjectName,
    bool isPresent, {
    int? timetableKey,
    String semester = "",
    String faculty = "",
  }) async {
    final alreadyMarked = AttendanceHistoryService.hasMarkedToday(
      subjectName,
      timetableKey: timetableKey,
    );

    if (alreadyMarked) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$subjectName attendance already marked today"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final success = await AttendanceHistoryService.markAttendance(
      subjectName: subjectName,
      isPresent: isPresent,
      timetableKey: timetableKey,
      semester: semester,
      faculty: faculty,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to mark attendance for $subjectName"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPresent
              ? "$subjectName marked Present"
              : "$subjectName marked Absent",
        ),
        backgroundColor: isPresent ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmAttendance(
    String subjectName,
    bool isPresent, {
    int? timetableKey,
    String semester = "",
    String faculty = "",
  }) async {
    final color = isPresent ? Colors.green : Colors.red;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                isPresent
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Text(isPresent ? "Mark Present" : "Mark Absent"),
            ],
          ),
          content: Text(
            "Mark $subjectName as "
            "${isPresent ? "Present" : "Absent"}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(isPresent ? "Present" : "Absent"),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _markAttendanceFromHome(
      subjectName,
      isPresent,
      timetableKey: timetableKey,
      semester: semester,
      faculty: faculty,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    final today = days[now.weekday - 1];

    final studentFuture = StudentService.getStudent();

    final double attendanceGoal = AttendanceGoalService.goal;

    final double overallAttendance = SubjectService.overallAttendance;

    final bool overallStarted = SubjectService.totalClasses > 0;

    final int totalPresent = SubjectService.totalPresent;

    final int totalAbsent = SubjectService.totalAbsent;

    final int totalClasses = totalPresent + totalAbsent;

    final startedSubjects = SubjectService.subjects
        .where((subject) => subject.total > 0)
        .toList();

    final lowAttendanceSubjects = startedSubjects
        .where((subject) => subject.percentage < attendanceGoal)
        .toList();

    final int totalSafeBunks = startedSubjects.fold<int>(
      0,
      (sum, subject) => sum + subject.safeBunksFor(attendanceGoal),
    );

    final int totalClassesNeeded = startedSubjects.fold<int>(
      0,
      (sum, subject) => sum + subject.classesNeededFor(attendanceGoal),
    );

    String overallMessage;

    if (!overallStarted) {
      overallMessage = "Start recording attendance";
    } else if (overallAttendance >= 85) {
      overallMessage = "Excellent! Keep it up ðŸ”¥";
    } else if (overallAttendance >= attendanceGoal) {
      overallMessage =
          "You're above your ${attendanceGoal.toStringAsFixed(0)}% goal";
    } else {
      overallMessage =
          "Attendance is below ${attendanceGoal.toStringAsFixed(0)}%";
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,

        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 13, bottom: 13),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF386A92), Color(0xFF294F70)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        titleSpacing: 14,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Attendly",
              style: TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 1),
            Text(
              "Student Dashboard",
              style: TextStyle(
                color: mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: "Timetable",
            icon: const Icon(
              Icons.calendar_month_rounded,
              size: 23,
              color: primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimetableScreen()),
              );
            },
          ),

          IconButton(
            tooltip: "Profile",
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 26,
              color: primary,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );

              if (!mounted) return;

              setState(() {});
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: FutureBuilder(
        future: studentFuture,

        builder: (context, snapshot) {
          final student = snapshot.data;

          final String department = student?.department ?? "CSIT";

          final String semester = student?.semester ?? "3-1";

          final String section = student?.section ?? "A";

          final todayClasses = TimetableService.getDayClasses(
            today,
            department: department,
            semester: semester,
            section: section,
          );

          final currentClass = TimetableService.getCurrentClass(
            department: department,
            semester: semester,
            section: section,
          );

          final nextClass = TimetableService.getNextClass(
            department: department,
            semester: semester,
            section: section,
          );

          return RefreshIndicator(
            color: primary,

            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));

              if (!mounted) return;

              setState(() {});
            },

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(18, 14, 18, 38),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // WELCOME
                  // ==================================================

                  Text(
                    student == null
                        ? "Welcome back ðŸ‘‹"
                        : "Welcome, ${student.name} ðŸ‘‹",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    student == null
                        ? "Stay on top of your attendance and classes."
                        : "${student.department}  â€¢  "
                              "Semester ${student.semester}  â€¢  "
                              "Section ${student.section}",
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: mutedText,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        "${now.day.toString().padLeft(2, '0')}/"
                        "${now.month.toString().padLeft(2, '0')}/"
                        "${now.year}  â€¢  $today",
                        style: const TextStyle(color: mutedText, fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ATTENDANCE HERO
                  // ==================================================
                  _attendanceHero(
                    attendance: overallAttendance,
                    goal: attendanceGoal,
                    message: overallMessage,
                    present: totalPresent,
                    absent: totalAbsent,
                    classes: totalClasses,
                  ),

                  const SizedBox(height: 27),

                  // ==================================================
                  // CURRENT CLASS
                  // ==================================================
                  _sectionHeader(
                    icon: Icons.play_circle_outline_rounded,
                    title: "Current Class",
                  ),

                  const SizedBox(height: 12),

                  if (currentClass == null)
                    _emptyClassCard(
                      icon: Icons.free_breakfast_rounded,
                      title: "No class right now",
                      message: "You're free at the moment.",
                    )
                  else
                    _currentClassCard(
                      subject: currentClass.subject,
                      time:
                          "${currentClass.startTime} - "
                          "${currentClass.endTime}",
                      faculty: currentClass.faculty,
                      room: currentClass.room,
                      timetableKey: currentClass.key,
                      semester: semester,
                    ),

                  const SizedBox(height: 27),

                  // ==================================================
                  // NEXT CLASS
                  // ==================================================
                  _sectionHeader(
                    icon: Icons.arrow_forward_rounded,
                    title: "Up Next",
                  ),

                  const SizedBox(height: 12),

                  if (nextClass == null)
                    _emptyClassCard(
                      icon: Icons.event_available_rounded,
                      title: "No more classes today",
                      message: "You're done for today ðŸŽ‰",
                    )
                  else
                    _nextClassCard(
                      subject: nextClass.subject,
                      time:
                          "${nextClass.startTime} - "
                          "${nextClass.endTime}",
                      faculty: nextClass.faculty,
                      room: nextClass.room,
                    ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // QUICK STATS
                  // ==================================================
                  _sectionHeader(
                    icon: Icons.insights_rounded,
                    title: "Attendance Overview",
                  ),

                  const SizedBox(height: 13),

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: "Present",
                          value: "$totalPresent",
                          icon: Icons.check_circle_rounded,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _statCard(
                          title: "Absent",
                          value: "$totalAbsent",
                          icon: Icons.cancel_rounded,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _statCard(
                          title: "Classes",
                          value: "$totalClasses",
                          icon: Icons.menu_book_rounded,
                          color: primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _miniInfoCard(
                          icon: Icons.free_breakfast_rounded,
                          title: "Safe Bunks",
                          value: "$totalSafeBunks",
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _miniInfoCard(
                          icon: Icons.school_rounded,
                          title: "Need To Attend",
                          value: "$totalClassesNeeded",
                          color: primary,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // LOW ATTENDANCE
                  // ==================================================
                  if (lowAttendanceSubjects.isNotEmpty) ...[
                    const SizedBox(height: 22),

                    _lowAttendanceCard(
                      subjects: lowAttendanceSubjects,
                      goal: attendanceGoal,
                    ),
                  ],

                  const SizedBox(height: 29),

                  // ==================================================
                  // QUICK ACTIONS
                  // ==================================================
                  _sectionHeader(
                    icon: Icons.bolt_rounded,
                    title: "Quick Actions",
                  ),

                  const SizedBox(height: 13),

                  Row(
                    children: [
                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.assignment_outlined,
                          title: "Assignments",
                          color: const Color(0xFF6A42A8),
                          background: const Color(0xFFF3EEFA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssignmentScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _quickActionCard(
                          icon: Icons.picture_as_pdf_rounded,
                          title: "PDF Report",
                          color: const Color(0xFFE44343),
                          background: const Color(0xFFFFF0F0),
                          onTap: () async {
                            await PdfService.generateAttendanceReport();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _wideActionCard(
                    icon: Icons.notifications_active_outlined,
                    title: "Attendance Reminder",
                    subtitle: "Test today's attendance notification",
                    color: primary,
                    onTap: () async {
                      await AttendanceNotificationService.showNotification(
                        title: "Attendance Reminder",
                        body: "Don't forget to mark today's attendance!",
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // TODAY'S CLASSES
                  // ==================================================
                  Row(
                    children: [
                      Expanded(
                        child: _sectionHeader(
                          icon: Icons.schedule_rounded,
                          title: "Today's Classes",
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F0F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${todayClasses.length}",
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  if (todayClasses.isEmpty)
                    _emptyTodayCard()
                  else
                    ...todayClasses.map((item) {
                      final marked = AttendanceHistoryService.hasMarkedToday(
                        item.subject,
                        timetableKey: item.key,
                      );

                      return _todayClassCard(
                        subject: item.subject,
                        time:
                            "${item.startTime} - "
                            "${item.endTime}",
                        faculty: item.faculty,
                        room: item.room,
                        marked: marked,
                      );
                    }),

                  const SizedBox(height: 30),

                  // ==================================================
                  // INSIGHTS
                  // ==================================================
                  _sectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: "Smart Insights",
                  ),

                  const SizedBox(height: 13),

                  const DashboardInsights(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: primary),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: darkText,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE HERO
  // ============================================================

  Widget _attendanceHero({
    required double attendance,
    required double goal,
    required String message,
    required int present,
    required int absent,
    required int classes,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(21),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF315F84), Color(0xFF4B6FA1), Color(0xFF6259B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF386A92).withValues(alpha: 0.22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Attendance",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "${attendance.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 39,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        "Goal ${goal.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (attendance / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Text(
                      "${attendance.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _heroStat(
                    icon: Icons.check_rounded,
                    value: "$present",
                    label: "Present",
                  ),
                ),

                _heroDivider(),

                Expanded(
                  child: _heroStat(
                    icon: Icons.close_rounded,
                    value: "$absent",
                    label: "Absent",
                  ),
                ),

                _heroDivider(),

                Expanded(
                  child: _heroStat(
                    icon: Icons.menu_book_rounded,
                    value: "$classes",
                    label: "Classes",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 19),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _heroDivider() {
    return Container(width: 1, height: 38, color: Colors.white24);
  }

  // ============================================================
  // CURRENT CLASS
  // ============================================================

  Widget _currentClassCard({
    required String subject,
    required String time,
    required String faculty,
    required String room,
    int? timetableKey,
    String semester = "",
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      "LIVE NOW",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            subject,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: darkText,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          _detailRow(Icons.schedule_rounded, time, Colors.green),

          const SizedBox(height: 8),

          _detailRow(Icons.person_outline_rounded, faculty, mutedText),

          const SizedBox(height: 8),

          _detailRow(Icons.location_on_outlined, room, mutedText),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _confirmAttendance(
                      subject,
                      false,
                      timetableKey: timetableKey,
                      semester: semester,
                      faculty: faculty,
                    );
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text("Absent"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _confirmAttendance(
                      subject,
                      true,
                      timetableKey: timetableKey,
                      semester: semester,
                      faculty: faculty,
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text("Present"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: color == Colors.green
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEXT CLASS
  // ============================================================

  Widget _nextClassCard({
    required String subject,
    required String time,
    required String faculty,
    required String room,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE1E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: Colors.orange,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "$faculty â€¢ $room",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 13),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFA1A7AE),
            size: 27,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E6EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),

          const SizedBox(height: 9),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              color: mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MINI INFO CARD
  // ============================================================

  Widget _miniInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E6EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          height: 105,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 31),

              const SizedBox(height: 10),

              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDE ACTION
  // ============================================================

  Widget _wideActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1E5EA)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedText, fontSize: 12.5),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOW ATTENDANCE
  // ============================================================

  Widget _lowAttendanceCard({required List subjects, required double goal}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  "Needs Attention",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),

              Text(
                "${subjects.length}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            "${subjects.length} subject(s) are below your "
            "${goal.toStringAsFixed(0)}% attendance goal.",
            style: const TextStyle(
              color: Color(0xFF5D5D5D),
              height: 1.4,
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 8),

          ...subjects.take(3).map((subject) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 7, color: Colors.orange),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  Text(
                    "${subject.percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY CLASS
  // ============================================================

  Widget _todayClassCard({
    required String subject,
    required String time,
    required String faculty,
    required String room,
    required bool marked,
  }) {
    final color = marked ? Colors.green : primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: marked
              ? Colors.green.withValues(alpha: 0.20)
              : const Color(0xFFE2E6EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              marked ? Icons.check_rounded : Icons.schedule_rounded,
              color: color,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "$faculty â€¢ $room",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 12.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: marked
                  ? Colors.green.withValues(alpha: 0.10)
                  : const Color(0xFFECEEF1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              marked ? "Marked" : "Pending",
              style: TextStyle(
                color: marked ? Colors.green : const Color(0xFF5A5E65),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CLASS
  // ============================================================

  Widget _emptyClassCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE2E6EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF73777F)),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(color: mutedText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY TODAY
  // ============================================================

  Widget _emptyTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E6EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 43,
            color: Color(0xFF7B8088),
          ),

          SizedBox(height: 10),

          Text(
            "No classes scheduled today",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Enjoy your free time ðŸŽ‰",
            style: TextStyle(color: mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
