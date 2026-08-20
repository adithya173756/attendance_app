import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'attendance_history.g.dart';

@HiveType(typeId: 2)
class AttendanceHistory extends HiveObject {
  @HiveField(0)
  String subjectName;

  @HiveField(1)
  bool isPresent;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  int? timetableKey;

  AttendanceHistory({
    required this.subjectName,
    required this.isPresent,
    required this.dateTime,
    this.timetableKey,
  });

  String get formattedDate => DateFormat("dd MMM yyyy").format(dateTime);

  String get formattedTime => DateFormat("hh:mm a").format(dateTime);

  String get status => isPresent ? "Present" : "Absent";
}
