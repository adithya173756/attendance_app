import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/attendance_history_service.dart';
import 'services/subject_service.dart';
import 'services/attendance_notification_service.dart';
import 'services/attendance_goal_service.dart';
import 'services/timetable_service.dart';
import 'services/assignment_service.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';

import 'screens/startup_screen.dart';

import 'models/student.dart';
import 'models/attendance_history.dart';
import 'models/assignment.dart';
import 'models/timetable.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // HIVE INITIALIZATION
  // ============================================================

  await Hive.initFlutter();

  // ============================================================
  // HIVE ADAPTERS
  // ============================================================

  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(AttendanceHistoryAdapter());
  Hive.registerAdapter(AssignmentAdapter());
  Hive.registerAdapter(TimetableAdapter());

  // ============================================================
  // SERVICES INITIALIZATION
  // ============================================================

  await AttendanceGoalService.init();

  await AttendanceHistoryService.init();

  await AssignmentService.init();

  await TimetableService.init();

  await AttendanceNotificationService.init();
  await AttendanceNotificationService.restoreSavedSchedule();

  await SubjectService.init();
  await AttendanceHistoryService.rebuildAllSubjectCounts();

  await AuthService.init();

  // ============================================================
  // THEME INITIALIZATION
  // ============================================================

  await ThemeService.init();

  // ============================================================
  // START APPLICATION
  // ============================================================

  runApp(const AttendanceTrackerApp());
}

class AttendanceTrackerApp extends StatelessWidget {
  const AttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.modeNotifier,

      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'Attendance Tracker',

          // ======================================================
          // LIGHT THEME
          // ======================================================
          theme: ThemeData(
            useMaterial3: true,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF386A92),
              brightness: Brightness.light,
              surface: Colors.white,
            ),

            scaffoldBackgroundColor: const Color(0xFFF7F9FC),

            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),

            dividerTheme: const DividerThemeData(
              color: Color(0xFFE4E8ED),
              thickness: 1,
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(17)),
                borderSide: BorderSide(color: Color(0xFFE1E5EA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(17)),
                borderSide: BorderSide(color: Color(0xFFE1E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(17)),
                borderSide: BorderSide(color: Color(0xFF386A92), width: 1.4),
              ),
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF18212B),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
          ),

          // ======================================================
          // DARK THEME
          // ======================================================
          darkTheme: ThemeData(
            useMaterial3: true,

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF386A92),
              brightness: Brightness.dark,
            ),

            scaffoldBackgroundColor: const Color(0xFF121212),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // ======================================================
          // CURRENT MODE
          // ======================================================
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          home: const StartupScreen(),
        );
      },
    );
  }
}
