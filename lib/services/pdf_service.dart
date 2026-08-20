import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/subject_service.dart';

class PdfService {
  static Future<void> generateAttendanceReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Attendance Report",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text(
            "Overall Attendance: "
            "${SubjectService.overallAttendance.toStringAsFixed(1)}%",
          ),

          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            headers: ["Subject", "Present", "Absent", "Attendance %"],
            data: SubjectService.subjects.map((subject) {
              return [
                subject.name,
                subject.present.toString(),
                subject.absent.toString(),
                subject.percentage.toStringAsFixed(1),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          pw.Text("Generated on: ${DateTime.now()}"),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
