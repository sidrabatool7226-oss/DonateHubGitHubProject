// ============================================================
// FILE: lib/services/cloudinary_service.dart
//
// WHAT IT DOES:
//   Uploads an image file to Cloudinary and returns the URL.
//   Uses http package (no extra Cloudinary SDK needed).
// ============================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // ── Your Cloudinary credentials ─────────────────────────────────────────
  // Cloud Name: found on your Cloudinary dashboard
  static const String _cloudName = 'dhx53e3id';

  // Upload Preset: created in Cloudinary → Settings → Upload → Upload presets
  // Make sure this preset is set to "Unsigned"
  static const String _uploadPreset = 'cloudinary_donatehub_preset';

  // ── Cloudinary upload URL ────────────────────────────────────────────────
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ==========================================================================
  // UPLOAD IMAGE
  //
  // Takes a File (from ImagePicker) and returns the hosted image URL.
  // Returns null if upload fails.
  // ==========================================================================
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Step 1: Build a multipart HTTP request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Step 2: Add required Cloudinary fields
      request.fields['upload_preset'] = _uploadPreset;

      // Step 3: Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Step 4: Send the request
      final response = await request.send();

      // Step 5: Read the response body
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Step 6: Parse JSON and extract the secure URL
        final data = json.decode(responseBody);
        final String imageUrl = data['secure_url'];
        return imageUrl;
      } else {
        // Upload failed — print error for debugging
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary error: $e');
      return null;
    }
  }
}