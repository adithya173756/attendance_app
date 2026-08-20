import 'package:flutter/material.dart';

import '../models/timetable.dart';
import '../services/timetable_service.dart';

class TimetableImportPreviewScreen extends StatefulWidget {
  final List<Timetable> classes;

  const TimetableImportPreviewScreen({super.key, required this.classes});

  @override
  State<TimetableImportPreviewScreen> createState() =>
      _TimetableImportPreviewScreenState();
}

class _TimetableImportPreviewScreenState
    extends State<TimetableImportPreviewScreen> {
  bool isImporting = false;

  // ============================================================
  // IMPORT
  // ============================================================

  Future<void> importClasses() async {
    if (widget.classes.isEmpty) {
      return;
    }

    setState(() {
      isImporting = true;
    });

    try {
      await TimetableService.addClasses(widget.classes);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${widget.classes.length} classes imported successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Import failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          "Preview Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // ======================================================
          // SUMMARY
          // ======================================================

          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.upload_file, color: Colors.blue.shade700),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Timetable Ready",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "${widget.classes.length} classes detected",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // LIST
          // ======================================================
          Expanded(
            child: widget.classes.isEmpty
                ? const Center(
                    child: Text(
                      "No valid classes found",
                      style: TextStyle(fontSize: 17),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: widget.classes.length,
                    itemBuilder: (context, index) {
                      final item = widget.classes[index];

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Text(
                              item.day,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          title: Text(
                            item.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            "${item.startTime} - ${item.endTime}\n"
                            "${item.faculty.isEmpty ? "Faculty not specified" : item.faculty}"
                            "${item.room.isEmpty ? "" : " • ${item.room}"}",
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ======================================================
          // IMPORT BUTTON
          // ======================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isImporting ? null : importClasses,
                  icon: isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),

                  label: Text(
                    isImporting
                        ? "Importing..."
                        : "Import ${widget.classes.length} Classes",
                    style: const TextStyle(fontSize: 16),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}
