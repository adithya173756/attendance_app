import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 1)
class Student extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String rollNumber;

  @HiveField(2)
  String department;

  @HiveField(3)
  String semester;

  @HiveField(4)
  String section;

  @HiveField(5)
  String phone;

  Student({
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.semester,
    required this.section,
    required this.phone,
  });
}
