import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import '../services/attendance_goal_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double attendanceGoal = 75;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  // ============================================================
  // LOAD ATTENDANCE GOAL
  // ============================================================

  Future<void> _loadGoal() async {
    final goal = AttendanceGoalService.getGoal();

    if (!mounted) return;

    setState(() {
      attendanceGoal = goal;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subjects = [...SubjectService.subjects];

    final startedSubjects = subjects
        .where((subject) => subject.total > 0)
        .toList();

    final overallAttendance = SubjectService.overallAttendance;

    final totalPresent = SubjectService.totalPresent;
    final totalAbsent = SubjectService.totalAbsent;
    final totalClasses = totalPresent + totalAbsent;

    Subject? bestSubject;
    Subject? lowestSubject;

    if (startedSubjects.isNotEmpty) {
      startedSubjects.sort((a, b) => b.percentage.compareTo(a.percentage));

      bestSubject = startedSubjects.first;
      lowestSubject = startedSubjects.last;
    }

    final classesNeeded = startedSubjects.fold<int>(
      0,
      (sum, subject) => sum + subject.classesNeededFor(attendanceGoal),
    );

    final safeBunks = startedSubjects.fold<int>(
      0,
      (sum, subject) => sum + subject.safeBunksFor(attendanceGoal),
    );

    final bool hasAttendance = totalClasses > 0;

    final bool isSafe = hasAttendance && overallAttendance >= attendanceGoal;

    final bool lowestNeedsAttention =
        lowestSubject != null && lowestSubject.percentage < attendanceGoal;

    final bool goalImpossible = startedSubjects.any(
      (subject) => !subject.canReachTarget(attendanceGoal),
    );

    final Color cardColor = theme.cardColor;

    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: RefreshIndicator(
        onRefresh: _loadGoal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                "Attendance Overview",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                "Track your attendance performance and stay on target.",
                style: TextStyle(fontSize: 15, color: secondaryText),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // OVERALL ATTENDANCE
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF6A5AE0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Overall Attendance",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "${overallAttendance.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                !hasAttendance
                                    ? Icons.menu_book
                                    : isSafe
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 20,
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: Text(
                                  !hasAttendance
                                      ? "Start recording attendance"
                                      : isSafe
                                      ? (overallAttendance > attendanceGoal
                                            ? "You are above your goal"
                                            : "You are exactly at your goal")
                                      : "You are below your goal",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Text(
                            "Goal: ${attendanceGoal.toStringAsFixed(0)}%",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: hasAttendance
                                  ? (overallAttendance / 100).clamp(0.0, 1.0)
                                  : 0.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),

                          Text(
                            hasAttendance
                                ? "${overallAttendance.toStringAsFixed(0)}%"
                                : "--",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // PERFORMANCE
              // ==================================================
              const Text(
                "Performance",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: "Present",
                      value: "$totalPresent",
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      cardColor: cardColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _statCard(
                      title: "Absent",
                      value: "$totalAbsent",
                      icon: Icons.cancel,
                      iconColor: Colors.red,
                      cardColor: cardColor,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _statCard(
                      title: "Classes",
                      value: "$totalClasses",
                      icon: Icons.menu_book,
                      iconColor: Colors.blue,
                      cardColor: cardColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // BEST SUBJECT
              // ==================================================
              if (bestSubject != null) ...[
                const Text(
                  "Top Performance",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                _highlightCard(
                  icon: Icons.emoji_events,
                  iconColor: Colors.green,
                  title: "Best Subject",
                  subjectName: bestSubject.name,
                  percentage: bestSubject.percentage,
                  message: "Keep maintaining this attendance.",
                  cardColor: cardColor,
                ),

                const SizedBox(height: 15),
              ],

              // ==================================================
              // LOWEST SUBJECT / NEEDS ATTENTION
              // ==================================================
              if (lowestSubject != null) ...[
                _highlightCard(
                  icon: lowestNeedsAttention
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,

                  iconColor: lowestNeedsAttention
                      ? Colors.orange
                      : Colors.green,

                  title: lowestNeedsAttention
                      ? "Needs Attention"
                      : "Lowest Attendance",

                  subjectName: lowestSubject.name,

                  percentage: lowestSubject.percentage,

                  message: lowestNeedsAttention
                      ? "Attend upcoming classes consistently."
                      : "Attendance is currently safe.",

                  cardColor: cardColor,
                ),

                const SizedBox(height: 25),
              ],

              // ==================================================
              // SUBJECT-WISE ATTENDANCE
              // ==================================================
              const Text(
                "Subject-wise Attendance",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              if (subjects.isEmpty)
                _emptyCard(cardColor)
              else
                ...subjects.map(
                  (subject) => _subjectAnalyticsCard(subject, cardColor),
                ),

              const SizedBox(height: 25),

              // ==================================================
              // ATTENDANCE ACTION PLAN
              // ==================================================
              const Text(
                "Attendance Action Plan",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              _actionPlanCard(
                icon: goalImpossible
                    ? Icons.block_rounded
                    : safeBunks > 0
                    ? Icons.free_breakfast
                    : Icons.event_available,
                color: goalImpossible
                    ? Colors.red
                    : safeBunks > 0
                    ? Colors.orange
                    : Colors.blue,
                title: goalImpossible
                    ? "Goal Cannot Be Reached"
                    : safeBunks > 0
                    ? "Safe Bunks Available"
                    : "Avoid Missing Classes",
                description: goalImpossible
                    ? "A 100% target cannot be recovered after an absence."
                    : safeBunks > 0
                    ? "You can skip approximately "
                          "$safeBunks class(es) while maintaining "
                          "the required attendance."
                    : "Your current attendance does not provide "
                          "a safe margin for skipping classes.",
                value: goalImpossible ? "—" : "$safeBunks",
                valueLabel: goalImpossible ? "Impossible" : "Safe Bunks",
                cardColor: cardColor,
              ),

              const SizedBox(height: 12),

              _actionPlanCard(
                icon: goalImpossible
                    ? Icons.block_rounded
                    : classesNeeded > 0
                    ? Icons.school
                    : Icons.verified,
                color: goalImpossible
                    ? Colors.red
                    : classesNeeded > 0
                    ? Colors.blue
                    : Colors.green,
                title: goalImpossible
                    ? "Goal Cannot Be Reached"
                    : classesNeeded > 0
                    ? "Classes To Attend"
                    : "Attendance Goal Achieved",
                description: goalImpossible
                    ? "A 100% target cannot be recovered after an absence."
                    : classesNeeded > 0
                    ? "Attend upcoming classes continuously "
                          "to improve your attendance."
                    : "Your current attendance is already at "
                          "or above the required level.",
                value: goalImpossible ? "—" : "$classesNeeded",
                valueLabel: goalImpossible ? "Impossible" : "Classes",
                cardColor: cardColor,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
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
    required Color iconColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  // ============================================================
  // HIGHLIGHT CARD
  // ============================================================

  Widget _highlightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subjectName,
    required double percentage,
    required String message,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT ANALYTICS CARD
  // ============================================================

  Widget _subjectAnalyticsCard(Subject subject, Color cardColor) {
    final started = subject.total > 0;
    final percentage = subject.percentage;

    final Color statusColor;

    if (!started) {
      statusColor = Colors.grey;
    } else if (percentage >= attendanceGoal) {
      statusColor = Colors.green;
    } else if (percentage >= attendanceGoal - 10) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              Text(
                started ? "${percentage.toStringAsFixed(1)}%" : "Not Started",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: started ? (percentage / 100).clamp(0.0, 1.0) : 0,
              minHeight: 9,
              backgroundColor: Colors.grey.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  "Present: ${subject.present}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  "Absent: ${subject.absent}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  "Total: ${subject.total}",
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION PLAN CARD
  // ============================================================

  Widget _actionPlanCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String value,
    required String valueLabel,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 27),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              Text(
                valueLabel,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CARD
  // ============================================================

  Widget _emptyCard(Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 50, color: Colors.grey),

          SizedBox(height: 12),

          Text(
            "No attendance data yet",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 5),

          Text(
            "Start marking attendance to see analytics.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
