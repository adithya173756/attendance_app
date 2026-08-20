import 'package:flutter/material.dart';

class AttendancePredictorScreen extends StatelessWidget {
  const AttendancePredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Predictor")),
      body: const Center(
        child: Text(
          "Attendance Predictor",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
