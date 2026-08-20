import 'package:flutter/material.dart';
import '../services/attendance_history_service.dart';
import '../models/attendance_history.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  Future<void> _clearHistory() async {
    final history = AttendanceHistoryService.history;

    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance history is already empty")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Clear Attendance History"),
          content: const Text(
            "Are you sure you want to delete all attendance history?\n\n"
            "This action cannot be undone.",
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Clear All"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AttendanceHistoryService.clearHistory();

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Attendance history cleared")));
  }

  Future<void> _deleteHistory(AttendanceHistory item) async {
    await AttendanceHistoryService.deleteHistory(item);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("History record deleted")));
  }

  @override
  Widget build(BuildContext context) {
    // Already sorted newest first by AttendanceHistoryService.
    final history = AttendanceHistoryService.history;

    final presentCount = history.where((item) => item.isPresent).length;

    final absentCount = history.where((item) => !item.isPresent).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Clear History",
            onPressed: _clearHistory,
          ),
        ],
      ),

      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 70, color: Colors.grey),
                  SizedBox(height: 15),
                  Text(
                    "No Attendance History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your attendance records will appear here.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // --------------------------------------------------
                // SUMMARY
                // --------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          "Present",
                          presentCount,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _summaryCard(
                          "Absent",
                          absentCount,
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _summaryCard(
                          "Total",
                          history.length,
                          Colors.blue,
                          Icons.history,
                        ),
                      ),
                    ],
                  ),
                ),

                // --------------------------------------------------
                // HISTORY LIST
                // --------------------------------------------------
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      bottom: 20,
                    ),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),

                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: item.isPresent
                                ? Colors.green
                                : Colors.red,
                            child: Icon(
                              item.isPresent ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),

                          title: Text(
                            item.subjectName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            "${item.formattedDate} • "
                            "${item.formattedTime}",
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.isPresent ? "Present" : "Absent",
                                style: TextStyle(
                                  color: item.isPresent
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(width: 8),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                tooltip: "Delete",
                                onPressed: () {
                                  _deleteHistory(item);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 6),

          Text(
            "$value",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 3),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
