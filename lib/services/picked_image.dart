// ============================================================
// FILE: lib/services/picked_image.dart (NEW)
//
// WHY: image_picker se milne wali XFile ko mobile par File(path)
// aur web par bytes ke through handle karna hota hai. Ye class
// dono cases ko ek jagah wrap karti hai taake har controller mein
// baar baar kIsWeb check na likhna pade.
//
// Existing controllers/screens ke liye koi breaking change nahi —
// ye sirf ek naya helper hai jo controllers apni marzi se use karenge.
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class PickedImage {
  final File? file;        // set on mobile only
  final Uint8List? bytes;  // set on web only
  final String fileName;

  PickedImage({this.file, this.bytes, required this.fileName});

  static Future<PickedImage?> fromXFile(XFile? xfile) async {
    if (xfile == null) return null;
    if (kIsWeb) {
      final bytes = await xfile.readAsBytes();
      return PickedImage(bytes: bytes, fileName: xfile.name);
    } else {
      return PickedImage(file: File(xfile.path), fileName: xfile.name);
    }
  }

  /// Uploads via the correct Cloudinary method for this platform.
  /// Mobile path calls the exact same uploadImage(File) as before —
  /// zero behavior change for the existing app.
  Future<String?> upload(CloudinaryService cloudinary) {
    if (kIsWeb) {
      return cloudinary.uploadImageBytes(bytes!, fileName: fileName);
    } else {
      return cloudinary.uploadImage(file!);
    }
  }
}