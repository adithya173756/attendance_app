import 'package:hive/hive.dart';

part 'assignment.g.dart';

@HiveType(typeId: 4)
class Assignment extends HiveObject {
  @HiveField(0)
  String subject;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime dueDate;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  String priority;

  Assignment({
    required this.subject,
    required this.title,
    required this.dueDate,
    this.completed = false,
    this.priority = "Medium",
  });
}
