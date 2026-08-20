import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

import '../models/timetable.dart';

class TimetableImportService {
  // ============================================================
  // MAIN PDF PARSER
  // ============================================================

  static Future<List<Timetable>> parsePdf(
    Uint8List bytes, {
    required String department,
    required String semester,
    required String section,
  }) async {
    if (bytes.isEmpty) {
      throw Exception("PDF is empty");
    }

    File? pdfFile;
    PdfImageRenderer? renderer;
    TextRecognizer? recognizer;

    try {
      // --------------------------------------------------------
      // SAVE PDF TEMPORARILY
      // --------------------------------------------------------

      final tempDir = await getTemporaryDirectory();

      pdfFile = File(
        '${tempDir.path}/attendance_timetable_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await pdfFile.writeAsBytes(bytes, flush: true);

      // --------------------------------------------------------
      // OPEN PDF
      // --------------------------------------------------------

      renderer = PdfImageRenderer(path: pdfFile.path);

      await renderer.open();

      final pageCount = await renderer.getPageCount();

      if (pageCount == 0) {
        throw Exception("No pages found in PDF");
      }

      // --------------------------------------------------------
      // THIS COLLEGE TIMETABLE IS ONE PAGE
      // --------------------------------------------------------

      final pageIndex = 0;

      await renderer.openPage(pageIndex: pageIndex);

      final pageSize = await renderer.getPageSize(pageIndex: pageIndex);

      // Render at higher resolution for OCR.
      final renderedBytes = await renderer.renderPage(
        pageIndex: pageIndex,
        x: 0,
        y: 0,
        width: pageSize.width,
        height: pageSize.height,
        scale: 2.0,
        background: Colors.white,
      );

      await renderer.closePage(pageIndex: pageIndex);

      if (renderedBytes == null || renderedBytes.isEmpty) {
        throw Exception("Unable to render timetable PDF");
      }

      // --------------------------------------------------------
      // SAVE RENDERED IMAGE
      // --------------------------------------------------------

      final imageFile = File(
        '${tempDir.path}/attendance_timetable_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await imageFile.writeAsBytes(renderedBytes, flush: true);

      // --------------------------------------------------------
      // OCR
      // --------------------------------------------------------

      recognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final inputImage = InputImage.fromFilePath(imageFile.path);

      final recognizedText = await recognizer.processImage(inputImage);

      debugPrint("========== TIMETABLE OCR START ==========");
      debugPrint(recognizedText.text);
      debugPrint("=========== TIMETABLE OCR END ===========");

      if (recognizedText.text.trim().isEmpty) {
        throw Exception("No readable text found in timetable PDF.");
      }

      // --------------------------------------------------------
      // COLLECT OCR LINES
      // --------------------------------------------------------

      final lines = <_OcrLine>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final value = line.text.trim();

          if (value.isEmpty) {
            continue;
          }

          lines.add(_OcrLine(text: value, box: line.boundingBox));
        }
      }

      if (lines.isEmpty) {
        throw Exception("OCR could not detect timetable text.");
      }

      // --------------------------------------------------------
      // PARSE GRID
      // --------------------------------------------------------

      final result = _parseTimetableGrid(
        lines,
        department: department,
        semester: semester,
        section: section,
      );

      if (result.isEmpty) {
        throw Exception("Timetable structure could not be detected.");
      }

      // --------------------------------------------------------
      // DELETE TEMP IMAGE
      // --------------------------------------------------------

      try {
        await imageFile.delete();
      } catch (_) {}

      return result;
    } finally {
      recognizer?.close();

      try {
        await renderer?.close();
      } catch (_) {}

      if (pdfFile != null) {
        try {
          await pdfFile.delete();
        } catch (_) {}
      }
    }
  }

  // ============================================================
  // PARSE TIMETABLE GRID
  // ============================================================

  static List<Timetable> _parseTimetableGrid(
    List<_OcrLine> lines, {
    required String department,
    required String semester,
    required String section,
  }) {
    // ----------------------------------------------------------
    // DAYS
    // ----------------------------------------------------------

    final dayRows = <_DayRow>[];

    const dayNames = {
      "mon": "Mon",
      "monday": "Mon",
      "tue": "Tue",
      "tuesday": "Tue",
      "wed": "Wed",
      "wednesday": "Wed",
      "thu": "Thu",
      "thursday": "Thu",
      "fri": "Fri",
      "friday": "Fri",
      "sat": "Sat",
      "saturday": "Sat",
      "sun": "Sun",
      "sunday": "Sun",
    };

    for (final line in lines) {
      final normalized = _clean(line.text).toLowerCase();

      String? day;

      for (final entry in dayNames.entries) {
        final pattern = RegExp(
          r'\b' + RegExp.escape(entry.key) + r'\b',
          caseSensitive: false,
        );

        if (pattern.hasMatch(normalized)) {
          day = entry.value;
          break;
        }
      }

      if (day != null) {
        dayRows.add(_DayRow(day: day, y: line.box.center.dy));
      }
    }

    final uniqueDays = <String, _DayRow>{};

    for (final row in dayRows) {
      if (!uniqueDays.containsKey(row.day)) {
        uniqueDays[row.day] = row;
      }
    }

    final rows = uniqueDays.values.toList()..sort((a, b) => a.y.compareTo(b.y));

    debugPrint("========== GRID DEBUG ==========");
    debugPrint("Detected day rows: ${rows.length}");

    for (final row in rows) {
      debugPrint("DAY=${row.day} Y=${row.y}");
    }

    debugPrint("================================");

    // ----------------------------------------------------------
    // PERIOD HEADER DETECTION
    // ----------------------------------------------------------

    final periodCenters = <int, double>{};

    for (final line in lines) {
      final value = line.text.trim();

      final match = RegExp(r'^[1-9]$').firstMatch(value);

      if (match == null) {
        continue;
      }

      final number = int.tryParse(value);

      if (number == null || number < 1 || number > 9) {
        continue;
      }

      // Only accept numbers above the day rows.
      final nearestDayY = rows.map((e) => e.y).reduce((a, b) => math.min(a, b));

      if (line.box.center.dy < nearestDayY) {
        periodCenters[number] = line.box.center.dx;
      }
    }

    // If OCR misses the period numbers, use the known
    // college timetable structure as fallback.
    debugPrint("Detected period centers: ${periodCenters.length}");
    debugPrint(periodCenters.toString());

    if (periodCenters.length < 5) {
      return _parseUsingGridFallback(
        lines,
        rows,
        department: department,
        semester: semester,
        section: section,
      );
    }

    final sortedPeriods = periodCenters.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // ----------------------------------------------------------
    // PERIOD BOUNDARIES
    // ----------------------------------------------------------

    final boundaries = <int, _PeriodBoundary>{};

    for (int i = 0; i < sortedPeriods.length; i++) {
      final period = sortedPeriods[i].key;
      final center = sortedPeriods[i].value;

      final previous = i == 0
          ? center - 50
          : (sortedPeriods[i - 1].value + center) / 2;

      final next = i == sortedPeriods.length - 1
          ? center + 50
          : (center + sortedPeriods[i + 1].value) / 2;

      boundaries[period] = _PeriodBoundary(left: previous, right: next);
    }

    // ----------------------------------------------------------
    // PARSE EACH DAY
    // ----------------------------------------------------------

    final result = <Timetable>[];

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      final nextY = rowIndex + 1 < rows.length
          ? rows[rowIndex + 1].y
          : row.y + 100;

      final previousY = rowIndex == 0 ? row.y - 100 : rows[rowIndex - 1].y;

      final rowHeight = math.max(30, math.min(100, (nextY - previousY) / 2));

      final tolerance = rowHeight * 0.65;

      final rowLines = lines.where((line) {
        final y = line.box.center.dy;

        return (y - row.y).abs() <= tolerance;
      }).toList();

      for (final line in rowLines) {
        final text = _clean(line.text);

        if (text.isEmpty) {
          continue;
        }

        if (_isDayText(text)) {
          continue;
        }

        if (_isNoise(text)) {
          continue;
        }

        final slots = _findOverlappingPeriods(line.box, boundaries);

        if (slots.isEmpty) {
          continue;
        }

        final subjectData = _normalizeSubject(text);

        if (subjectData == null) {
          continue;
        }

        // A merged cell can cover multiple periods.
        for (final period in slots) {
          final time = _periodTime(period);

          if (time == null) {
            continue;
          }

          result.add(
            Timetable(
              subject: subjectData.subject,
              faculty: subjectData.faculty,
              room: subjectData.room,
              day: row.day,
              startTime: time.start,
              endTime: time.end,
              department: department,
              semester: semester,
              section: section,
              period: period,
            ),
          );
        }
      }
    }

    final deduplicated = _deduplicate(result);

    return _mergeConsecutivePeriods(deduplicated);
  }

  // ============================================================
  // FALLBACK GRID
  //
  // Specifically matches the timetable structure in the
  // uploaded CSIT-A / CSIT-B / CSD PDFs.
  // ============================================================

  static List<Timetable> _parseUsingGridFallback(
    List<_OcrLine> lines,
    List<_DayRow> rows, {
    required String department,
    required String semester,
    required String section,
  }) {
    final result = <Timetable>[];

    // These are relative positions of the 9 periods in the
    // timetable image. We don't need exact pixel dimensions.
    //
    // P1-P4 are before lunch.
    // P5-P9 are after lunch.

    final minX = lines.isEmpty
        ? 0.0
        : lines.map((e) => e.box.left).reduce(math.min);

    final maxX = lines.isEmpty
        ? 900.0
        : lines.map((e) => e.box.right).reduce(math.max);

    final width = maxX - minX;

    if (width <= 0) {
      return [];
    }

    // Approximate centers.
    final centers = <int, double>{
      1: minX + width * 0.10,
      2: minX + width * 0.20,
      3: minX + width * 0.30,
      4: minX + width * 0.40,
      5: minX + width * 0.61,
      6: minX + width * 0.71,
      7: minX + width * 0.81,
      8: minX + width * 0.90,
      9: minX + width * 0.97,
    };

    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      final nextY = rowIndex + 1 < rows.length
          ? rows[rowIndex + 1].y
          : row.y + 100;

      final tolerance = math.max(22, (nextY - row.y) * 0.45);

      final rowLines = lines.where((line) {
        return (line.box.center.dy - row.y).abs() <= tolerance;
      }).toList();

      for (final line in rowLines) {
        final text = _clean(line.text);

        debugPrint(
          'OCR LINE: "${line.text}" | '
          'X=${line.box.left} Y=${line.box.top}',
        );

        if (_isDayText(text) || _isNoise(text)) {
          continue;
        }

        final subjectData = _normalizeSubject(text);

        if (subjectData == null) {
          continue;
        }

        int? nearestPeriod;
        double nearestDistance = double.infinity;

        for (final entry in centers.entries) {
          final distance = (line.box.center.dx - entry.value).abs();

          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestPeriod = entry.key;
          }
        }

        if (nearestPeriod == null) {
          continue;
        }

        final time = _periodTime(nearestPeriod);

        if (time == null) {
          continue;
        }

        result.add(
          Timetable(
            subject: subjectData.subject,
            faculty: subjectData.faculty,
            room: subjectData.room,
            day: row.day,
            startTime: time.start,
            endTime: time.end,
            department: department,
            semester: semester,
            section: section,
            period: nearestPeriod,
          ),
        );
      }
    }

    final deduplicated = _deduplicate(result);

    return _mergeConsecutivePeriods(deduplicated);
  }

  // ============================================================
  // FIND PERIODS OVERLAPPED BY OCR BOX
  // ============================================================

  static List<int> _findOverlappingPeriods(
    Rect box,
    Map<int, _PeriodBoundary> boundaries,
  ) {
    final result = <int>[];

    for (final entry in boundaries.entries) {
      final boundary = entry.value;

      final overlapLeft = math.max(box.left, boundary.left);

      final overlapRight = math.min(box.right, boundary.right);

      final overlap = overlapRight - overlapLeft;

      if (overlap > 4) {
        result.add(entry.key);
      }
    }

    return result;
  }

  // ============================================================
  // PERIOD TIMES
  // ============================================================

  static _PeriodTime? _periodTime(int period) {
    switch (period) {
      case 1:
        return const _PeriodTime("09:00 AM", "09:45 AM");

      case 2:
        return const _PeriodTime("09:45 AM", "10:30 AM");

      case 3:
        return const _PeriodTime("10:30 AM", "11:15 AM");

      case 4:
        return const _PeriodTime("11:15 AM", "12:00 PM");

      case 5:
        return const _PeriodTime("01:30 PM", "02:15 PM");

      case 6:
        return const _PeriodTime("02:15 PM", "03:00 PM");

      case 7:
        return const _PeriodTime("03:00 PM", "03:45 PM");

      case 8:
        return const _PeriodTime("03:45 PM", "04:30 PM");

      default:
        return null;
    }
  }

  // ============================================================
  // SUBJECT NORMALIZATION
  // ============================================================

  static _SubjectData? _normalizeSubject(String raw) {
    var text = raw.trim();

    if (text.isEmpty) {
      return null;
    }

    final upper = text.toUpperCase();

    // ----------------------------------------------------------
    // SPORTS / YOGA
    // ----------------------------------------------------------

    if (upper.contains("SPORT") || upper.contains("YOGA")) {
      return const _SubjectData(subject: "Sports/Yoga");
    }

    // ----------------------------------------------------------
    // COUNSELLING
    // ----------------------------------------------------------

    if (upper.contains("COUNSELL")) {
      return const _SubjectData(subject: "Counselling");
    }

    // ----------------------------------------------------------
    // TRAINING & PLACEMENT
    // ----------------------------------------------------------

    if (upper == "T&P" || upper.contains("TRAINING AND PLACEMENT")) {
      return const _SubjectData(subject: "Training & Placement");
    }

    // ----------------------------------------------------------
    // IOT
    // ----------------------------------------------------------

    if (RegExp(r'\bIOT\b', caseSensitive: false).hasMatch(text)) {
      return _SubjectData(
        subject: "Internet of Things",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // COMPUTER NETWORKS
    // ----------------------------------------------------------

    if (RegExp(r'\bCN\b', caseSensitive: false).hasMatch(text) ||
        upper.contains("COMPUTER NETWORK")) {
      return _SubjectData(
        subject: "Computer Networks",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // VDC
    // ----------------------------------------------------------

    if (RegExp(r'\bVDC\b', caseSensitive: false).hasMatch(text) ||
        upper.contains("VISUAL DESIGN")) {
      return _SubjectData(
        subject: "Visual Design and Communication",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // DWDM LAB
    // ----------------------------------------------------------

    if (upper.contains("DWDM LAB")) {
      return _SubjectData(
        subject: "Data Mining and Data Warehousing Lab",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // DWDM
    // ----------------------------------------------------------

    if (RegExp(r'\bDWDM\b', caseSensitive: false).hasMatch(text) ||
        upper.contains("DATA MINING")) {
      return _SubjectData(
        subject: "Data Mining and Data Warehousing",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // FSD LAB
    // ----------------------------------------------------------

    if (upper.contains("FSD LAB") || upper.contains("FULL STACK")) {
      return _SubjectData(
        subject: "Full Stack Development Lab",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // TINKERING LAB
    // ----------------------------------------------------------

    if (upper.contains("TINKERING")) {
      return _SubjectData(
        subject: "Tinkering Lab",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // SOFT SKILLS
    // ----------------------------------------------------------

    if (upper.contains("SOFT SKILL") ||
        RegExp(r'\bSS\b', caseSensitive: false).hasMatch(text)) {
      return _SubjectData(
        subject: "Soft Skills",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // QA
    // ----------------------------------------------------------

    if (RegExp(r'\bQA\b', caseSensitive: false).hasMatch(text) ||
        upper.contains("QUANTITATIVE")) {
      return _SubjectData(
        subject: "Quantitative Aptitude",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // OE
    // ----------------------------------------------------------

    if (RegExp(r'\bOE(?:-1)?\b', caseSensitive: false).hasMatch(text)) {
      return _SubjectData(
        subject: "Open Elective",
        faculty: _extractFaculty(text),
        room: _extractRoom(text),
      );
    }

    // ----------------------------------------------------------
    // UNKNOWN / NOISE
    // ----------------------------------------------------------

    // Ignore obvious timetable labels.
    if (upper.contains("PERIOD") ||
        upper == "LUNCH" ||
        upper == "CODE" ||
        upper.contains("COURSE") ||
        upper.contains("TEACHER") ||
        upper.contains("CREDIT")) {
      return null;
    }

    // Don't import tiny OCR fragments.
    if (text.length < 2) {
      return null;
    }

    return _SubjectData(
      subject: _cleanSubjectName(text),
      faculty: _extractFaculty(text),
      room: _extractRoom(text),
    );
  }

  // ============================================================
  // FACULTY
  // ============================================================

  static String _extractFaculty(String text) {
    final match = RegExp(
      r'(?:\(|\s)([A-Z][A-Za-z. ]{2,40})\)',
    ).firstMatch(text);

    if (match != null) {
      return match.group(1)?.trim() ?? "";
    }

    return "";
  }

  // ============================================================
  // ROOM
  // ============================================================

  static String _extractRoom(String text) {
    final match = RegExp(
      r'\bU[- ]?\d{3}\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      return match.group(0)!.replaceAll(" ", "");
    }

    return "";
  }

  // ============================================================
  // CLEAN SUBJECT
  // ============================================================

  static String _cleanSubjectName(String value) {
    var text = value;

    text = text.replaceAll(
      RegExp(r'\bU[- ]?\d{3}\b', caseSensitive: false),
      "",
    );

    text = text.replaceAll(
      RegExp(r'\bLAB[- ]?\d+\b', caseSensitive: false),
      "",
    );

    text = text.replaceAll(RegExp(r'\[[A-Z0-9]+\]'), "");

    text = text.replaceAll(RegExp(r'\s+'), " ");

    return text.trim();
  }

  // ============================================================
  // NOISE
  // ============================================================

  static bool _isNoise(String text) {
    final upper = text.toUpperCase();

    if (upper == "L") return true;
    if (upper == "U") return true;
    if (upper == "N") return true;
    if (upper == "C") return true;
    if (upper == "H") return true;

    if (upper == "LUNCH") return true;

    if (RegExp(r'^[1-9]$').hasMatch(text)) {
      return true;
    }

    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(text)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // DAY TEXT
  // ============================================================

  static bool _isDayText(String text) {
    final clean = text.toLowerCase().trim();

    const days = {
      "mon",
      "monday",
      "tue",
      "tuesday",
      "wed",
      "wednesday",
      "thu",
      "thursday",
      "fri",
      "friday",
      "sat",
      "saturday",
      "sun",
      "sunday",
    };

    return days.contains(clean);
  }

  // ============================================================
  // CLEAN OCR
  // ============================================================

  static String _clean(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ============================================================
  // DEDUPLICATE
  // ============================================================

  static List<Timetable> _deduplicate(List<Timetable> input) {
    final map = <String, Timetable>{};

    for (final item in input) {
      final key =
          "${item.day}|"
          "${item.period}|"
          "${item.subject}|"
          "${item.department}|"
          "${item.semester}|"
          "${item.section}";

      map[key] = item;
    }

    final result = map.values.toList();

    result.sort((a, b) {
      const order = {
        "Mon": 1,
        "Tue": 2,
        "Wed": 3,
        "Thu": 4,
        "Fri": 5,
        "Sat": 6,
        "Sun": 7,
      };

      final dayCompare = (order[a.day] ?? 99).compareTo(order[b.day] ?? 99);

      if (dayCompare != 0) {
        return dayCompare;
      }

      return a.period.compareTo(b.period);
    });

    return result;
  }

  // ============================================================
  // MERGE CONSECUTIVE PERIODS
  // ============================================================

  static List<Timetable> _mergeConsecutivePeriods(List<Timetable> input) {
    if (input.isEmpty) {
      return [];
    }

    final sorted = [...input];

    sorted.sort((a, b) {
      const dayOrder = {
        "Mon": 1,
        "Tue": 2,
        "Wed": 3,
        "Thu": 4,
        "Fri": 5,
        "Sat": 6,
        "Sun": 7,
      };

      final dayCompare = (dayOrder[a.day] ?? 99).compareTo(
        dayOrder[b.day] ?? 99,
      );

      if (dayCompare != 0) {
        return dayCompare;
      }

      return a.period.compareTo(b.period);
    });

    final result = <Timetable>[];

    for (final current in sorted) {
      if (result.isEmpty) {
        result.add(current);
        continue;
      }

      final previous = result.last;

      final sameClass =
          previous.day == current.day &&
          previous.subject == current.subject &&
          previous.faculty == current.faculty &&
          previous.room == current.room &&
          previous.department == current.department &&
          previous.semester == current.semester &&
          previous.section == current.section &&
          current.period == previous.period + 1;

      if (sameClass) {
        final mergedFaculty = previous.faculty.trim().isNotEmpty
            ? previous.faculty
            : current.faculty;

        final mergedRoom = previous.room.trim().isNotEmpty
            ? previous.room
            : current.room;

        result[result.length - 1] = Timetable(
          subject: previous.subject,
          faculty: mergedFaculty,
          room: mergedRoom,
          day: previous.day,
          startTime: previous.startTime,
          endTime: current.endTime,
          department: previous.department,
          semester: previous.semester,
          section: previous.section,
          period: previous.period,
        );
      } else {
        result.add(current);
      }
    }

    return result;
  }

  // ============================================================
  // END OF TIMETABLE IMPORT SERVICE
  // ============================================================
}

// ============================================================
// OCR LINE
// ============================================================

class _OcrLine {
  final String text;
  final Rect box;

  const _OcrLine({required this.text, required this.box});
}

// ============================================================
// DAY ROW
// ============================================================

class _DayRow {
  final String day;
  final double y;

  const _DayRow({required this.day, required this.y});
}

// ============================================================
// PERIOD BOUNDARY
// ============================================================

class _PeriodBoundary {
  final double left;
  final double right;

  const _PeriodBoundary({required this.left, required this.right});
}

// ================================================================
// PERIOD TIME
// ================================================================

class _PeriodTime {
  final String start;
  final String end;

  const _PeriodTime(this.start, this.end);
}

// ================================================================
// SUBJECT DATA
// ================================================================

class _SubjectData {
  final String subject;
  final String faculty;
  final String room;

  const _SubjectData({
    required this.subject,
    this.faculty = "",
    this.room = "",
  });
}
