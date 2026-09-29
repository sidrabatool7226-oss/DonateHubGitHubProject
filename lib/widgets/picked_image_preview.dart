// ============================================================
// FILE: lib/widgets/picked_image_preview.dart (NEW)
// Renders a PickedImage correctly on both mobile (File) and web (bytes).
// ============================================================

import 'package:flutter/material.dart';
import '../services/picked_image.dart';

/// Use wherever you currently do Image.file(someFile, fit: ...)
Widget buildPickedImagePreview(PickedImage picked, {BoxFit fit = BoxFit.cover}) {
  if (picked.bytes != null) {
    return Image.memory(picked.bytes!, fit: fit);
  }
  return Image.file(picked.file!, fit: fit);
}

/// Use wherever you currently do FileImage(someFile) inside a DecorationImage
ImageProvider pickedImageProvider(PickedImage picked) {
  if (picked.bytes != null) {
    return MemoryImage(picked.bytes!);
  }
  return FileImage(picked.file!);
}