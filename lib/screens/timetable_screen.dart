import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import '../services/timetable_service.dart';
import '../services/timetable_import_service.dart';
import '../services/attendance_history_service.dart';
import '../services/student_service.dart';
import '../models/timetable.dart';

import 'add_class_screen.dart';

class TimetableScreen extends StatefulWidget {
  final String department;
  final String semester;
  final String section;

  const TimetableScreen({
    super.key,
    this.department = "CSIT",
    this.semester = "3-1",
    this.section = "A",
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime selectedDate;

  String selectedDepartment = "CSIT";
  String selectedSemester = "3-1";
  String selectedSection = "A";

  bool isProfileLoaded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();

    selectedDepartment = widget.department;
    selectedSemester = widget.semester;
    selectedSection = widget.section;

    loadStudentProfile();
  }

  // ============================================================
  // LOAD STUDENT PROFILE
  // ============================================================

  Future<void> loadStudentProfile() async {
    final student = await StudentService.getStudent();

    if (!mounted) return;

    if (student != null) {
      setState(() {
        selectedDepartment = student.department.trim().isNotEmpty
            ? student.department.trim()
            : widget.department;

        selectedSemester = student.semester.trim().isNotEmpty
            ? student.semester.trim()
            : widget.semester;

        selectedSection = student.section.trim().isNotEmpty
            ? student.section.trim()
            : widget.section;

        isProfileLoaded = true;
      });
    } else {
      setState(() {
        isProfileLoaded = true;
      });
    }
  }

  // ============================================================
  // REFRESH PROFILE
  // ============================================================

  Future<void> refreshProfile() async {
    await loadStudentProfile();

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2026, 6, 15),
      lastDate: DateTime(2027, 6, 30),
      helpText: "Select Class Date",
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // ============================================================
  // FORMAT DAY
  // ============================================================

  String _formatDay(DateTime date) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    return days[date.weekday - 1];
  }

  // ============================================================
  // CLASS GROUP
  // ============================================================

  String get selectedClassGroup {
    return "$selectedDepartment-$selectedSemester-$selectedSection";
  }

  // ============================================================
  // GET SELECTED DAY CLASSES
  // ============================================================

  List<Timetable> get selectedDayClasses {
    return TimetableService.getClassesForDate(
      selectedDate,
      department: selectedDepartment,
      semester: selectedSemester,
      section: selectedSection,
    );
  }

  // ============================================================
  // CHECK TODAY
  // ============================================================

  bool get isSelectedDateToday {
    final now = DateTime.now();

    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  Future<void> _markAttendance(Timetable item, bool isPresent) async {
    // Attendance can only be marked for today.
    if (!isSelectedDateToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance can only be marked for today"),
        ),
      );

      return;
    }

    // Prevent duplicate attendance for this exact timetable class.
    final alreadyMarked = AttendanceHistoryService.hasMarkedToday(
      item.subject,
      timetableKey: item.key,
    );

    if (alreadyMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance already marked for this class today"),
        ),
      );

      return;
    }

    // AttendanceHistoryService is the single source of truth.
    final success = await AttendanceHistoryService.markAttendance(
      subjectName: item.subject,
      isPresent: isPresent,
      timetableKey: item.key,
      semester: item.semester,
      faculty: item.faculty,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to mark attendance"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPresent ? "${item.subject}: Present" : "${item.subject}: Absent",
        ),
        backgroundColor: isPresent ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // IMPORT TIMETABLE PDF
  // ============================================================

  Future<void> _importTimetable() async {
    try {
      final student = await StudentService.getStudent();

      if (!mounted) {
        return;
      }

      final department = student?.department.trim().isNotEmpty == true
          ? student!.department.trim()
          : selectedDepartment;

      final semester = student?.semester.trim().isNotEmpty == true
          ? student!.semester.trim()
          : selectedSemester;

      final section = student?.section.trim().isNotEmpty == true
          ? student!.section.trim()
          : selectedSection;

      // ==========================================================
      // PICK PDF
      // ==========================================================

      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (file == null) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selected PDF is empty."),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }
      // ==========================================================
      // SHOW LOADING
      // ==========================================================

      if (!mounted) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(width: 20),
                Expanded(child: Text("Analyzing timetable PDF...")),
              ],
            ),
          );
        },
      );

      // ==========================================================
      // PARSE PDF
      // ==========================================================

      final importedClasses = await TimetableImportService.parsePdf(
        bytes,
        department: department,
        semester: semester,
        section: section,
      );

      if (!mounted) {
        return;
      }

      // Close loading dialog.
      Navigator.of(context).pop();

      // ==========================================================
      // NOTHING FOUND
      // ==========================================================

      if (importedClasses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No timetable classes could be detected from this PDF.",
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // ==========================================================
      // PREVIEW
      // ==========================================================

      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Import ${importedClasses.length} Classes?"),

            content: SizedBox(
              width: double.maxFinite,
              height: 400,

              child: ListView.builder(
                itemCount: importedClasses.length,

                itemBuilder: (context, index) {
                  final item = importedClasses[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                    ),

                    title: Text(item.subject),

                    subtitle: Text(
                      "${item.day} • "
                      "${item.startTime} - ${item.endTime}"
                      "${item.faculty.isNotEmpty ? "\n${item.faculty}" : ""}"
                      "${item.room.isNotEmpty ? " • ${item.room}" : ""}",
                    ),
                  );
                },
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },

                child: const Text("Cancel"),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },

                icon: const Icon(Icons.download),
                label: const Text("Import"),
              ),
            ],
          );
        },
      );

      // ==========================================================
      // USER CANCELLED
      // ==========================================================

      if (shouldImport != true) {
        return;
      }

      // ==========================================================
      // SAVE TO HIVE
      // ==========================================================

      await TimetableService.addClasses(importedClasses);

      if (!mounted) {
        return;
      }

      // ==========================================================
      // REFRESH UI
      // ==========================================================

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${importedClasses.length} classes imported successfully",
          ),

          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Close loading dialog if it is currently open.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to import timetable: $e"),

          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // GET TODAY'S ATTENDANCE RECORD
  // ============================================================

  AttendanceStatus _getAttendanceStatus(
    String subjectName, {
    int? timetableKey,
  }) {
    if (!isSelectedDateToday) {
      return AttendanceStatus.none;
    }

    final record = AttendanceHistoryService.getTodayRecord(
      subjectName,
      timetableKey: timetableKey,
    );

    if (record == null) {
      return AttendanceStatus.none;
    }

    if (record.isPresent) {
      return AttendanceStatus.present;
    }

    return AttendanceStatus.absent;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    TimetableService.debugPrintTimetable();

    TimetableService.debugPrintTimetable();

    final classes = selectedDayClasses;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text(
          "Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            onPressed: refreshProfile,
            icon: const Icon(Icons.refresh, size: 26),
            tooltip: "Refresh Profile",
          ),

          IconButton(
            onPressed: _importTimetable,
            icon: const Icon(Icons.upload_file, size: 27),
            tooltip: "Import Timetable",
          ),

          IconButton(
            onPressed: selectDate,
            icon: const Icon(Icons.calendar_month, size: 28),
            tooltip: "Select Date",
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: !isProfileLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 15),

                // ==================================================
                // STUDENT PROFILE INFO
                // ==================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  child: Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(18),

                      border: Border.all(color: Colors.blue.shade100),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),

                          blurRadius: 8,

                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,

                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.10),

                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: const Icon(
                            Icons.school,
                            color: Colors.blue,
                            size: 26,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                "My Timetable",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "$selectedDepartment • "
                                "$selectedSemester • "
                                "Section $selectedSection",

                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DATE INFORMATION
                // ==================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),

                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              _formatDay(selectedDate),

                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              _formatDate(selectedDate),

                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Text(
                          selectedClassGroup,

                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // CLASS COUNT
                // ==================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),

                  child: Row(
                    children: [
                      Text(
                        "${_formatDay(selectedDate)} Classes",

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        "${classes.length} classes",

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // CLASSES
                // ==================================================
                Expanded(
                  child: classes.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),

                          itemCount: classes.length,

                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),

                              child: _classCard(classes[index]),
                            );
                          },
                        ),
                ),
              ],
            ),

      // ==========================================================
      // ADD CLASS
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassScreen()),
          );

          if (result == true && mounted) {
            await refreshProfile();

            if (!mounted) return;

            setState(() {});
          }
        },

        icon: const Icon(Icons.add),

        label: const Text("Add Class"),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            Icons.event_available_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          Text(
            "No classes scheduled",

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "$selectedClassGroup • "
            "${_formatDay(selectedDate)}",

            style: TextStyle(color: Colors.grey.shade500),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: selectDate,

            icon: const Icon(Icons.calendar_month),

            label: const Text("Select Another Date"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget _classCard(Timetable item) {
    final currentClass = TimetableService.getCurrentClass(
      department: selectedDepartment,
      semester: selectedSemester,
      section: selectedSection,
    );

    final now = DateTime.now();

    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final isCurrent =
        isToday && currentClass != null && currentClass.key == item.key;

    final attendanceStatus = _getAttendanceStatus(
      item.subject,
      timetableKey: item.key,
    );

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: isCurrent ? Border.all(color: Colors.green, width: 2) : null,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),

            blurRadius: 12,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ========================================================
          // TITLE
          // ========================================================

          Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.menu_book,
                  color: Colors.blue,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  item.subject,

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "edit") {
                    _editClass(item);
                  } else if (value == "delete") {
                    _deleteClass(item);
                  }
                },

                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(value: "edit", child: Text("Edit Class")),

                    PopupMenuItem(value: "delete", child: Text("Delete Class")),
                  ];
                },
              ),
            ],
          ),

          // ========================================================
          // CURRENT CLASS
          // ========================================================
          if (isCurrent) ...[
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              decoration: BoxDecoration(
                color: Colors.green,

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Text(
                "CURRENT CLASS",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ========================================================
          // TIME
          // ========================================================
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue),

              const SizedBox(width: 10),

              Text(
                "${item.startTime} - "
                "${item.endTime}",

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ========================================================
          // FACULTY
          // ========================================================
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey),

              const SizedBox(width: 10),

              Expanded(
                child: Text(item.faculty, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ========================================================
          // ROOM
          // ========================================================
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),

              const SizedBox(width: 10),

              Text(item.room, style: const TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(height: 18),

          // ========================================================
          // ATTENDANCE
          // ========================================================
          _attendanceSection(item, attendanceStatus),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE SECTION
  // ============================================================

  Widget _attendanceSection(Timetable item, AttendanceStatus status) {
    // Already marked Present.
    if (status == AttendanceStatus.present) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),

        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.10),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: Colors.green.withValues(alpha: 0.40)),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.check_circle, color: Colors.green),

            SizedBox(width: 8),

            Text(
              "Present Today",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Already marked Absent.
    if (status == AttendanceStatus.absent) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),

        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: Colors.red.withValues(alpha: 0.40)),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.cancel, color: Colors.red),

            SizedBox(width: 8),

            Text(
              "Absent Today",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Past or future date.
    if (!isSelectedDateToday) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          color: Colors.grey.shade100,

          borderRadius: BorderRadius.circular(14),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),

            const SizedBox(width: 7),

            Text(
              "Attendance only for today",

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Today but not marked.
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _markAttendance(item, true),

            icon: const Icon(Icons.check, size: 20),

            label: const Text("Present"),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 13),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _markAttendance(item, false),

            icon: const Icon(Icons.close, size: 20),

            label: const Text("Absent"),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 13),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editClass(Timetable item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddClassScreen(editClass: item)),
    );

    if (result == true && mounted) {
      await refreshProfile();

      if (!mounted) return;

      setState(() {});
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteClass(Timetable item) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Class?"),

          content: Text('Delete "${item.subject}"?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await TimetableService.deleteClass(item);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Class deleted successfully")));
  }
}

// ================================================================
// ATTENDANCE STATUS
// ================================================================

enum AttendanceStatus { none, present, absent }
