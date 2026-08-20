import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../models/student.dart';

import '../services/auth_service.dart';
import '../services/subject_service.dart';
import '../services/timetable_service.dart';
import '../services/attendance_history_service.dart';
import '../services/app_refresh_service.dart';

import 'login_screen.dart';
import '../widgets/bottom_nav.dart';

class StudentProfileScreen extends StatefulWidget {
  final bool initialSetup;

  const StudentProfileScreen({super.key, this.initialSetup = false});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final phoneController = TextEditingController();

  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;

  String originalDepartment = "";
  String originalSemester = "";
  String originalSection = "";

  String department = "CSIT";
  String semester = "3-1";
  String section = "A";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    try {
      final student = await StudentService.getStudent();

      if (!mounted) {
        return;
      }

      if (student == null) {
        setState(() {
          isLoading = false;
          isEditing = false;
        });

        return;
      }

      nameController.text = student.name;
      rollController.text = student.rollNumber;
      phoneController.text = student.phone;

      department = student.department;
      semester = student.semester;
      section = student.section;

      originalDepartment = student.department;
      originalSemester = student.semester;
      originalSection = student.section;

      isEditing = true;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // CHECK ACADEMIC DETAILS CHANGED
  // ============================================================

  bool get academicDetailsChanged {
    return isEditing &&
        (originalDepartment != department ||
            originalSemester != semester ||
            originalSection != section);
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    if (isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ==========================================================
    // ACADEMIC CHANGE CONFIRMATION
    // ==========================================================

    if (academicDetailsChanged) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Academic Details Changed"),
            content: const Text(
              "Your Department, Semester or Section has changed.\n\n"
              "Your current timetable and subjects are based on the "
              "previous academic details.\n\n"
              "They will be cleared and fresh subjects can be loaded "
              "for the new details.\n\n"
              "Do you want to continue?",
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
                child: const Text("Continue"),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      if (confirmed != true) {
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // CLEAR OLD ACADEMIC DATA
      // ========================================================

      if (academicDetailsChanged) {
        // Attendance belongs to the academic setup. Keeping old history
        // after replacing subjects would make future deletions/imports
        // corrupt the new subject counters.
        await AttendanceHistoryService.clearHistoryAndSync();
        await SubjectService.clearAllSubjects();
        await TimetableService.clearTimetable();
      }

      // ========================================================
      // CREATE STUDENT
      // ========================================================

      final student = Student(
        name: nameController.text.trim(),
        rollNumber: rollController.text.trim(),
        department: department,
        semester: semester,
        section: section,
        phone: phoneController.text.trim(),
      );

      // ========================================================
      // SAVE STUDENT
      // ========================================================

      await StudentService.saveStudent(student);
      AppRefreshService.refresh();

      // ========================================================
      // DEFAULT SUBJECTS
      //
      // Your current SubjectService has this disabled.
      // Timetable/PDF import is the actual subject source.
      // ========================================================

      await SubjectService.addDefaultSubjects();

      if (widget.initialSetup) {
        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
        );

        return;
      }

      // ========================================================
      // UPDATE ORIGINAL VALUES
      // ========================================================

      originalDepartment = department;
      originalSemester = semester;
      originalSection = section;

      isEditing = true;

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      // ========================================================
      // INITIAL SETUP
      // ========================================================

      if (widget.initialSetup) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
        );

        return;
      }

      // ========================================================
      // NORMAL PROFILE UPDATE
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            academicDetailsChanged
                ? "Profile updated. New academic setup is ready."
                : "Profile updated successfully.",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error saving profile: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to save profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    // ----------------------------------------------------------
    // CONFIRM LOGOUT
    // ----------------------------------------------------------

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
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
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    // ----------------------------------------------------------
    // CANCELLED
    // ----------------------------------------------------------

    if (!mounted || confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // LOGOUT
    //
    // Only loggedIn becomes false.
    //
    // Profile
    // Attendance
    // Subjects
    // Timetable
    // History
    //
    // remain untouched.
    // ----------------------------------------------------------

    await AuthService.logout();

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // GO TO LOGIN
    //
    // Remove previous screens from navigation stack.
    // ----------------------------------------------------------

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Student Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final departmentOptions = <String>{
      'CSIT',
      'CSD',
      if (department.trim().isNotEmpty) department.trim(),
    }.toList();
    final semesterOptions = <String>{
      '1-1',
      '1-2',
      '2-1',
      '2-2',
      '3-1',
      '3-2',
      '4-1',
      '4-2',
      if (semester.trim().isNotEmpty) semester.trim(),
    }.toList();
    final sectionOptions = <String>{
      'A',
      'B',
      'C',
      if (section.trim().isNotEmpty) section.trim(),
    }.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // ==================================================
              // FULL NAME
              // ==================================================

              TextFormField(
                controller: nameController,

                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter your name";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ROLL NUMBER
              // ==================================================
              TextFormField(
                controller: rollController,

                decoration: const InputDecoration(
                  labelText: "Roll Number",
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter your roll number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PHONE
              // ==================================================
              TextFormField(
                controller: phoneController,

                keyboardType: TextInputType.phone,

                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) return 'Enter your phone number';
                  if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // DEPARTMENT
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: departmentOptions.contains(department)
                    ? department
                    : departmentOptions.first,

                decoration: const InputDecoration(
                  labelText: "Department",
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),

                items: departmentOptions
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    department = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SEMESTER
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: semesterOptions.contains(semester) ? semester : semesterOptions.first,

                decoration: const InputDecoration(
                  labelText: "Semester",
                  prefixIcon: Icon(Icons.menu_book),
                  border: OutlineInputBorder(),
                ),

                items: semesterOptions
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    semester = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SECTION
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: sectionOptions.contains(section) ? section : sectionOptions.first,

                decoration: const InputDecoration(
                  labelText: "Section",
                  prefixIcon: Icon(Icons.groups),
                  border: OutlineInputBorder(),
                ),

                items: sectionOptions
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    section = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE / UPDATE BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveProfile,

                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),

                  label: Text(
                    isSaving
                        ? "Saving..."
                        : isEditing
                        ? "Update Profile"
                        : "Save Profile",

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,

                    disabledBackgroundColor: Colors.blue.shade300,

                    disabledForegroundColor: Colors.white,
                  ),
                ),
              ),

              // ==================================================
              // LOGOUT
              //
              // Don't show during first-time profile setup.
              // ==================================================
              if (!widget.initialSetup) ...[
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : _logout,

                    icon: const Icon(Icons.logout, color: Colors.red),

                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    phoneController.dispose();

    super.dispose();
  }
}
