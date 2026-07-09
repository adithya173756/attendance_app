class Subject {
  String name;
  int presentClasses;
  int absentClasses;
  int minimumAttendance;

  Subject({
    required this.name,
    this.presentClasses = 0,
    this.absentClasses = 0,
    this.minimumAttendance = 75,
  });

  int get totalClasses => presentClasses + absentClasses;

  double get attendancePercentage {
    if (totalClasses == 0) return 0;
    return (presentClasses / totalClasses) * 100;
  }
}
