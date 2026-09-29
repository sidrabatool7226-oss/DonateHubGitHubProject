// ============================================================
// FILE: lib/services/cloudinary_service.dart
//
// WHAT IT DOES:
//   Uploads an image to Cloudinary and returns the URL.
//   uploadImage(File)      → UNCHANGED, used by existing mobile code
//   uploadImageBytes(...)  → NEW, cross-platform (web + mobile safe)
// ============================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class CloudinaryService {
  static const String _cloudName = 'dhx53e3id';
  static const String _uploadPreset = 'cloudinary_donatehub_preset';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ==========================================================================
  // UPLOAD IMAGE (UNCHANGED — still used by any existing mobile-only call site)
  // ==========================================================================
  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final String imageUrl = data['secure_url'];
        return imageUrl;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary error: $e');
      return null;
    }
  }

  // ==========================================================================
  // NEW — UPLOAD IMAGE FROM BYTES
  // Works on Web AND mobile. Used by the new cross-platform picker helper
  // (upload_helper.dart) so Admin/Manager web forms can upload images too.
  // ==========================================================================
  Future<String?> uploadImageBytes(Uint8List bytes, {String fileName = 'upload.jpg'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final String imageUrl = data['secure_url'];
        return imageUrl;
      } else {
        print('Cloudinary upload (bytes) failed: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary error (bytes): $e');
      return null;
    }
  }
}