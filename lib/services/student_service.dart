import 'package:hive/hive.dart';
import '../models/student.dart';

class StudentService {
  static const String boxName = "studentBox";

  static Future<Box<Student>> _box() async {
    return await Hive.openBox<Student>(boxName);
  }

  static Future<void> saveStudent(Student student) async {
    final box = await _box();
    await box.put("profile", student);
  }

  static Future<bool> hasProfile() async {
    final box = await Hive.openBox<Student>(boxName);
    return box.isNotEmpty;
  }

  static Future<Student?> getStudent() async {
    final box = await _box();
    return box.get("profile");
  }

  static Future<void> deleteStudent() async {
    final box = await _box();
    await box.delete("profile");
  }

  static Future<bool> hasStudent() async {
    final box = await _box();
    return box.containsKey("profile");
  }
}
