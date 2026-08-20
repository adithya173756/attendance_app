// lib/services/timetable_parser_service.dart

import '../models/ocr_line.dart';
import '../models/parsed_timetable.dart';

class TimetableParserService {
  // ================================================================
  // SUBJECT CATALOG
  // ================================================================

  static _SubjectInfo? _resolveSubjectInfo(String value) {
    var key = value
        .toUpperCase()
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // --------------------------------------------------------------
    // Normalize LAB suffixes
    //
    // DWDM LAB-I
    // DWDM LAB I
    // DWDM LAB-III
    // --------------------------------------------------------------

    key = key.replaceAll(
      RegExp(r'\bLAB\s*[-–]?\s*[IVX]+\b', caseSensitive: false),
      'LAB',
    );

    // --------------------------------------------------------------
    // Fix duplicated LAB text
    //
    // DWDM LAB LAB
    // DWDM LAB LAB-I
    // --------------------------------------------------------------

    key = key.replaceAll(RegExp(r'\bLAB\s+LAB\b'), 'LAB');

    key = key
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const catalog = <String, _SubjectInfo>{
      // ============================================================
      // IOT
      // ============================================================

      'IOT': _SubjectInfo(code: 'B23CT3101', name: 'Internet of Things'),

      'INTERNET OF THINGS': _SubjectInfo(
        code: 'B23CT3101',
        name: 'Internet of Things',
      ),

      // ============================================================
      // COMPUTER NETWORKS
      // ============================================================
      'CN': _SubjectInfo(code: 'B23CD3102', name: 'Computer Networks'),

      'COMPUTER NETWORKS': _SubjectInfo(
        code: 'B23CD3102',
        name: 'Computer Networks',
      ),

      // ============================================================
      // VDC
      // ============================================================
      'VDC': _SubjectInfo(
        code: 'B23CT3102',
        name: 'Visual Design and Communication',
      ),

      'VISUAL DESIGN AND COMMUNICATION': _SubjectInfo(
        code: 'B23CT3102',
        name: 'Visual Design and Communication',
      ),

      // ============================================================
      // DWDM
      // ============================================================
      'DWDM': _SubjectInfo(
        code: 'B23CD3103',
        name: 'Data Mining and Data Warehousing',
      ),

      'DATA MINING AND DATA WAREHOUSING': _SubjectInfo(
        code: 'B23CD3103',
        name: 'Data Mining and Data Warehousing',
      ),

      // ============================================================
      // FSD LAB
      // ============================================================
      'FSD LAB': _SubjectInfo(
        code: 'B23CT3106',
        name: 'Full Stack Development-2 Lab',
      ),

      'FULL STACK DEVELOPMENT 2 LAB': _SubjectInfo(
        code: 'B23CT3106',
        name: 'Full Stack Development-2 Lab',
      ),

      'FULL STACK DEVELOPMENT-2 LAB': _SubjectInfo(
        code: 'B23CT3106',
        name: 'Full Stack Development-2 Lab',
      ),

      // ============================================================
      // DWDM LAB
      // ============================================================
      'DWDM LAB': _SubjectInfo(
        code: 'B23CT3107',
        name: 'Data Mining and Data Warehousing Lab',
      ),

      'DATA MINING AND DATA WAREHOUSING LAB': _SubjectInfo(
        code: 'B23CT3107',
        name: 'Data Mining and Data Warehousing Lab',
      ),

      // ============================================================
      // SOFT SKILLS
      // ============================================================
      'SOFT SKILLS': _SubjectInfo(code: 'B23BS3101', name: 'Soft Skills'),

      // ============================================================
      // TINKERING LAB
      // ============================================================
      'TINKERING LAB': _SubjectInfo(code: 'B23CT3108', name: 'Tinkering Lab'),

      // ============================================================
      // OPEN ELECTIVE
      // ============================================================
      'OE': _SubjectInfo(code: 'OE-1', name: 'Open Elective-I'),

      'OE I': _SubjectInfo(code: 'OE-1', name: 'Open Elective-I'),

      'OE 1': _SubjectInfo(code: 'OE-1', name: 'Open Elective-I'),

      'OPEN ELECTIVE I': _SubjectInfo(code: 'OE-1', name: 'Open Elective-I'),

      'OPEN ELECTIVE-I': _SubjectInfo(code: 'OE-1', name: 'Open Elective-I'),

      // ============================================================
      // NON-COURSE ACTIVITIES
      // ============================================================
      'QA': _SubjectInfo(code: '', name: 'Quantitative Aptitude'),

      'QUANTITATIVE APTITUDE': _SubjectInfo(
        code: '',
        name: 'Quantitative Aptitude',
      ),

      'T P': _SubjectInfo(code: '', name: 'Training & Placement'),

      'TRAINING PLACEMENT': _SubjectInfo(
        code: '',
        name: 'Training & Placement',
      ),

      'TRAINING AND PLACEMENT': _SubjectInfo(
        code: '',
        name: 'Training & Placement',
      ),

      'COUNSELLING': _SubjectInfo(code: '', name: 'Counselling'),
    };

    return catalog[key];
  }

  // ================================================================
  // PUBLIC ENTRY POINT
  // ================================================================

  static ParsedTimetable parseTimetable(
    String text, {
    List<OcrLine>? ocrLines,
  }) {
    final normalizedText = _normalizeText(text);

    final department = _extractDepartment(normalizedText);
    final semester = _extractSemester(normalizedText);
    final section = _extractSection(normalizedText);

    final classes = parseClasses(normalizedText, ocrLines: ocrLines);

    final subjects = _mergeSubjectsFromClasses(classes, text: normalizedText);

    return ParsedTimetable(
      department: department,
      semester: semester,
      section: section,
      subjects: subjects,
      classes: classes,
    );
  }

  // ================================================================
  // PUBLIC CLASS PARSER
  // ================================================================

  static List<ParsedClass> parseClasses(
    String text, {
    List<OcrLine>? ocrLines,
  }) {
    if (ocrLines != null && ocrLines.isNotEmpty) {
      final gridResult = _parseGridTimeTable(ocrLines);

      if (gridResult.isNotEmpty) {
        return _removeDuplicateClasses(gridResult);
      }
    }

    return _removeDuplicateClasses(_parseClassesFromText(text));
  }

  // ================================================================
  // DEPARTMENT
  // ================================================================

  static String _extractDepartment(String text) {
    final patterns = [
      RegExp(
        r'\b(?:DEPARTMENT|DEPT)\s*[:-]?\s*([A-Z][A-Z0-9&/ -]{1,30})',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(CSIT|CSE|ECE|EEE|MECH|CIVIL|IT|AIML|AI\s*ML|DS|CSD)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match == null) {
        continue;
      }

      var value = match.group(1)?.trim() ?? '';

      value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (value.isNotEmpty) {
        return value.toUpperCase();
      }
    }

    return '';
  }

  // ================================================================
  // SEMESTER
  // ================================================================

  static String _extractSemester(String text) {
    // --------------------------------------------------------------
    // Standard formats
    // --------------------------------------------------------------

    final patterns = [
      RegExp(
        r'\b(?:SEMESTER|SEM)\s*[:\-]?\s*([1-8]\s*[-\/]\s*[1-2])\b',
        caseSensitive: false,
      ),

      RegExp(r'\b([1-8]\s*[-\/]\s*[1-2])\b', caseSensitive: false),

      // III/IV-B.Tech.I-Semester
      // III / IV B.Tech I Semester
      RegExp(
        r'\bIII\s*\/?\s*IV\b.*?\bI\s*[- ]?\s*SEMESTER\b',
        caseSensitive: false,
      ),

      // III B.Tech I Semester
      RegExp(r'\bIII\b.*?\bI\s*[- ]?\s*SEMESTER\b', caseSensitive: false),

      // 3rd Year 1st Semester
      RegExp(
        r'\b3(?:RD|TH)?\s*YEAR\b.*?\b1(?:ST|TH)?\s*SEMESTER\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match == null) {
        continue;
      }

      // Special handling for:
      // III/IV-B.Tech.I-Semester
      if (pattern.pattern.contains('III')) {
        return '3-1';
      }

      final captured = match.group(1);

      if (captured != null && captured.trim().isNotEmpty) {
        return captured
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('/', '-')
            .toUpperCase();
      }
    }

    // --------------------------------------------------------------
    // Infer 3-1 from R23 third-year course codes.
    //
    // Example:
    // B23CD3103
    // B23CT3107
    // --------------------------------------------------------------

    final courseCodeMatch = RegExp(
      r'\bB\d{2}[A-Z]{2,8}31\d{2,3}\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (courseCodeMatch != null) {
      return '3-1';
    }

    return '';
  }

  // ================================================================
  // SECTION
  // ================================================================

  static String _extractSection(String text) {
    final patterns = [
      // SECTION: B
      RegExp(r'\bSECTION\s*[:\-]?\s*([A-Z0-9])\b', caseSensitive: false),

      // SEC: B
      RegExp(r'\bSEC\s*[:\-]?\s*([A-Z0-9])\b', caseSensitive: false),

      // CSIT-A / CSIT A
      RegExp(
        r'\b(?:CSIT|CSE|ECE|EEE|IT)\s*[-\/]?\s*([A-Z])\b',
        caseSensitive: false,
      ),

      // SECTION B
      RegExp(r'\b(?:SEC|SECTION)\s+([A-Z0-9])\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);

      if (match == null) {
        continue;
      }

      final value = match.group(1)?.trim() ?? '';

      if (value.isNotEmpty) {
        return value.toUpperCase();
      }
    }

    return '';
  }

  // ================================================================
  // MERGE SUBJECTS FROM CLASSES
  // ================================================================

  static List<ParsedSubject> _mergeSubjectsFromClasses(
    List<ParsedClass> classes, {
    String text = '',
  }) {
    final result = <ParsedSubject>[];

    final existingByName = <String, ParsedSubject>{};
    final existingByCode = <String, ParsedSubject>{};

    final classGroups = <String, List<ParsedClass>>{};

    for (final item in classes) {
      var cleanName = _cleanClassSubject(item.subject);

      if (cleanName.isEmpty) {
        continue;
      }

      // Convert abbreviation to official name.
      final resolved = _resolveSubjectInfo(cleanName);

      if (resolved != null) {
        cleanName = resolved.name;
      }

      if (_isInvalidSubjectName(cleanName)) {
        continue;
      }

      if (_isExcludedActivity(cleanName)) {
        continue;
      }

      final key = _normalizeSubjectName(cleanName);

      if (key.isEmpty) {
        continue;
      }

      classGroups.putIfAbsent(key, () => []).add(item);
    }

    for (final entry in classGroups.entries) {
      final classItems = entry.value;

      if (classItems.isEmpty) {
        continue;
      }

      final first = classItems.first;

      var cleanName = _cleanClassSubject(first.subject);

      final resolved = _resolveSubjectInfo(cleanName);

      String code = '';

      if (resolved != null) {
        cleanName = resolved.name;
        code = resolved.code;
      }

      if (cleanName.isEmpty) {
        continue;
      }

      String faculty = '';

      for (final item in classItems) {
        final facultyCode = item.facultyCode.trim();

        if (facultyCode.isNotEmpty && !_isMetadataCode(facultyCode)) {
          faculty = facultyCode.toUpperCase();
          break;
        }
      }

      final subjectInfo = _resolveSubjectInfo(cleanName);

      final subject = ParsedSubject(
        code: subjectInfo?.code ?? '',
        name: subjectInfo?.name ?? cleanName,
        faculty: faculty,
      );

      result.add(subject);

      existingByName[_normalizeSubjectName(cleanName)] = subject;

      if (code.isNotEmpty) {
        existingByCode[_normalizeCode(code)] = subject;
      }
    }

    // --------------------------------------------------------------
    // Extract additional subjects directly from OCR text.
    // --------------------------------------------------------------

    final detectedSubjects = _extractSubjectsFromText(text);

    for (var subject in detectedSubjects) {
      var name = subject.name;
      var code = subject.code;

      final resolved = _resolveSubjectInfo(name);

      if (resolved != null) {
        name = resolved.name;

        if (code.isEmpty) {
          code = resolved.code;
        }
      }

      final nameKey = _normalizeSubjectName(name);
      final codeKey = _normalizeCode(code);

      if (nameKey.isEmpty && codeKey.isEmpty) {
        continue;
      }

      if (_isExcludedActivity(name)) {
        continue;
      }

      // If same subject already exists but has no code,
      // update the existing subject with the detected code.
      final existing = existingByName[nameKey];

      if (existing != null) {
        if (existing.code.isEmpty && code.isNotEmpty) {
          final index = result.indexOf(existing);

          if (index != -1) {
            final updated = ParsedSubject(
              code: code,
              name: existing.name,
              faculty: existing.faculty.isNotEmpty
                  ? existing.faculty
                  : subject.faculty,
            );

            result[index] = updated;
            existingByName[nameKey] = updated;
            existingByCode[codeKey] = updated;
          }
        }

        continue;
      }

      if (codeKey.isNotEmpty && existingByCode.containsKey(codeKey)) {
        continue;
      }

      final updatedSubject = ParsedSubject(
        code: code,
        name: name,
        faculty: subject.faculty,
      );

      result.add(updatedSubject);

      if (nameKey.isNotEmpty) {
        existingByName[nameKey] = updatedSubject;
      }

      if (codeKey.isNotEmpty) {
        existingByCode[codeKey] = updatedSubject;
      }
    }

    return _removeDuplicateSubjects(result);
  }

  // ================================================================
  // SUBJECT EXTRACTION FROM OCR TEXT
  // ================================================================

  static List<ParsedSubject> _extractSubjectsFromText(String text) {
    final result = <ParsedSubject>[];

    final lines = _cleanLines(text);

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      if (line.isEmpty) {
        continue;
      }

      // ------------------------------------------------------------
      // Ignore metadata / timetable structural lines.
      // ------------------------------------------------------------

      if (_isMetadataLine(line)) {
        continue;
      }

      if (_isHeaderLine(line)) {
        continue;
      }

      if (_detectDay(line) != null) {
        continue;
      }

      if (_looksLikeTime(line)) {
        continue;
      }

      if (_isExcludedActivity(line)) {
        continue;
      }

      // ------------------------------------------------------------
      // Course code.
      //
      // Example:
      // B23CD3102
      // B23CT3106
      // B23CT3108
      // ------------------------------------------------------------

      final codeMatch = RegExp(
        r'\b(B\d{2}[A-Z]{2,8}\d{3,6})\b',
        caseSensitive: false,
      ).firstMatch(line);

      if (codeMatch == null) {
        continue;
      }

      final code = codeMatch.group(1)?.toUpperCase() ?? '';

      if (code.isEmpty) {
        continue;
      }

      var beforeCode = line.substring(0, codeMatch.start).trim();

      var afterCode = line.substring(codeMatch.end).trim();

      beforeCode = beforeCode.replaceAll(RegExp(r'[\|\:\-]+$'), '').trim();

      afterCode = afterCode.replaceAll(RegExp(r'^[\|\:\-]+'), '').trim();

      // ------------------------------------------------------------
      // Remove section metadata.
      // ------------------------------------------------------------

      beforeCode = _removeMetadataPrefix(beforeCode);
      afterCode = _removeMetadataPrefix(afterCode);

      // ------------------------------------------------------------
      // Never treat [SEC: / SEC: / SECTION: as subject.
      // ------------------------------------------------------------

      if (_looksLikeSectionMetadata(beforeCode)) {
        beforeCode = '';
      }

      if (_looksLikeSectionMetadata(afterCode)) {
        afterCode = '';
      }

      String subjectName = '';

      if (beforeCode.isNotEmpty) {
        subjectName = beforeCode;
      } else if (afterCode.isNotEmpty) {
        subjectName = afterCode;
      }

      subjectName = _cleanSubjectNameFromText(subjectName);

      if (subjectName.isEmpty) {
        continue;
      }

      if (_isMetadataLine(subjectName)) {
        continue;
      }

      if (_isInvalidSubjectName(subjectName)) {
        continue;
      }

      if (_isExcludedActivity(subjectName)) {
        continue;
      }

      String faculty = '';

      final facultyMatch = RegExp(
        r'([A-Z]{1,8})',
        caseSensitive: false,
      ).firstMatch(line);

      if (facultyMatch != null) {
        final candidate = facultyMatch.group(1)?.toUpperCase() ?? '';

        if (!_isMetadataCode(candidate)) {
          faculty = candidate;
        }
      }

      result.add(
        ParsedSubject(code: code, name: subjectName, faculty: faculty),
      );
    }

    return _removeDuplicateSubjects(result);
  }

  // ================================================================
  // REMOVE DUPLICATE SUBJECTS
  // ================================================================

  static List<ParsedSubject> _removeDuplicateSubjects(
    List<ParsedSubject> subjects,
  ) {
    final unique = <ParsedSubject>[];

    final seenCodes = <String>{};
    final seenNames = <String>{};

    for (final subject in subjects) {
      final code = _normalizeCode(subject.code);
      final name = _normalizeSubjectName(subject.name);

      if (code.isEmpty && name.isEmpty) {
        continue;
      }

      if (_isExcludedActivity(subject.name)) {
        continue;
      }

      if (code.isNotEmpty && seenCodes.contains(code)) {
        continue;
      }

      if (name.isNotEmpty && seenNames.contains(name)) {
        continue;
      }

      if (code.isNotEmpty) {
        seenCodes.add(code);
      }

      if (name.isNotEmpty) {
        seenNames.add(name);
      }

      unique.add(subject);
    }

    return unique;
  }

  // ================================================================
  // GRID TIMETABLE PARSER
  // ================================================================

  static List<ParsedClass> _parseGridTimeTable(List<OcrLine> originalLines) {
    final lines = originalLines
        .where((line) => line.text.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return [];
    }

    final periodHeaders = _findPeriodHeaderPositions(lines);

    if (periodHeaders.length < 3) {
      return [];
    }

    final dayRows = <_GridDayRow>[];

    for (final line in lines) {
      final day = _detectDay(line.text);

      if (day == null) {
        continue;
      }

      if (!_looksLikeTimetableDayRow(line, lines)) {
        continue;
      }

      dayRows.add(_GridDayRow(day: day, line: line));
    }

    if (dayRows.isEmpty) {
      return [];
    }

    final uniqueDays = <String, _GridDayRow>{};

    for (final row in dayRows) {
      final key = '${row.line.pageIndex}_${row.day}';

      uniqueDays.putIfAbsent(key, () => row);
    }

    final sortedDays = uniqueDays.values.toList()
      ..sort((a, b) => a.line.centerY.compareTo(b.line.centerY));

    final classes = <ParsedClass>[];

    for (final dayRow in sortedDays) {
      classes.addAll(
        _findClassesForDayRow(
          dayRow: dayRow,
          lines: lines,
          periodHeaders: periodHeaders,
        ),
      );
    }

    return _removeDuplicateClasses(classes);
  }

  // ================================================================
  // PERIOD HEADER POSITIONS
  // ================================================================

  static List<_PeriodColumn> _findPeriodHeaderPositions(List<OcrLine> lines) {
    final candidates = <OcrLine>[];

    for (final line in lines) {
      final value = line.text.trim();

      if (!RegExp(r'^[1-9]$').hasMatch(value)) {
        continue;
      }

      candidates.add(line);
    }

    if (candidates.isEmpty) {
      return [];
    }

    candidates.sort((a, b) => a.centerY.compareTo(b.centerY));

    List<OcrLine> bestGroup = [];

    for (final candidate in candidates) {
      final group = candidates
          .where((other) => (other.centerY - candidate.centerY).abs() <= 25)
          .toList();

      if (group.length > bestGroup.length) {
        bestGroup = group;
      }
    }

    bestGroup.sort((a, b) => a.centerX.compareTo(b.centerX));

    final result = <_PeriodColumn>[];
    final usedNumbers = <int>{};

    for (final line in bestGroup) {
      final number = int.tryParse(line.text.trim());

      if (number == null) {
        continue;
      }

      if (number < 1 || number > 9) {
        continue;
      }

      if (usedNumbers.contains(number)) {
        continue;
      }

      usedNumbers.add(number);

      result.add(_PeriodColumn(period: number, centerX: line.centerX));
    }

    result.sort((a, b) => a.period.compareTo(b.period));

    return result;
  }

  // ================================================================
  // DAY ROW CHECK
  // ================================================================

  static bool _looksLikeTimetableDayRow(OcrLine dayLine, List<OcrLine> lines) {
    final nearby = lines.where((line) {
      if (line.pageIndex != dayLine.pageIndex) {
        return false;
      }

      if (identical(line, dayLine)) {
        return false;
      }

      return (line.centerY - dayLine.centerY).abs() <= 40;
    }).toList();

    return nearby.length >= 2;
  }

  // ================================================================
  // FIND CLASSES FOR DAY
  // ================================================================

  static List<ParsedClass> _findClassesForDayRow({
    required _GridDayRow dayRow,
    required List<OcrLine> lines,
    required List<_PeriodColumn> periodHeaders,
  }) {
    final result = <ParsedClass>[];

    final dayLine = dayRow.line;

    final rowLines = lines.where((line) {
      if (line.pageIndex != dayLine.pageIndex) {
        return false;
      }

      if (identical(line, dayLine)) {
        return false;
      }

      final distance = (line.centerY - dayLine.centerY).abs();

      return distance <= 35;
    }).toList();

    rowLines.sort((a, b) => a.centerX.compareTo(b.centerX));

    for (final line in rowLines) {
      var subject = line.text.trim();

      if (subject.isEmpty) {
        continue;
      }

      if (_isLunchNoise(subject)) {
        continue;
      }

      if (_isExcludedActivity(subject)) {
        continue;
      }

      if (_isMetadataLine(subject)) {
        continue;
      }

      if (_isDayOnly(subject)) {
        continue;
      }

      if (_isPeriodNumber(subject)) {
        continue;
      }

      if (_looksLikeTime(subject)) {
        continue;
      }

      if (_isHeaderLine(subject)) {
        continue;
      }

      subject = _cleanClassCellText(subject);

      if (subject.isEmpty) {
        continue;
      }

      if (_isLikelyNonSubject(subject)) {
        continue;
      }

      final period = _findNearestPeriod(line.centerX, periodHeaders);

      if (period == null) {
        continue;
      }

      if (period == 9) {
        continue;
      }

      final timing = _periodTiming(period);

      final facultyCode = _extractFacultyCode(subject);

      final room = _extractRoom(subject);

      var cleanSubject = _removeClassMetadata(subject);

      if (cleanSubject.isEmpty) {
        continue;
      }

      // Resolve abbreviation to official full subject name.
      final subjectInfo = _resolveSubjectInfo(cleanSubject);

      if (subjectInfo != null) {
        cleanSubject = subjectInfo.name;
      }

      if (_isInvalidSubjectName(cleanSubject)) {
        continue;
      }

      if (_isExcludedActivity(cleanSubject)) {
        continue;
      }

      result.add(
        ParsedClass(
          day: dayRow.day,
          period: period,
          subject: cleanSubject,
          facultyCode: facultyCode,
          room: room,
          startTime: timing.start,
          endTime: timing.end,
        ),
      );
    }

    return result;
  }

  // ================================================================
  // FIND NEAREST PERIOD
  // ================================================================

  static int? _findNearestPeriod(double x, List<_PeriodColumn> columns) {
    if (columns.isEmpty) {
      return null;
    }

    _PeriodColumn? nearest;
    double? distance;

    for (final column in columns) {
      final currentDistance = (x - column.centerX).abs();

      if (distance == null || currentDistance < distance) {
        distance = currentDistance;
        nearest = column;
      }
    }

    return nearest?.period;
  }

  // ================================================================
  // CLEAN CLASS CELL
  // ================================================================

  static String _cleanClassCellText(String value) {
    var result = value.trim();

    result = result
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result;
  }

  // ================================================================
  // FACULTY CODE
  // ================================================================

  static String _extractFacultyCode(String value) {
    final matches = RegExp(
      r'\(([A-Z]{1,8})\)',
      caseSensitive: false,
    ).allMatches(value);

    if (matches.isEmpty) {
      return '';
    }

    for (final match in matches) {
      final candidate = match.group(1)?.toUpperCase() ?? '';

      if (candidate.isEmpty) {
        continue;
      }

      if (_isMetadataCode(candidate)) {
        continue;
      }

      return candidate;
    }

    return '';
  }

  // ================================================================
  // ROOM
  // ================================================================

  static String _extractRoom(String value) {
    final patterns = [
      RegExp(r'\b(U-\d+[A-Z]?)\b', caseSensitive: false),
      RegExp(r'\b(LAB[- ]?\d+[A-Z]?)\b', caseSensitive: false),
      RegExp(r'\b(ROOM[- ]?\d+[A-Z]?)\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);

      if (match == null) {
        continue;
      }

      var room = match.group(1) ?? '';

      room = room
          .replaceAll(RegExp(r'U-40S', caseSensitive: false), 'U-405')
          .toUpperCase();

      return room;
    }

    return '';
  }

  // ================================================================
  // REMOVE CLASS METADATA
  // ================================================================

  static String _removeClassMetadata(String value) {
    var result = value.trim();

    // Remove parenthesized faculty information.
    //
    // DWDM LAB(KSR,PMA,SM K)
    // -> DWDM LAB
    result = result.replaceAll(RegExp(r'\([^)]*\)'), '');

    // Course code
    result = result.replaceAll(
      RegExp(r'\bB\d{2}[A-Z]{2,8}\d{3,6}\b', caseSensitive: false),
      '',
    );

    // Section metadata
    result = result.replaceAll(
      RegExp(r'\[?\s*(?:SEC|SECTION)\s*:[^\]]*\]?', caseSensitive: false),
      '',
    );

    // Rooms
    result = result.replaceAll(
      RegExp(r'\bU-\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\bLAB[- ]?\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\bROOM[- ]?\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    // Period
    result = result.replaceAll(
      RegExp(r'\bP\d{1,2}\b', caseSensitive: false),
      '',
    );

    // Remove lab section suffixes.
    // Examples:
    // DWDM LAB-I   -> DWDM LAB
    // DWDM LAB-II  -> DWDM LAB
    // DWDM LAB-III -> DWDM LAB
    result = result.replaceAll(
      RegExp(r'\bLAB\s*[-–]?\s*[IVX]+\b', caseSensitive: false),
      'LAB',
    );

    // Remove duplicated LAB.
    // Example:
    // DWDM LAB LAB -> DWDM LAB
    result = result.replaceAll(
      RegExp(r'\bLAB\s+LAB\b', caseSensitive: false),
      'LAB',
    );

    result = result
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result;
  }

  // ================================================================
  // CLEAN CLASS SUBJECT
  // ================================================================

  static String _cleanClassSubject(String value) {
    var result = value.trim();

    if (result.isEmpty) {
      return '';
    }

    // Remove faculty information.
    result = result.replaceAll(RegExp(r'\([^)]*\)'), '');

    // Remove course codes.
    result = result.replaceAll(
      RegExp(r'\bB\d{2}[A-Z]{2,8}\d{3,6}\b', caseSensitive: false),
      '',
    );

    // Remove section metadata.
    result = result.replaceAll(
      RegExp(r'\[?\s*(?:SEC|SECTION)\s*:[^\]]*\]?', caseSensitive: false),
      '',
    );

    // Remove rooms.
    result = result.replaceAll(
      RegExp(r'\bU-\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\bLAB[- ]?\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\bROOM[- ]?\d+[A-Z]?\b', caseSensitive: false),
      '',
    );

    // IMPORTANT:
    // DWDM LAB-I -> DWDM LAB
    // DWDM LAB I -> DWDM LAB
    result = result.replaceAll(
      RegExp(r'\bLAB\s*[-–]?\s*[IVX]+\b', caseSensitive: false),
      'LAB',
    );

    // Remove period.
    result = result.replaceAll(
      RegExp(r'\bP\d{1,2}\b', caseSensitive: false),
      '',
    );

    result = result
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('|', ' ')
        .replaceAll(':', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result;
  }

  // ================================================================
  // LUNCH / ACTIVITY NOISE
  // ================================================================

  static bool _isLunchNoise(String value) {
    final text = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

    const values = {'L', 'U', 'N', 'C', 'H', 'LUNCH', 'BREAK'};

    return values.contains(text);
  }

  // ================================================================
  // SPORTS / YOGA
  // ================================================================

  static bool _isExcludedActivity(String value) {
    var text = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\[\]\(\):|_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) {
      return false;
    }

    // Exact matches.
    const exact = {
      'SPORTS',
      'YOGA',
      'SPORTS YOGA',
      'SPORTS / YOGA',
      'SPORTS AND YOGA',
      'SPORTS & YOGA',
    };

    if (exact.contains(text)) {
      return true;
    }

    // Any timetable cell containing these activities.
    if (text.contains('SPORTS')) {
      return true;
    }

    if (text.contains('YOGA')) {
      return true;
    }

    return false;
  }

  // ================================================================
  // PERIOD TIMING
  // ================================================================

  static _PeriodTiming _periodTiming(int period) {
    switch (period) {
      case 1:
        return const _PeriodTiming(start: '09:00 AM', end: '09:45 AM');

      case 2:
        return const _PeriodTiming(start: '09:45 AM', end: '10:30 AM');

      case 3:
        return const _PeriodTiming(start: '10:30 AM', end: '11:15 AM');

      case 4:
        return const _PeriodTiming(start: '11:15 AM', end: '12:00 PM');

      case 5:
        return const _PeriodTiming(start: '01:30 PM', end: '02:15 PM');

      case 6:
        return const _PeriodTiming(start: '02:15 PM', end: '03:00 PM');

      case 7:
        return const _PeriodTiming(start: '03:00 PM', end: '03:45 PM');

      case 8:
        return const _PeriodTiming(start: '03:45 PM', end: '04:30 PM');

      case 9:
        return const _PeriodTiming(start: '', end: '');

      default:
        return const _PeriodTiming(start: '', end: '');
    }
  }

  // ================================================================
  // TEXT FALLBACK CLASS PARSER
  // ================================================================

  static List<ParsedClass> _parseClassesFromText(String text) {
    final lines = _cleanLines(text);

    final classes = <ParsedClass>[];

    String? currentDay;
    int currentPeriod = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_isExcludedActivity(line)) {
        continue;
      }

      final day = _detectDay(line);

      if (day != null) {
        currentDay = day;
        currentPeriod = 0;
        continue;
      }

      if (currentDay == null) {
        continue;
      }

      final time = _extractTimeRange(line);

      if (time == null) {
        continue;
      }

      currentPeriod++;

      var subject = _extractClassSubjectFromText(line);

      if (subject.isEmpty && i + 1 < lines.length) {
        final next = lines[i + 1];

        if (_detectDay(next) == null &&
            _extractTimeRange(next) == null &&
            !_isMetadataLine(next) &&
            !_isExcludedActivity(next)) {
          subject = _cleanClassSubject(next);
        }
      }

      if (subject.isEmpty) {
        continue;
      }

      final facultyCode = _extractFacultyCode(subject);

      final room = _extractRoom(subject);

      var cleanSubject = _removeClassMetadata(subject);

      if (cleanSubject.isEmpty) {
        continue;
      }

      // Resolve abbreviated OCR names to official subject name/code.
      final subjectInfo = _resolveSubjectInfo(cleanSubject);

      if (subjectInfo != null) {
        cleanSubject = subjectInfo.name;
      }

      if (_isExcludedActivity(cleanSubject)) {
        continue;
      }

      classes.add(
        ParsedClass(
          day: currentDay,
          period: currentPeriod,
          subject: cleanSubject,
          facultyCode: facultyCode,
          room: room,
          startTime: time['start'] ?? '',
          endTime: time['end'] ?? '',
        ),
      );
    }

    return _removeDuplicateClasses(classes);
  }

  // ================================================================
  // TEXT CLASS SUBJECT
  // ================================================================

  static String _extractClassSubjectFromText(String line) {
    var result = line;

    if (_isMetadataLine(result)) {
      return '';
    }

    if (_isExcludedActivity(result)) {
      return '';
    }

    result = result.replaceAll(
      RegExp(r'\d{1,2}[:.]\d{2}\s*(?:AM|PM)?', caseSensitive: false),
      ' ',
    );

    result = result.replaceAll(
      RegExp(r'\bB\d{2}[A-Z]{2,8}\d{3,6}\b', caseSensitive: false),
      ' ',
    );

    result = result.replaceAll(
      RegExp(
        r'\b(?:ROOM|R\.?NO\.?|U-|LAB[- ]?)\s*[A-Z0-9-]+\b',
        caseSensitive: false,
      ),
      ' ',
    );

    result = _cleanClassSubject(result);

    if (_isInvalidSubjectName(result)) {
      return '';
    }

    if (_isExcludedActivity(result)) {
      return '';
    }

    if (_isMetadataLine(result)) {
      return '';
    }

    return result;
  }

  // ================================================================
  // DAY DETECTION
  // ================================================================

  static String? _detectDay(String line) {
    final value = line.trim().toUpperCase();

    if (RegExp(r'\bMON(?:DAY)?\b').hasMatch(value)) {
      return 'Mon';
    }

    if (RegExp(r'\bTUE(?:SDAY)?\b').hasMatch(value)) {
      return 'Tue';
    }

    if (RegExp(r'\bWED(?:NESDAY)?\b').hasMatch(value)) {
      return 'Wed';
    }

    if (RegExp(r'\bTHU(?:RSDAY)?\b').hasMatch(value)) {
      return 'Thu';
    }

    if (RegExp(r'\bFRI(?:DAY)?\b').hasMatch(value)) {
      return 'Fri';
    }

    if (RegExp(r'\bSAT(?:URDAY)?\b').hasMatch(value)) {
      return 'Sat';
    }

    if (RegExp(r'\bSUN(?:DAY)?\b').hasMatch(value)) {
      return 'Sun';
    }

    return null;
  }

  // ================================================================
  // TIME DETECTION
  // ================================================================

  static bool _looksLikeTime(String line) {
    return RegExp(
      r'\b\d{1,2}[:.]\d{2}\s*(?:AM|PM)?\b',
      caseSensitive: false,
    ).hasMatch(line);
  }

  // ================================================================
  // TIME RANGE
  // ================================================================

  static Map<String, String>? _extractTimeRange(String line) {
    final match = RegExp(
      r'(\d{1,2}[:.]\d{2}\s*(?:AM|PM)?)'
      r'\s*(?:-|–|to)\s*'
      r'(\d{1,2}[:.]\d{2}\s*(?:AM|PM)?)',
      caseSensitive: false,
    ).firstMatch(line);

    if (match == null) {
      return null;
    }

    return {
      'start': _normalizeTime(match.group(1)!),
      'end': _normalizeTime(match.group(2)!),
    };
  }

  // ================================================================
  // NORMALIZE TIME
  // ================================================================

  static String _normalizeTime(String value) {
    var result = value
        .toUpperCase()
        .replaceAll('.', ':')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (!result.contains('AM') && !result.contains('PM')) {
      final parts = result.split(':');

      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;

        if (hour < 12) {
          result = '$result AM';
        } else {
          result = '$result PM';
        }
      }
    }

    return result;
  }

  // ================================================================
  // PERIOD NUMBER
  // ================================================================

  static bool _isPeriodNumber(String value) {
    final text = value.trim().toUpperCase();

    return RegExp(r'^(?:P)?\d{1,2}$').hasMatch(text);
  }

  // ================================================================
  // DAY ONLY
  // ================================================================

  static bool _isDayOnly(String value) {
    return _detectDay(value) != null && !RegExp(r'\d').hasMatch(value);
  }

  // ================================================================
  // DUPLICATE CLASSES
  // ================================================================

  static List<ParsedClass> _removeDuplicateClasses(List<ParsedClass> classes) {
    final unique = <ParsedClass>[];
    final seen = <String>{};

    for (final item in classes) {
      if (_isExcludedActivity(item.subject)) {
        continue;
      }

      final key = [
        item.day.toLowerCase().trim(),
        item.period,
        _normalizeSubjectName(item.subject),
        item.facultyCode.toLowerCase().trim(),
        item.room.toLowerCase().trim(),
        item.startTime.toLowerCase().trim(),
        item.endTime.toLowerCase().trim(),
      ].join('|');

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      unique.add(item);
    }

    return unique;
  }

  // ================================================================
  // INVALID SUBJECT CHECK
  // ================================================================

  static bool _isInvalidSubjectName(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return true;
    }

    final normalized = text.toUpperCase().trim();

    const invalid = {
      'L',
      'U',
      'N',
      'C',
      'H',
      'LUNCH',
      'BREAK',
      'PERIOD',
      'TIME',
      'DAY',
      'DAYS',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
      'SEC',
      'SECTION',
    };

    if (invalid.contains(normalized)) {
      return true;
    }

    if (_isMetadataLine(text)) {
      return true;
    }

    if (_isExcludedActivity(text)) {
      return true;
    }

    if (RegExp(r'^[^A-Z0-9]+$').hasMatch(text)) {
      return true;
    }

    if (RegExp(r'^\d+$').hasMatch(text)) {
      return true;
    }

    return false;
  }

  // ================================================================
  // LIKELY NON-SUBJECT
  // ================================================================

  static bool _isLikelyNonSubject(String value) {
    final text = value.trim().toUpperCase();

    if (_isExcludedActivity(text)) {
      return true;
    }

    if (_isMetadataLine(text)) {
      return true;
    }

    return false;
  }

  // ================================================================
  // HEADER LINE
  // ================================================================

  static bool _isHeaderLine(String value) {
    final text = value.trim().toUpperCase();

    const headers = {
      'DAY',
      'DAYS',
      'PERIOD',
      'PERIODS',
      'TIME',
      'TIMETABLE',
      'CLASS',
      'CLASSES',
      'SUBJECT',
      'SUBJECTS',
      'FACULTY',
      'FACULTY NAME',
      'ROOM',
      'ROOM NO',
    };

    return headers.contains(text);
  }

  // ================================================================
  // METADATA LINE
  // ================================================================

  static bool _isMetadataLine(String value) {
    final text = value.trim().toUpperCase();

    if (text.isEmpty) {
      return false;
    }

    // [SEC:Tinkering lab
    if (RegExp(
      r'^\[?\s*SEC(?:TION)?\s*:',
      caseSensitive: false,
    ).hasMatch(text)) {
      return true;
    }

    // SEC: Tinkering lab
    if (RegExp(r'^\s*SEC(?:TION)?\s*:', caseSensitive: false).hasMatch(text)) {
      return true;
    }

    // [SECTION: A
    if (RegExp(r'^\[?\s*SECTION\s*:', caseSensitive: false).hasMatch(text)) {
      return true;
    }

    return false;
  }

  // ================================================================
  // SECTION METADATA CHECK
  // ================================================================

  static bool _looksLikeSectionMetadata(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return false;
    }

    return RegExp(
      r'^\[?\s*(?:SEC|SECTION)\s*:',
      caseSensitive: false,
    ).hasMatch(text);
  }

  // ================================================================
  // REMOVE METADATA PREFIX
  // ================================================================

  static String _removeMetadataPrefix(String value) {
    var result = value.trim();

    result = result.replaceFirst(
      RegExp(r'^\[?\s*(?:SEC|SECTION)\s*:\s*', caseSensitive: false),
      '',
    );

    return result
        .replaceAll(RegExp(r'^\s*\['), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ================================================================
  // METADATA FACULTY CODE CHECK
  // ================================================================

  static bool _isMetadataCode(String value) {
    final text = value.trim().toUpperCase();

    const invalid = {'SEC', 'SECTION', 'SPORTS', 'YOGA', 'PM', 'AM'};

    return invalid.contains(text);
  }

  // ================================================================
  // NORMALIZE SUBJECT NAME
  // ================================================================

  static String _normalizeSubjectName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ================================================================
  // NORMALIZE COURSE CODE
  // ================================================================

  static String _normalizeCode(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  // ================================================================
  // CLEAN SUBJECT FROM TEXT
  // ================================================================

  static String _cleanSubjectNameFromText(String value) {
    var result = value.trim();

    // Faculty codes.
    result = result.replaceAll(
      RegExp(r'\([A-Z]{1,8}(?:\s*,\s*[A-Z]{1,8})*\)', caseSensitive: false),
      '',
    );

    // Section metadata.
    result = result.replaceAll(
      RegExp(r'^\[?\s*(?:SEC|SECTION)\s*:\s*', caseSensitive: false),
      '',
    );

    // Course codes.
    result = result.replaceAll(
      RegExp(r'\bB\d{2}[A-Z]{2,8}\d{3,6}\b', caseSensitive: false),
      '',
    );

    // Common separators.
    result = result
        .replaceAll(RegExp(r'^[\:\-\|]+'), '')
        .replaceAll(RegExp(r'[\:\-\|]+$'), '');

    // Remove stray brackets.
    result = result.replaceAll('[', '').replaceAll(']', '');

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  // ================================================================
  // CLEAN LINES
  // ================================================================

  static List<String> _cleanLines(String text) {
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .map(_removeOCRNoise)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  // ================================================================
  // OCR NOISE
  // ================================================================

  static String _removeOCRNoise(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ================================================================
  // NORMALIZE TEXT
  // ================================================================

  static String _normalizeText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ================================================================
  // PUBLIC TEXT NORMALIZATION
  // ================================================================

  static String normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _SubjectInfo {
  final String code;
  final String name;

  const _SubjectInfo({required this.code, required this.name});
}

// ==================================================================
// INTERNAL GRID DAY MODEL
// ==================================================================

class _GridDayRow {
  final String day;
  final OcrLine line;

  const _GridDayRow({required this.day, required this.line});
}

// ==================================================================
// INTERNAL PERIOD MODEL
// ==================================================================

class _PeriodColumn {
  final int period;
  final double centerX;

  const _PeriodColumn({required this.period, required this.centerX});
}

// ==================================================================
// INTERNAL TIMING MODEL
// ==================================================================

class _PeriodTiming {
  final String start;
  final String end;

  const _PeriodTiming({required this.start, required this.end});
}
