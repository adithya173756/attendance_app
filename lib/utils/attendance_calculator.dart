class AttendanceCalculator {
  const AttendanceCalculator._();

  /// Returns attendance percentage from present and absent counts.
  /// A subject with no recorded classes has no measurable attendance,
  /// so callers should use [hasAttendance] when displaying it.
  static double percentage(int present, int absent) {
    final total = present + absent;
    if (total <= 0) return 0.0;
    return (present / total) * 100.0;
  }

  static bool hasAttendance(int present, int absent) => present + absent > 0;

  /// Number of future classes that must be attended to reach [target].
  /// Returns 0 when the target is already met or there are no recorded
  /// classes yet. This avoids the old iterative calculation and handles
  /// 100% targets correctly.
  static int classesNeeded(int present, int absent, double target) {
    if (target <= 0) return 0;
    if (target > 100) return 0;

    final total = present + absent;
    if (total <= 0) return 0;
    if (percentage(present, absent) >= target) return 0;

    if (target == 100) {
      // A single recorded absence makes a perfect 100% target impossible.
      // Keep the integer API bounded; the UI can surface the impossible
      // state separately through [canReachTarget].
      return absent == 0 ? 0 : 10000;
    }

    final numerator = (target * total) - (100.0 * present);
    final denominator = 100.0 - target;
    if (numerator <= 0) return 0;

    return (numerator / denominator).ceil();
  }

  /// Maximum number of future classes that can be missed while keeping
  /// attendance at or above [target].
  static int safeBunks(int present, int absent, double target) {
    if (target <= 0) return 999999;
    if (target > 100) return 0;

    final total = present + absent;
    if (total <= 0) return 0;
    if (percentage(present, absent) < target) return 0;

    if (target == 100) return 0;

    final maxTotal = (present * 100.0 / target).floor();
    final bunks = maxTotal - total;
    return bunks < 0 ? 0 : bunks;
  }

  static bool canReachTarget(int present, int absent, double target) {
    if (target <= 100) {
      if (target == 100) return absent == 0;
      return true;
    }
    return false;
  }

  static String status(double attendance, {double target = 75}) {
    if (attendance >= 85) return 'Excellent';
    if (attendance >= target) return 'Safe';
    return 'Warning';
  }
}
