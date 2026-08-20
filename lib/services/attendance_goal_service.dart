import 'package:shared_preferences/shared_preferences.dart';
import 'app_refresh_service.dart';

class AttendanceGoalService {
  static const String _key = 'attendance_goal';

  static double goal = 75;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGoal = prefs.getString(_key);

    if (savedGoal != null) {
      final parsed = double.tryParse(savedGoal.replaceAll('%', '')) ?? 75;

      goal = parsed.clamp(50, 100).toDouble();
    }
  }

  static double getGoal() {
    return goal;
  }

  static Future<void> setGoal(double value) async {
    value = value.clamp(50, 100).toDouble();

    goal = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key, '${value.toStringAsFixed(0)}%');

    AppRefreshService.refresh();
  }
}
