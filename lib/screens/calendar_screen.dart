import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/attendance_history_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final history = AttendanceHistoryService.history;

  List get selectedHistory {
    if (_selectedDay == null) return [];

    return history.where((item) {
      return item.dateTime.year == _selectedDay!.year &&
          item.dateTime.month == _selectedDay!.month &&
          item.dateTime.day == _selectedDay!.day;
    }).toList();
  }

  bool hasPresent(DateTime day) {
    return history.any(
      (item) => item.isPresent && isSameDay(item.dateTime, day),
    );
  }

  bool hasAbsent(DateTime day) {
    return history.any(
      (item) => !item.isPresent && isSameDay(item.dateTime, day),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Calendar")),

      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2025),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (hasPresent(day)) {
                  return const Align(
                    alignment: Alignment.bottomCenter,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                if (hasAbsent(day)) {
                  return const Align(
                    alignment: Alignment.bottomCenter,
                    child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                  );
                }

                return null;
              },
            ),

            calendarStyle: CalendarStyle(
              todayDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),

            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          Expanded(
            child: selectedHistory.isEmpty
                ? const Center(child: Text("No attendance"))
                : ListView.builder(
                    itemCount: selectedHistory.length,
                    itemBuilder: (_, index) {
                      final item = selectedHistory[index];

                      return ListTile(
                        leading: Icon(
                          item.isPresent ? Icons.check_circle : Icons.cancel,
                          color: item.isPresent ? Colors.green : Colors.red,
                        ),
                        title: Text(item.subjectName),
                        subtitle: Text(item.dateTime.toString()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
