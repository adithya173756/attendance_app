import 'package:flutter/material.dart';

import '../services/timetable_service.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../models/timetable.dart';

class AddClassScreen extends StatefulWidget {
  final Timetable? editClass;

  final String department;
  final String semester;
  final String section;

  const AddClassScreen({
    super.key,
    this.editClass,
    this.department = "CSIT",
    this.semester = "3-1",
    this.section = "A",
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  String selectedDay = "Mon";

  String selectedDepartment = "CSIT";
  String selectedSemester = "3-1";
  String selectedSection = "A";

  final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isLoadingProfile = true;

  bool get isEditing => widget.editClass != null;

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";

    return "$hour:$minute $period";
  }

  // ============================================================
  // AVAILABLE SUBJECTS
  // ============================================================

  List<String> get availableSubjects {
    return SubjectService.subjects
        .map((subject) => subject.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ============================================================
  // LOAD PROFILE + EDIT DATA
  // ============================================================

  Future<void> _loadData() async {
    final student = await StudentService.getStudent();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // LOAD PROFILE
    // ==========================================================

    if (student != null) {
      selectedDepartment = student.department.trim().isNotEmpty
          ? student.department.trim()
          : widget.department;

      selectedSemester = student.semester.trim().isNotEmpty
          ? student.semester.trim()
          : widget.semester;

      selectedSection = student.section.trim().isNotEmpty
          ? student.section.trim()
          : widget.section;
    } else {
      selectedDepartment = widget.department;
      selectedSemester = widget.semester;
      selectedSection = widget.section;
    }

    // ==========================================================
    // LOAD EDIT CLASS
    // ==========================================================

    final item = widget.editClass;

    if (item != null) {
      subjectController.text = item.subject;
      facultyController.text = item.faculty;
      roomController.text = item.room;

      selectedDay = days.contains(item.day) ? item.day : "Mon";

      // Keep the existing class details while editing.
      if (item.department.trim().isNotEmpty) {
        selectedDepartment = item.department.trim();
      }

      if (item.semester.trim().isNotEmpty) {
        selectedSemester = item.semester.trim();
      }

      if (item.section.trim().isNotEmpty) {
        selectedSection = item.section.trim();
      }

      startTime = _parseTime(item.startTime);
      endTime = _parseTime(item.endTime);
    }

    setState(() {
      isLoadingProfile = false;
    });
  }

  // ============================================================
  // PARSE TIME
  // ============================================================

  TimeOfDay _parseTime(String time) {
    final clean = time.trim().toUpperCase();

    final isPM = clean.contains("PM");

    final value = clean.replaceAll("AM", "").replaceAll("PM", "").trim();

    final parts = value.split(":");

    if (parts.length != 2) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    int hour = int.tryParse(parts[0]) ?? 9;

    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour != 12) {
      hour += 12;
    }

    if (!isPM && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ============================================================
  // PICK TIME
  // ============================================================

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (startTime ?? TimeOfDay.now())
          : (endTime ?? TimeOfDay.now()),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    });
  }

  // ============================================================
  // SAVE CLASS
  // ============================================================

  Future<void> saveClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Start Time and End Time")),
      );

      return;
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;

    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    // ==========================================================
    // TIME VALIDATION
    // ==========================================================

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End Time must be after Start Time")),
      );

      return;
    }

    // ==========================================================
    // CHECK OVERLAP
    // ==========================================================

    final overlap = TimetableService.hasOverlap(
      day: selectedDay,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      department: selectedDepartment,
      section: selectedSection,
      semester: selectedSemester,
      excludeClass: widget.editClass,
    );

    if (overlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Class overlaps with another class on this day"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final subject = subjectController.text.trim();
    final faculty = facultyController.text.trim();
    final room = roomController.text.trim();

    // ==========================================================
    // EDIT CLASS
    // ==========================================================

    if (isEditing) {
      final item = widget.editClass!;

      item.subject = subject;
      item.faculty = faculty;
      item.room = room;

      item.day = selectedDay;

      item.startTime = _formatTime(startTime!);
      item.endTime = _formatTime(endTime!);

      // IMPORTANT:
      // Keep profile-based department, semester and section.
      item.department = selectedDepartment;
      item.semester = selectedSemester;
      item.section = selectedSection;

      await TimetableService.updateClass(item);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Class updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
    // ==========================================================
    // ADD NEW CLASS
    // ==========================================================
    else {
      final newClass = Timetable(
        subject: subject,
        faculty: faculty,
        room: room,
        day: selectedDay,
        startTime: _formatTime(startTime!),
        endTime: _formatTime(endTime!),

        // IMPORTANT:
        // These values come from the current student profile.
        department: selectedDepartment,
        semester: selectedSemester,
        section: selectedSection,
      );

      final success = await TimetableService.addClass(newClass);

      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to save class. Timetable storage is not ready.",
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Class added successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }

    // ==========================================================
    // RETURN TO TIMETABLE
    // ==========================================================

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    subjectController.dispose();
    facultyController.dispose();
    roomController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),

        appBar: AppBar(
          title: Text(isEditing ? "Edit Class" : "Add Class"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),

        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = availableSubjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: Text(isEditing ? "Edit Class" : "Add Class"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              const SizedBox(height: 10),

              // ==================================================
              // PROFILE INFORMATION
              // ==================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,

                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Icon(Icons.school, color: Colors.blue.shade700),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Adding class for",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            "$selectedDepartment • "
                            "$selectedSemester • "
                            "Section $selectedSection",

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SUBJECT
              // ==================================================
              if (subjects.isEmpty)
                TextFormField(
                  controller: subjectController,

                  decoration: const InputDecoration(
                    labelText: "Subject",
                    hintText: "Enter Subject Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.menu_book),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter Subject Name";
                    }

                    return null;
                  },
                )
              else
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: subjectController.text),

                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();

                    if (query.isEmpty) {
                      return subjects;
                    }

                    return subjects.where(
                      (subject) => subject.toLowerCase().contains(query),
                    );
                  },

                  onSelected: (value) {
                    subjectController.text = value;
                  },

                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        if (controller.text != subjectController.text) {
                          controller.text = subjectController.text;
                        }

                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,

                          decoration: const InputDecoration(
                            labelText: "Subject",
                            hintText: "Select or search subject",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.menu_book),
                          ),

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Select Subject";
                            }

                            return null;
                          },

                          onChanged: (value) {
                            subjectController.text = value;
                          },

                          onFieldSubmitted: (_) {
                            onFieldSubmitted();
                          },
                        );
                      },

                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,

                      child: Material(
                        elevation: 6,

                        borderRadius: BorderRadius.circular(12),

                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 250,
                            maxWidth: 350,
                          ),

                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),

                            shrinkWrap: true,

                            itemCount: options.length,

                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);

                              return ListTile(
                                leading: const Icon(
                                  Icons.menu_book,
                                  color: Colors.blue,
                                ),

                                title: Text(option),

                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 18),

              // ==================================================
              // FACULTY
              // ==================================================
              TextFormField(
                controller: facultyController,

                decoration: const InputDecoration(
                  labelText: "Faculty",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Faculty Name";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // ROOM
              // ==================================================
              TextFormField(
                controller: roomController,

                decoration: const InputDecoration(
                  labelText: "Room",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter Room Name";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // DEPARTMENT
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedDepartment,

                decoration: const InputDecoration(
                  labelText: "Department",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),

                items: [
                  DropdownMenuItem<String>(
                    value: selectedDepartment,
                    child: Text(selectedDepartment),
                  ),
                ],

                onChanged: null,
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SEMESTER
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedSemester,

                decoration: const InputDecoration(
                  labelText: "Semester",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book),
                ),

                items: [
                  DropdownMenuItem<String>(
                    value: selectedSemester,
                    child: Text(selectedSemester),
                  ),
                ],

                onChanged: null,
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SECTION
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedSection,

                decoration: const InputDecoration(
                  labelText: "Section",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),

                items: [
                  DropdownMenuItem<String>(
                    value: selectedSection,
                    child: Text("Section $selectedSection"),
                  ),
                ],

                onChanged: null,
              ),

              const SizedBox(height: 18),

              // ==================================================
              // DAY
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedDay,

                decoration: const InputDecoration(
                  labelText: "Day",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),

                items: days.map((day) {
                  return DropdownMenuItem<String>(value: day, child: Text(day));
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedDay = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TIME
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickTime(true),

                      icon: const Icon(Icons.access_time),

                      label: Text(
                        startTime == null
                            ? "Start Time"
                            : startTime!.format(context),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickTime(false),

                      icon: const Icon(Icons.access_time_filled),

                      label: Text(
                        endTime == null ? "End Time" : endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: saveClass,

                  icon: Icon(isEditing ? Icons.update : Icons.save),

                  label: Text(
                    isEditing ? "Update Class" : "Save Class",

                    style: const TextStyle(fontSize: 18),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
