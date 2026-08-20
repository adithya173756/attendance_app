import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/attendance_history.dart';
import '../models/subject.dart';
import '../services/attendance_goal_service.dart';
import '../services/attendance_history_service.dart';

class AttendanceTrendScreen extends StatelessWidget {
  final Subject subject;

  const AttendanceTrendScreen({super.key, required this.subject});

  List<AttendanceHistory> _records() {
    final records = AttendanceHistoryService.history
        .where(
          (record) =>
              record.subjectName.trim().toLowerCase() ==
              subject.name.trim().toLowerCase(),
        )
        .toList();
    records.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return records;
  }

  List<FlSpot> _spots(List<AttendanceHistory> records) {
    var present = 0;
    var total = 0;
    final spots = <FlSpot>[];

    for (var i = 0; i < records.length; i++) {
      if (records[i].isPresent) present++;
      total++;
      spots.add(FlSpot(i.toDouble(), (present / total) * 100));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final records = _records();
    final goal = AttendanceGoalService.goal;
    final spots = _spots(records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Trend'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            subject.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${records.length} recorded class${records.length == 1 ? '' : 'es'}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 54, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 14),
                    const Text(
                      'No trend data yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mark attendance for this subject to build a real attendance trend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 16),
                child: SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      minX: 0,
                      maxX: (spots.length - 1).toDouble().clamp(1.0, double.infinity).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: spots.length <= 8,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= records.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: 25,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: goal,
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3.5,
                          dotData: FlDotData(show: spots.length <= 12),
                          belowBarData: BarAreaData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(context, Icons.check_circle_rounded, 'Present', '${subject.present}', Colors.green),
            _infoCard(context, Icons.cancel_rounded, 'Absent', '${subject.absent}', Colors.red),
            _infoCard(context, Icons.flag_rounded, 'Current goal', '${goal.toStringAsFixed(0)}%', Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
