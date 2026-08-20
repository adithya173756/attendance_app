import 'package:file_picker/file_picker.dart';

class PdfImportService {
  static Future<String?> pickPdf() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    return pickedFile?.path;
  }
}
