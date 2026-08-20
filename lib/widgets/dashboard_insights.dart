import 'package:flutter/material.dart';
import '../services/subject_service.dart';
import '../services/attendance_goal_service.dart';
import '../utils/attendance_calculator.dart';

class DashboardInsights extends StatelessWidget {
  const DashboardInsights({super.key});

  int _safeBunks(int present, int total, double goal) {
    return AttendanceCalculator.safeBunks(present, total - present, goal);
  }

  int _classesNeeded(int present, int total, double goal) {
    return AttendanceCalculator.classesNeeded(present, total - present, goal);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = [
      ...SubjectService.subjects,
    ].where((subject) => subject.total > 0).toList();

    if (subjects.isEmpty) return const SizedBox.shrink();

    final goal = AttendanceGoalService.goal;
    subjects.sort((a, b) => b.percentage.compareTo(a.percentage));

    final best = subjects.first;
    final attention = subjects.where((s) => s.percentage < goal).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));

    final safeBunks = subjects.fold<int>(
      0,
      (sum, s) => sum + _safeBunks(s.present, s.total, goal),
    );
    final goalImpossible = subjects.any(
      (s) => !AttendanceCalculator.canReachTarget(s.present, s.absent, goal),
    );
    final needClasses = subjects.fold<int>(
      0,
      (sum, s) => sum + _classesNeeded(s.present, s.total, goal),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF4F6FF), Color(0xFFF9FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E6F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF5661B3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Insights",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18212B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'A quick view of your attendance health',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF78818D),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Goal ${goal.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5661B3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _insightRow(
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFF43A047),
            title: 'Best Subject',
            subtitle: best.name,
            value: '${best.percentage.toStringAsFixed(1)}%',
          ),
          _insightRow(
            icon: attention.isEmpty
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: attention.isEmpty
                ? const Color(0xFF43A047)
                : const Color(0xFFE53935),
            title: 'Needs Attention',
            subtitle: attention.isEmpty
                ? 'No issues yet'
                : attention.first.name,
            value: attention.isEmpty
                ? 'Good'
                : '${attention.first.percentage.toStringAsFixed(1)}%',
          ),
          _insightRow(
            icon: Icons.coffee_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Safe Bunks',
            subtitle: 'Classes you can skip safely',
            value: '$safeBunks',
          ),
          _insightRow(
            icon: Icons.school_rounded,
            color: const Color(0xFF386A92),
            title: 'Classes To Attend',
            subtitle: 'Needed to reach your goal',
            value: goalImpossible ? 'Impossible' : '$needClasses',
          ),
        ],
      ),
    );
  }

  Widget _insightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF252C35),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.2,
                    color: Color(0xFF7A838E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
