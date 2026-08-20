class OcrLine {
  final String text;

  // PDF page number
  final int pageIndex;

  // OCR bounding box
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrLine({
    required this.text,
    this.pageIndex = 0,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  // ============================================================
  // WIDTH
  // ============================================================

  double get width => right - left;

  // ============================================================
  // HEIGHT
  // ============================================================

  double get height => bottom - top;

  // ============================================================
  // CENTER X
  // ============================================================

  double get centerX => (left + right) / 2;

  // ============================================================
  // CENTER Y
  // ============================================================

  double get centerY => (top + bottom) / 2;

  // ============================================================
  // COPY WITH
  // ============================================================

  OcrLine copyWith({
    String? text,
    int? pageIndex,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return OcrLine(
      text: text ?? this.text,
      pageIndex: pageIndex ?? this.pageIndex,
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'OcrLine('
        'text: $text, '
        'pageIndex: $pageIndex, '
        'left: $left, '
        'top: $top, '
        'right: $right, '
        'bottom: $bottom'
        ')';
  }
}
