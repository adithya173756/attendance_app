import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';

class EditSubjectScreen extends StatefulWidget {
  final Subject subject;
  final int subjectIndex;

  const EditSubjectScreen({
    super.key,
    required this.subject,
    required this.subjectIndex,
  });

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController facultyController;
  late TextEditingController minimumAttendanceController;
  late TextEditingController presentController;
  late TextEditingController absentController;

  late String selectedSemester;

  final List<String> semesters = [
    "1-1",
    "1-2",
    "2-1",
    "2-2",
    "3-1",
    "3-2",
    "4-1",
    "4-2",
  ];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.subject.name);

    facultyController = TextEditingController(text: widget.subject.faculty);

    minimumAttendanceController = TextEditingController(
      text: widget.subject.minimumAttendance.toStringAsFixed(0),
    );

    presentController = TextEditingController(
      text: widget.subject.present.toString(),
    );

    absentController = TextEditingController(
      text: widget.subject.absent.toString(),
    );

    selectedSemester = semesters.contains(widget.subject.semester)
        ? widget.subject.semester
        : "3-1";
  }

  @override
  void dispose() {
    nameController.dispose();
    facultyController.dispose();
    minimumAttendanceController.dispose();
    presentController.dispose();
    absentController.dispose();
    super.dispose();
  }

  Future<void> saveSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int present = int.tryParse(presentController.text.trim()) ?? 0;

    final int absent = int.tryParse(absentController.text.trim()) ?? 0;

    final double minimumAttendance =
        double.tryParse(minimumAttendanceController.text.trim()) ?? 75;

    final updatedSubject = Subject(
      name: nameController.text.trim(),
      semester: selectedSemester,
      faculty: facultyController.text.trim(),
      minimumAttendance: minimumAttendance,
      present: present,
      absent: absent,
    );

    await SubjectService.updateSubject(widget.subjectIndex, updatedSubject);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject updated successfully")),
    );

    Navigator.pop(context, true);
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Subject"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // --------------------------------
              // HEADER
              // --------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 25),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF5E60CE)],
                  ),

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 42,
                    ),

                    SizedBox(height: 12),

                    Text(
                      "Edit Subject",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Update subject details and attendance.",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),

              // --------------------------------
              // SUBJECT NAME
              // --------------------------------
              TextFormField(
                controller: nameController,

                decoration: inputDecoration(
                  label: "Subject Name",
                  icon: Icons.menu_book_rounded,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Subject Name";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------
              // FACULTY
              // --------------------------------
              TextFormField(
                controller: facultyController,

                decoration: inputDecoration(
                  label: "Faculty Name",
                  icon: Icons.person_rounded,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Faculty Name";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------
              // SEMESTER
              // --------------------------------
              DropdownButtonFormField<String>(
                initialValue: selectedSemester,

                decoration: inputDecoration(
                  label: "Semester",
                  icon: Icons.school_rounded,
                ),

                borderRadius: BorderRadius.circular(18),

                items: semesters.map((semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedSemester = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------
              // MINIMUM ATTENDANCE
              // --------------------------------
              TextFormField(
                controller: minimumAttendanceController,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: inputDecoration(
                  label: "Minimum Attendance %",
                  icon: Icons.flag_rounded,
                ).copyWith(suffixText: "%"),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Minimum Attendance";
                  }

                  final number = double.tryParse(value.trim());

                  if (number == null) {
                    return "Enter a valid number";
                  }

                  if (number < 0 || number > 100) {
                    return "Enter value between 0 and 100";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------
              // PRESENT
              // --------------------------------
              TextFormField(
                controller: presentController,

                keyboardType: TextInputType.number,

                decoration: inputDecoration(
                  label: "Present Classes",
                  icon: Icons.check_circle,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Present Classes";
                  }

                  final number = int.tryParse(value.trim());

                  if (number == null || number < 0) {
                    return "Enter a valid number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // --------------------------------
              // ABSENT
              // --------------------------------
              TextFormField(
                controller: absentController,

                keyboardType: TextInputType.number,

                decoration: inputDecoration(
                  label: "Absent Classes",
                  icon: Icons.cancel,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Absent Classes";
                  }

                  final number = int.tryParse(value.trim());

                  if (number == null || number < 0) {
                    return "Enter a valid number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // --------------------------------
              // SAVE BUTTON
              // --------------------------------
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(
                  onPressed: saveSubject,

                  icon: const Icon(Icons.save_rounded),

                  label: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 6,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // --------------------------------
              // CANCEL BUTTON
              // --------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
