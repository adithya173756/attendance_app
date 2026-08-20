import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

import '../models/ocr_line.dart';

class PdfOcrResult {
  final String text;
  final List<OcrLine> lines;

  const PdfOcrResult({required this.text, required this.lines});
}

class PdfTextService {
  // ============================================================
  // EXTRACT OCR FROM PDF
  //
  // PDF
  //   ↓
  // PDF PAGE
  //   ↓
  // IMAGE
  //   ↓
  // ML KIT OCR
  //   ↓
  // TEXT + POSITION
  //
  // Supports multiple PDF pages.
  // ============================================================

  static Future<PdfOcrResult> extractOcr(String path) async {
    final renderer = PdfImageRenderer(path: path);

    try {
      await renderer.open();

      final pageCount = await renderer.getPageCount();

      if (pageCount <= 0) {
        return const PdfOcrResult(text: '', lines: []);
      }

      final tempDirectory = await getTemporaryDirectory();

      final List<String> allText = [];
      final List<OcrLine> allLines = [];

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        try {
          // ------------------------------------------------------
          // OPEN PAGE
          // ------------------------------------------------------

          await renderer.openPage(pageIndex: pageIndex);

          final pageSize = await renderer.getPageSize(pageIndex: pageIndex);

          // ------------------------------------------------------
          // RENDER PAGE
          // ------------------------------------------------------

          final imageBytes = await renderer.renderPage(
            pageIndex: pageIndex,
            x: 0,
            y: 0,
            width: pageSize.width,
            height: pageSize.height,
            scale: 2.0,
          );

          await renderer.closePage(pageIndex: pageIndex);

          if (imageBytes == null || imageBytes.isEmpty) {
            continue;
          }

          // ------------------------------------------------------
          // TEMP IMAGE
          // ------------------------------------------------------

          final imagePath =
              '${tempDirectory.path}/attendance_ocr_page_$pageIndex.png';

          final imageFile = File(imagePath);

          await imageFile.writeAsBytes(imageBytes, flush: true);

          // ------------------------------------------------------
          // ML KIT INPUT
          // ------------------------------------------------------

          final inputImage = InputImage.fromFilePath(imagePath);

          final recognizer = TextRecognizer(
            script: TextRecognitionScript.latin,
          );

          try {
            final recognizedText = await recognizer.processImage(inputImage);

            debugPrint("========== OCR TEXT ==========");
            debugPrint(recognizedText.text);
            debugPrint("========== END OCR TEXT ==========");

            if (recognizedText.text.trim().isEmpty) {
              throw Exception("No readable text found in timetable PDF.");
            }

            // ----------------------------------------------------
            // RAW TEXT
            // ----------------------------------------------------

            final pageText = recognizedText.text.trim();

            if (pageText.isNotEmpty) {
              allText.add(pageText);
            }

            // ----------------------------------------------------
            // OCR LINES + POSITION
            // ----------------------------------------------------

            for (final block in recognizedText.blocks) {
              for (final line in block.lines) {
                final lineText = line.text.trim();

                if (lineText.isEmpty) {
                  continue;
                }

                final box = line.boundingBox;

                allLines.add(
                  OcrLine(
                    text: lineText,
                    pageIndex: pageIndex,
                    left: box.left,
                    top: box.top,
                    right: box.right,
                    bottom: box.bottom,
                  ),
                );
              }
            }
          } finally {
            await recognizer.close();
          }

          // ------------------------------------------------------
          // DELETE TEMP IMAGE
          // ------------------------------------------------------

          try {
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          } catch (_) {
            // Ignore temporary file deletion errors.
          }
        } catch (_) {
          // If one PDF page fails, continue with remaining pages.
          continue;
        }
      }

      // ----------------------------------------------------------
      // SORT OCR LINES
      //
      // First page
      //   ↓
      // top to bottom
      //   ↓
      // left to right
      // ----------------------------------------------------------

      allLines.sort((a, b) {
        final pageCompare = a.pageIndex.compareTo(b.pageIndex);

        if (pageCompare != 0) {
          return pageCompare;
        }

        final topDifference = a.top - b.top;

        if (topDifference.abs() > 12) {
          return topDifference < 0 ? -1 : 1;
        }

        return a.left.compareTo(b.left);
      });

      return PdfOcrResult(text: allText.join('\n'), lines: allLines);
    } finally {
      await renderer.close();
    }
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  //
  // Existing code which calls:
  //
  // PdfTextService.extractText(path)
  //
  // will continue working.
  // ============================================================

  static Future<String> extractText(String path) async {
    final result = await extractOcr(path);

    return result.text;
  }
}
