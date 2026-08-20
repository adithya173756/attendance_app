import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../services/assignment_service.dart';

import 'add_assignment_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  String selectedFilter = "All";

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final assignments = _getFilteredAssignments();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        title: const Text(
          "Assignments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: Column(
        children: [
          // ========================================================
          // SUMMARY
          // ========================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: "Total",
                    value: "${AssignmentService.totalAssignments}",
                    icon: Icons.assignment,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _summaryCard(
                    title: "Pending",
                    value: "${AssignmentService.pendingCount}",
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _summaryCard(
                    title: "Done",
                    value: "${AssignmentService.completedCount}",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // FILTERS
          // ========================================================
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip("All"),
                _filterChip("Pending"),
                _filterChip("Completed"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ========================================================
          // ASSIGNMENT LIST
          // ========================================================
          Expanded(
            child: assignments.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 100),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _assignmentCard(assignments[index]),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ==========================================================
      // ADD ASSIGNMENT
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
          );

          if (result == true && mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Assignment"),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Assignment> _getFilteredAssignments() {
    final all = AssignmentService.assignments;

    if (selectedFilter == "Pending") {
      return all.where((item) => !item.completed).toList();
    }

    if (selectedFilter == "Completed") {
      return all.where((item) => item.completed).toList();
    }

    return all;
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip(String filter) {
    final selected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(filter),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedFilter = filter;
          });
        },
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          color: selected ? Colors.blue.shade900 : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  // ============================================================
  // ASSIGNMENT CARD
  // ============================================================

  Widget _assignmentCard(Assignment assignment) {
    final dueDate = assignment.dueDate;

    final dateText =
        "${dueDate.day.toString().padLeft(2, '0')}/"
        "${dueDate.month.toString().padLeft(2, '0')}/"
        "${dueDate.year}";

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final isOverdue = !assignment.completed && dueDay.isBefore(today);

    // ==========================================================
    // PRIORITY COLOR
    // ==========================================================

    Color priorityColor;

    switch (assignment.priority) {
      case "High":
        priorityColor = Colors.red;
        break;

      case "Low":
        priorityColor = Colors.green;
        break;

      default:
        priorityColor = Colors.orange;
    }

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // CHECKBOX
                // ==================================================

                Checkbox(
                  value: assignment.completed,

                  activeColor: Colors.green,

                  onChanged: (value) async {
                    if (value == true) {
                      await AssignmentService.markCompleted(assignment);
                    } else {
                      await AssignmentService.markPending(assignment);
                    }

                    if (!mounted) return;

                    setState(() {});
                  },
                ),

                const SizedBox(width: 4),

                // ==================================================
                // TITLE
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        assignment.title,

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,

                          decoration: assignment.completed
                              ? TextDecoration.lineThrough
                              : null,

                          color: assignment.completed
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        assignment.subject,

                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DELETE
                // ==================================================
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),

                  onPressed: () {
                    _deleteAssignment(assignment);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ======================================================
            // BOTTOM INFORMATION
            // ======================================================
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isOverdue ? Colors.red : Colors.blue,
                ),

                const SizedBox(width: 6),

                Text(
                  isOverdue ? "Overdue: $dateText" : "Due: $dateText",

                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey.shade700,

                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Text(
                    assignment.priority,

                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELETE ASSIGNMENT
  // ============================================================

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Assignment"),

          content: Text(
            "Are you sure you want to delete "
            "\"${assignment.title}\"?",
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

    await AssignmentService.deleteAssignment(assignment);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Assignment deleted")));
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    String message;

    if (selectedFilter == "Pending") {
      message = "No pending assignments";
    } else if (selectedFilter == "Completed") {
      message = "No completed assignments";
    } else {
      message = "No assignments yet";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          Text(
            message,

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Add an assignment using the button below",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
