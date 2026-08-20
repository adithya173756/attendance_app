import '../models/exam.dart';

class ExamService {
  static final List<Exam> exams = [];

  static void addExam(Exam exam) {
    exams.add(exam);
  }

  static void deleteExam(Exam exam) {
    exams.remove(exam);
  }
}
