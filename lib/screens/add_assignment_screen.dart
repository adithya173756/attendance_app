import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../services/assignment_service.dart';
import '../services/subject_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  String? _selectedSubject;

  DateTime? _dueDate;

  String _priority = "Medium";

  final List<String> _priorities = ["Low", "Medium", "High"];

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    setState(() {
      _dueDate = selectedDate;
    });
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a subject")));
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a due date")));
      return;
    }

    final assignment = Assignment(
      subject: _selectedSubject!,
      title: _titleController.text.trim(),
      dueDate: _dueDate!,
      priority: _priority,
    );

    await AssignmentService.addAssignment(assignment);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Assignment added successfully")),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = SubjectService.subjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Add Assignment"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TITLE
              // ==================================================
              TextFormField(
                controller: _titleController,

                decoration: InputDecoration(
                  labelText: "Assignment Title",
                  hintText: "e.g. CN Unit 3 Assignment",
                  prefixIcon: const Icon(Icons.assignment),

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
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter assignment title";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SUBJECT
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: _selectedSubject,

                decoration: InputDecoration(
                  labelText: "Subject",
                  prefixIcon: const Icon(Icons.menu_book),

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
                ),

                items: subjects.map((subject) {
                  return DropdownMenuItem<String>(
                    value: subject.name,
                    child: Text(subject.name),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                  });
                },

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Select a subject";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // DUE DATE
              // ==================================================
              InkWell(
                onTap: _pickDueDate,

                borderRadius: BorderRadius.circular(18),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Due Date",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              _dueDate == null
                                  ? "Select due date"
                                  : "${_dueDate!.day.toString().padLeft(2, '0')}/"
                                        "${_dueDate!.month.toString().padLeft(2, '0')}/"
                                        "${_dueDate!.year}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PRIORITY
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: _priority,

                decoration: InputDecoration(
                  labelText: "Priority",
                  prefixIcon: const Icon(Icons.flag),

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
                ),

                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _priority = value;
                  });
                },
              ),

              const SizedBox(height: 35),

              // ==================================================
              // SAVE
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton.icon(
                  onPressed: _saveAssignment,

                  icon: const Icon(Icons.save),

                  label: const Text(
                    "Save Assignment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
