import 'package:flutter/material.dart';

import '../models/ocr_line.dart';
import '../models/parsed_timetable.dart';
import '../models/subject.dart';
import '../models/timetable.dart';

import '../services/subject_service.dart';
import '../services/timetable_parser_service.dart';
import '../services/timetable_service.dart';
import '../services/student_service.dart';

class ImportPreviewScreen extends StatelessWidget {
  final String extractedText;
  final List<OcrLine> ocrLines;

  const ImportPreviewScreen({
    super.key,
    required this.extractedText,
    required this.ocrLines,
  });

  @override
  Widget build(BuildContext context) {
    final ParsedTimetable parsedTimetable =
        TimetableParserService.parseTimetable(
          extractedText,
          ocrLines: ocrLines,
        );

    final subjects = parsedTimetable.subjects;

    // Only show valid timetable classes.
    final classes = parsedTimetable.classes.where((item) {
      final subject = item.subject.trim().toLowerCase();

      if (subject.isEmpty) return false;

      const invalidSubjects = {
        "to",
        "period",
        "1st period",
        "2nd period",
        "3rd period",
        "4th period",
        "5th period",
        "6th period",
        "7th period",
        "8th period",
        "9th period",
      };

      if (invalidSubjects.contains(subject)) {
        return false;
      }

      return item.startTime.trim().isNotEmpty &&
          item.endTime.trim().isNotEmpty &&
          item.day.trim().isNotEmpty;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Import Preview"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              children: [
                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    "Detected Timetable",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    "${classes.length} classes • ${subjects.length} subjects",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // ACADEMIC INFORMATION
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Academic Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      _infoRow(
                        "Department",
                        parsedTimetable.department.isEmpty
                            ? "Not detected"
                            : parsedTimetable.department,
                      ),

                      const SizedBox(height: 7),

                      _infoRow(
                        "Semester",
                        parsedTimetable.semester.isEmpty
                            ? "Not detected"
                            : parsedTimetable.semester,
                      ),

                      const SizedBox(height: 7),

                      _infoRow(
                        "Section",
                        parsedTimetable.section.isEmpty
                            ? "Not detected"
                            : parsedTimetable.section,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SUBJECTS
                // ==================================================
                if (subjects.isNotEmpty) ...[
                  const Text(
                    "Detected Subjects",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  ...subjects.map((subject) => _subjectCard(subject)),

                  const SizedBox(height: 22),
                ],

                // ==================================================
                // CLASSES
                // ==================================================
                const Text(
                  "Detected Classes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (classes.isEmpty)
                  _emptyClassesCard()
                else
                  ...classes.map((item) => _classCard(item)),
              ],
            ),
          ),

          // ========================================================
          // IMPORT BUTTON
          // ========================================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: classes.isEmpty
                      ? null
                      : () async {
                          await _importTimetable(context, parsedTimetable);
                        },
                  icon: const Icon(Icons.download),
                  label: const Text(
                    "Import Timetable",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ================================================================
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard(ParsedSubject subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book, color: Colors.blue),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (subject.code.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subject.code,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (subject.faculty.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subject.faculty,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CLASS CARD
  // ================================================================

  Widget _classCard(ParsedClass item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule, color: Colors.blue),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    "${item.day} • "
                    "${item.startTime} - ${item.endTime}",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (item.facultyCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.facultyCode,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],

                  if (item.room.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.room,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),

            if (item.period > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  "P${item.period}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY CLASSES
  // ================================================================

  Widget _emptyClassesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            "No timetable classes detected",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 7),

          Text(
            "The timetable structure could not be read correctly.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // IMPORT
  // ================================================================

  Future<void> _importTimetable(
    BuildContext context,
    ParsedTimetable parsedTimetable,
  ) async {
    try {
      final student = await StudentService.getStudent();

      final String department = parsedTimetable.department.trim().isNotEmpty
          ? parsedTimetable.department.trim()
          : student?.department ?? "CSIT";

      final String semester = parsedTimetable.semester.trim().isNotEmpty
          ? parsedTimetable.semester.trim()
          : student?.semester ?? "3-1";

      final String section = parsedTimetable.section.trim().isNotEmpty
          ? parsedTimetable.section.trim()
          : student?.section ?? "A";

      // ==========================================================
      // SUBJECTS
      // ==========================================================

      final List<Subject> importSubjects = [];

      for (final item in parsedTimetable.subjects) {
        final name = item.name.trim();

        if (name.isEmpty) {
          continue;
        }

        importSubjects.add(
          Subject(
            name: name,
            faculty: item.faculty.trim(),
            semester: semester,
            minimumAttendance: 75,
          ),
        );
      }

      // ==========================================================
      // TIMETABLE
      // ==========================================================

      final List<Timetable> importClasses = [];

      for (final item in parsedTimetable.classes) {
        final subject = item.subject.trim();

        if (subject.isEmpty) {
          continue;
        }

        importClasses.add(
          Timetable(
            subject: subject,
            faculty: item.facultyCode.trim(),
            room: item.room.trim(),
            day: item.day.trim(),
            startTime: item.startTime.trim(),
            endTime: item.endTime.trim(),
            department: department,
            semester: semester,
            section: section,
            period: item.period,
            effectiveFrom: DateTime.now(),
          ),
        );
      }

      // ==========================================================
      // SAVE
      // ==========================================================

      if (importSubjects.isNotEmpty) {
        await SubjectService.replaceSubjects(importSubjects);
      }

      if (importClasses.isNotEmpty) {
        await TimetableService.replaceTimetable(importClasses);
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${importClasses.length} classes and "
            "${importSubjects.length} subjects imported successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Import failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
