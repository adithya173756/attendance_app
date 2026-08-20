import 'package:attendance_app/screens/import_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'student_profile_screen.dart';

import '../services/pdf_import_service.dart';
import '../services/pdf_text_service.dart';
import '../services/pdf_service.dart';
import '../services/attendance_notification_service.dart';
import '../services/attendance_goal_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;

  double attendanceGoal = 75;

  int notificationHour = 8;
  int notificationMinute = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadAttendanceGoal();
    _loadNotificationTime();
    _loadNotificationSetting();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();

    final savedNotifications = prefs.getBool('notifications_enabled') ?? true;

    if (!mounted) return;

    setState(() {
      notifications = savedNotifications;
    });
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();

    final hour = prefs.getInt('notification_hour') ?? 8;
    final minute = prefs.getInt('notification_minute') ?? 0;

    if (!mounted) return;

    setState(() {
      notificationHour = hour;
      notificationMinute = minute;
    });
  }

  Future<void> _loadAttendanceGoal() async {
    final goal = AttendanceGoalService.getGoal();

    if (!mounted) return;

    setState(() {
      attendanceGoal = goal;
    });
  }

  // ============================================================
  // SAVE ATTENDANCE GOAL
  // ============================================================

  Future<void> _saveAttendanceGoal(String value) async {
    final goal = double.tryParse(value.replaceAll('%', ''));
    if (goal == null) return;

    await AttendanceGoalService.setGoal(goal);

    if (!mounted) return;

    setState(() {
      attendanceGoal = goal;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Attendance goal set to ${goal.toStringAsFixed(0)}%"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DARK MODE
  // ============================================================

  Future<void> _toggleDarkMode(bool value) async {
    await ThemeService.setDarkMode(value);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "Dark Mode enabled" : "Dark Mode disabled"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications_enabled', value);

    if (value) {
      await AttendanceNotificationService.scheduleDailyReminder(
        hour: notificationHour,
        minute: notificationMinute,
      );
    } else {
      await AttendanceNotificationService.cancelReminder();
    }

    if (!mounted) return;

    setState(() {
      notifications = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? "Attendance reminders enabled"
              : "Attendance reminders disabled",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // NOTIFICATION TIME
  // ============================================================

  Future<void> _selectNotificationTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: notificationHour,
        minute: notificationMinute,
      ),
    );

    if (selectedTime == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('notification_hour', selectedTime.hour);

    await prefs.setInt('notification_minute', selectedTime.minute);

    if (notifications) {
      await AttendanceNotificationService.scheduleDailyReminder(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );
    }

    if (!mounted) return;

    setState(() {
      notificationHour = selectedTime.hour;
      notificationMinute = selectedTime.minute;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder time set to ${selectedTime.format(context)}"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: "Attendance Tracker",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.school, size: 42, color: Colors.blue),
      children: const [
        SizedBox(height: 10),
        Text(
          "Attendance Tracker helps students manage "
          "attendance, subjects, timetable, assignments "
          "and academic progress in one place.",
        ),
      ],
    );
  }

  // ============================================================
  // RATE APP
  // ============================================================

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("App rating will be available soon."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // IMPORT TIMETABLE
  // ============================================================

  Future<void> _importTimetable() async {
    final pdfPath = await PdfImportService.pickPdf();

    if (!mounted) return;

    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No PDF selected"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final ocrResult = await PdfTextService.extractOcr(pdfPath);

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportPreviewScreen(
          extractedText: ocrResult.text,
          ocrLines: ocrResult.lines,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Timetable imported successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue, size: 21),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
        children: [
          // ======================================================
          // PROFILE
          // ======================================================

          _settingsCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),

              leading: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF6A5AE0)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),

              title: const Text(
                "Student Profile",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text("View and update your student details"),
              ),

              trailing: const Icon(Icons.arrow_forward_ios, size: 17),

              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentProfileScreen(),
                  ),
                );

                if (!mounted) return;

                if (result == true) {
                  setState(() {});
                }
              },
            ),
          ),

          const SizedBox(height: 30),

          // ======================================================
          // PREFERENCES
          // ======================================================
          _sectionTitle("Preferences", Icons.tune),

          const SizedBox(height: 15),

          _settingsCard(
            child: Column(
              children: [
                // DARK MODE
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),

                  secondary: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.deepPurple.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: isDarkMode ? Colors.deepPurple : Colors.orange,
                    ),
                  ),

                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: Text(
                    isDarkMode
                        ? "Dark theme is enabled"
                        : "Light theme is enabled",
                  ),

                  value: isDarkMode,

                  onChanged: _toggleDarkMode,
                ),

                const Divider(height: 1),

                // NOTIFICATIONS
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),

                  secondary: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: notifications
                          ? Colors.blue.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notifications
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: notifications ? Colors.blue : Colors.grey,
                    ),
                  ),

                  title: const Text(
                    "Attendance Notifications",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: Text(
                    notifications
                        ? "Daily attendance reminder is enabled"
                        : "Daily attendance reminder is disabled",
                  ),

                  value: notifications,

                  onChanged: _toggleNotifications,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ======================================================
          // ATTENDANCE GOAL
          // ======================================================
          _sectionTitle("Attendance Goal", Icons.flag_outlined),

          const SizedBox(height: 15),

          _settingsCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),

              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag, color: Colors.orange),
              ),

              title: const Text(
                "Minimum Attendance",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text("Used for attendance calculations"),
              ),

              trailing: DropdownButton<String>(
                value: '${attendanceGoal.toStringAsFixed(0)}%',

                underline: const SizedBox(),

                borderRadius: BorderRadius.circular(14),

                items: List.generate(
                  51,
                  (index) {
                    final value = 50 + index;
                    return DropdownMenuItem<String>(
                      value: '$value%',
                      child: Text('$value%'),
                    );
                  },
                ),

                onChanged: (value) {
                  if (value != null) {
                    _saveAttendanceGoal(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ======================================================
          // MORE
          // ======================================================
          _sectionTitle("More", Icons.more_horiz),

          const SizedBox(height: 15),

          _settingsCard(
            child: Column(
              children: [
                // NOTIFICATION TIME
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: const Icon(Icons.schedule, color: Colors.blue),

                  title: const Text(
                    "Notification Time",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      TimeOfDay(
                        hour: notificationHour,
                        minute: notificationMinute,
                      ).format(context),
                    ),
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _selectNotificationTime,
                ),

                const Divider(height: 1),

                // EXPORT
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),

                  title: const Text(
                    "Export Attendance Report",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text("Generate your attendance PDF"),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () async {
                    await PdfService.generateAttendanceReport();
                  },
                ),

                const Divider(height: 1),

                // IMPORT
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload_file, color: Colors.indigo),
                  ),

                  title: const Text(
                    "Import Timetable PDF",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text("Import classes from your timetable"),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _importTimetable,
                ),

                const Divider(height: 1),

                // RATE
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.amber),
                  ),

                  title: const Text(
                    "Rate App",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text("Share your feedback"),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _rateApp,
                ),

                const Divider(height: 1),

                // ABOUT
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 5,
                  ),

                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.blueGrey,
                    ),
                  ),

                  title: const Text(
                    "About App",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text("Attendance Tracker • Version 1.0.0"),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _showAboutApp,
                ),
              ],
            ),
          ),

          const SizedBox(height: 35),

          // ======================================================
          // APP INFO
          // ======================================================
          Center(
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF6A5AE0)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Attendance Tracker",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 4),

                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Made for students 🎓",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
