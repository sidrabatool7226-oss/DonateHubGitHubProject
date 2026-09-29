import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractTextFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      final text = await extractTextFromFile(file);

      try {
        await file.delete();
      } catch (_) {}

      return text;
    } catch (e) {
      print('OCR (URL) error: $e');
      return null;
    }
  }

  Future<String?> extractTextFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      print('OCR (file) error: $e');
      return null;
    }
  }

  void dispose() {
    _recognizer.close();
  }
}