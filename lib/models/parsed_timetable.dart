class ParsedSubject {
  final String code;
  final String name;
  final String faculty;

  ParsedSubject({
    required this.code,
    required this.name,
    required this.faculty,
  });
}

class ParsedClass {
  final String day;
  final int period;
  final String subject;
  final String facultyCode;
  final String room;

  // NEW
  final String startTime;
  final String endTime;

  ParsedClass({
    required this.day,
    required this.period,
    required this.subject,
    required this.facultyCode,
    required this.room,
    required this.startTime,
    required this.endTime,
  });
}

class ParsedTimetable {
  final String department;
  final String semester;
  final String section;

  final List<ParsedSubject> subjects;
  final List<ParsedClass> classes;

  ParsedTimetable({
    required this.department,
    required this.semester,
    required this.section,
    required this.subjects,
    required this.classes,
  });
}
