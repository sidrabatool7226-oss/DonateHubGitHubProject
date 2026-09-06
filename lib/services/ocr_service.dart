// ============================================================
// FILE: lib/services/ocr_service.dart
// CHANGE: Stub replaced with real Google ML Kit Text Recognition.
// This ONLY extracts text from an image. It does NOT verify a
// payment occurred — that is Manager/Admin's responsibility.
// ============================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  /// Downloads the image at [imageUrl] (e.g. a Cloudinary URL) and runs
  /// on-device text recognition. Used by Manager/Admin to re-scan an
  /// already-uploaded receipt.
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

  /// Runs text recognition directly on a local file. Used by the donor
  /// right after picking/cropping a screenshot, before it is uploaded.
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