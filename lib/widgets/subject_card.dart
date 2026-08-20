import 'package:flutter/material.dart';

class SubjectCard extends StatelessWidget {
  final String subjectName;
  final String faculty;
  final double attendance;
  final double minimumAttendance;
  final int present;
  final int absent;
  final int classesNeeded;
  final int safeBunks;

  final VoidCallback? onTap;
  final VoidCallback? onPresent;
  final VoidCallback? onAbsent;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.subjectName,
    required this.faculty,
    required this.attendance,
    required this.minimumAttendance,
    required this.present,
    required this.absent,
    required this.classesNeeded,
    required this.safeBunks,
    this.onTap,
    this.onPresent,
    this.onAbsent,
    this.onDelete,
  });

  bool get hasAttendance => present + absent > 0;

  Color get statusColor {
    if (!hasAttendance) return const Color(0xFF607D8B);
    if (attendance >= 85) return const Color(0xFF43A047);
    if (attendance >= minimumAttendance) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  String get statusLabel {
    if (!hasAttendance) return 'Not Started';
    if (attendance >= 85) return 'Excellent';
    if (attendance >= minimumAttendance) return 'On Track';
    return 'Needs Attention';
  }

  IconData get statusIcon {
    if (!hasAttendance) return Icons.menu_book_rounded;
    if (attendance >= 85) return Icons.verified_rounded;
    if (attendance >= minimumAttendance) return Icons.trending_up_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final progress = hasAttendance ? (attendance / 100).clamp(0.0, 1.0) : 0.0;

    final colors = Theme.of(context).colorScheme;
    final cardText = colors.onSurface;
    final muted = colors.onSurfaceVariant;
    final surfaceAlt = colors.surfaceContainerHighest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 27),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: cardText,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          faculty.isEmpty ? 'Faculty not added' : faculty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Subject options',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('Delete subject'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        color: statusColor,
                        backgroundColor: const Color(0xFFE9EDF2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hasAttendance ? '${attendance.toStringAsFixed(1)}%' : '—',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(statusIcon, size: 15, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Goal ${minimumAttendance.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF7A838E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceAlt,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    _stat(
                      context,
                      Icons.check_circle_rounded,
                      '$present',
                      'Present',
                      const Color(0xFF43A047),
                    ),
                    _divider(),
                    _stat(
                      context,
                      Icons.cancel_rounded,
                      '$absent',
                      'Absent',
                      const Color(0xFFE53935),
                    ),
                    _divider(),
                    _stat(
                      context,
                      attendance >= minimumAttendance
                          ? Icons.coffee_rounded
                          : Icons.school_rounded,
                      hasAttendance
                          ? (attendance >= minimumAttendance
                                ? '$safeBunks'
                                : (classesNeeded >= 10000
                                      ? 'Impossible'
                                      : '$classesNeeded'))
                          : '—',
                      hasAttendance
                          ? (attendance >= minimumAttendance
                                ? 'Safe Bunks'
                                : (classesNeeded >= 10000 ? 'Goal' : 'Need'))
                          : 'Status',
                      attendance >= minimumAttendance
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF386A92),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAbsent,
                      icon: const Icon(Icons.close_rounded, size: 19),
                      label: const Text('Absent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.1,
                        ),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onPresent,
                      icon: const Icon(Icons.check_rounded, size: 19),
                      label: const Text('Present'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34, color: Colors.grey.shade300);
}
