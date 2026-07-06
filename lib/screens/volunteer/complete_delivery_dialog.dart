import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Call this from anywhere (e.g. a "Complete Delivery" button on a task
/// card in My Tasks screen) like:
///
/// showDialog(
///   context: context,
///   builder: (_) => CompleteDeliveryDialog(taskId: task.id),
/// );
class CompleteDeliveryDialog extends StatefulWidget {
  final String taskId;

  const CompleteDeliveryDialog({super.key, required this.taskId});

  @override
  State<CompleteDeliveryDialog> createState() =>
      _CompleteDeliveryDialogState();
}

class _CompleteDeliveryDialogState extends State<CompleteDeliveryDialog> {
  static const Color primaryGreen = Color(0xFF1FA15C);

  File? _proofImage;
  bool _isSubmitting = false;

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  Future<String?> _uploadProofImage(File file) async {
    try {
      // Same Cloudinary setup used in volunteer_details_form.dart —
      // replace with your real cloud_name / upload_preset.
      final cloudinary =
      CloudinaryPublic('your_cloud_name', 'your_upload_preset', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: 'delivery_proofs'),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _markAsDelivered() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final proofUrl = await _uploadProofImage(_proofImage!);

    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'status': 'completed',
        'proofImageUrl': proofUrl,
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true); // true = success, caller can refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery marked as completed ✅'),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Complete Delivery',
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Take a photo of the delivered items as proof of delivery',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Camera box / preview
            GestureDetector(
              onTap: _openCamera,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                  color: Colors.grey.shade50,
                ),
                child: _proofImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_proofImage!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 30, color: Colors.grey.shade500),
                    const SizedBox(height: 8),
                    Text('Open Camera',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Status: Picked',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            // Visual progress indicator: Picked -> Delivered
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _proofImage == null ? 0.0 : 0.5,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Picked', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Delivered', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _markAsDelivered,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Mark as Delivered'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}