import '../models/subject.dart';

class CSITSubjects {
  static List<Subject> getSemesterSubjects(String semester) {
    switch (semester) {
      case "3-1":
        return [
          Subject(
            name: "Internet of Things",
            faculty: "Mr. P S V Surya Kumar (PSV)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Computer Networks",
            faculty: "Sri. P Mouna (PMOU)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Visual Design and Communication",
            faculty: "Sri. N Aneela (NA)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Data Mining and Data Warehousing",
            faculty: "Dr. K Srinivas Rao (KSR)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Full Stack Development Lab",
            faculty: "Mr. K Sunil Varma (KVS)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Data Mining and Data Warehousing Lab",
            faculty: "Dr. K Srinivas Rao (KSR)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "SEC: Tinkering Lab",
            faculty: "Sri. N Navya (NN)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Soft Skills",
            faculty: "Dr. P. Bhuvaneswari (PB)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Quantitative Aptitude",
            faculty: "Mr. B. Naga Babu (BNB)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
          Subject(
            name: "Training & Placement",
            faculty: "Dr. N. G. K. Murthy (NGKM)",
            semester: "3-1",
            minimumAttendance: 75,
          ),
        ];

      default:
        return [];
    }
  }
}
