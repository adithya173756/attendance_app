import 'package:flutter/material.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exam Scheduler")),
      body: const Center(
        child: Text("No Exams Added", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
