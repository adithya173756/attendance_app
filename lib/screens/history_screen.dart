import 'package:flutter/material.dart';

import '../models/attendance_history.dart';
import '../services/attendance_history_service.dart';
import '../services/subject_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedSubject = "All Subjects";

  DateTime? selectedDate;

  // ============================================================
  // GET HISTORY
  // ============================================================

  List<AttendanceHistory> get filteredHistory {
    List<AttendanceHistory> list = AttendanceHistoryService.history;

    // Subject filter
    if (selectedSubject != "All Subjects") {
      list = list.where((record) {
        return record.subjectName.trim().toLowerCase() ==
            selectedSubject.trim().toLowerCase();
      }).toList();
    }

    // Date filter
    if (selectedDate != null) {
      list = list.where((record) {
        return record.dateTime.year == selectedDate!.year &&
            record.dateTime.month == selectedDate!.month &&
            record.dateTime.day == selectedDate!.day;
      }).toList();
    }

    return list;
  }

  // ============================================================
  // SUBJECT LIST
  // ============================================================

  List<String> get subjectNames {
    return [
      "All Subjects",
      ...SubjectService.subjects.map((subject) => subject.name),
    ];
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2026, 6, 15),
      lastDate: DateTime(2030),
      helpText: "Filter Attendance Date",
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
    });
  }

  // ============================================================
  // CLEAR DATE
  // ============================================================

  void clearDateFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  // ============================================================
  // DELETE RECORD
  // ============================================================

  Future<void> deleteRecord(AttendanceHistory record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Attendance?"),
          content: Text(
            "Delete ${record.subjectName} attendance record?\n\n"
            "${record.formattedDate} • ${record.status}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
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

    if (confirmed != true) {
      return;
    }

    final success = await AttendanceHistoryService.deleteHistoryAndSync(record);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Attendance deleted and count updated"
              : "Unable to delete attendance",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> clearAllHistory() async {
    if (AttendanceHistoryService.totalRecords == 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Attendance History?"),
          content: const Text(
            "This will delete all attendance history "
            "and reset the corresponding subject attendance counts.\n\n"
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
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

    if (confirmed != true) {
      return;
    }

    final success = await AttendanceHistoryService.clearHistoryAndSync();

    if (!mounted) {
      return;
    }

    setState(() {
      selectedSubject = "All Subjects";
      selectedDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "History cleared and attendance counts reset"
              : "Unable to clear history",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final records = filteredHistory;

    final totalPresent = records.where((record) => record.isPresent).length;

    final totalAbsent = records.where((record) => !record.isPresent).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text(
          "Attendance History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          if (AttendanceHistoryService.totalRecords > 0)
            IconButton(
              onPressed: clearAllHistory,
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear History",
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          const SizedBox(height: 15),

          // ======================================================
          // STATISTICS
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.check_circle,
                    title: "Present",
                    value: totalPresent,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    icon: Icons.cancel,
                    title: "Absent",
                    value: totalAbsent,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    icon: Icons.history,
                    title: "Records",
                    value: records.length,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ======================================================
          // FILTERS
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,

                    initialValue: subjectNames.contains(selectedSubject)
                        ? selectedSubject
                        : "All Subjects",

                    decoration: InputDecoration(
                      labelText: "Subject",
                      prefixIcon: const Icon(Icons.menu_book),

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                    ),

                    icon: const Icon(Icons.keyboard_arrow_down),

                    items: subjectNames.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,

                        child: Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedSubject = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 58,
                  height: 58,

                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),

                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: selectDate,

                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.blue,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // DATE FILTER CHIP
          // ======================================================
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),

              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.blue,
                    ),

                    label: Text(
                      "${selectedDate!.day}/"
                      "${selectedDate!.month}/"
                      "${selectedDate!.year}",
                    ),

                    deleteIcon: const Icon(Icons.close),

                    onDeleted: clearDateFilter,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ======================================================
          // HISTORY LIST
          // ======================================================
          Expanded(
            child: records.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),

                    itemCount: records.length,

                    itemBuilder: (context, index) {
                      return _historyCard(records[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 25),

          const SizedBox(height: 6),

          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _historyCard(AttendanceHistory record) {
    final isPresent = record.isPresent;

    final statusColor = isPresent ? Colors.green : Colors.red;

    final statusBackground = isPresent
        ? Colors.green.withValues(alpha: 0.10)
        : Colors.red.withValues(alpha: 0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: statusColor.withValues(alpha: 0.25)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // ======================================================
          // STATUS ICON
          // ======================================================

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: statusBackground,
              shape: BoxShape.circle,
            ),

            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: statusColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // DETAILS
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  record.subjectName,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      record.formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      record.formattedTime,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ======================================================
          // STATUS + DELETE
          // ======================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  record.status,

                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              SizedBox(
                height: 32,

                child: IconButton(
                  padding: EdgeInsets.zero,

                  onPressed: () {
                    deleteRecord(record);
                  },

                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey.shade600,
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
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    final hasFilter = selectedSubject != "All Subjects" || selectedDate != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              hasFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.history_toggle_off,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 18),

            Text(
              hasFilter ? "No matching records" : "No attendance history",
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasFilter
                  ? "Try changing the filters."
                  : "Your attendance records will appear here.",
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),

            if (hasFilter) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedSubject = "All Subjects";
                    selectedDate = null;
                  });
                },

                icon: const Icon(Icons.clear_all),

                label: const Text("Clear Filters"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
