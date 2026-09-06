import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class VolunteerTasksController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  var selectedTab = 0.obs;
  var isSaving = false.obs;
  File? proofImage;

  final List<String> tabLabels = const ['New', 'Accepted', 'Completed'];

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get myTasksStream =>
      _db.collection('tasks').where('volunteerId', isEqualTo: uid).snapshots();

  // ── Accept Task — guarded against double-accept ────────────────────────
  Future<bool> acceptTask(String taskId, String assignedBy) async {
    isSaving.value = true;
    try {
      final doc = await _db.collection('tasks').doc(taskId).get();
      final currentStatus = doc.data()?['status'];
      if (currentStatus != 'assigned') {
        _snack('Already Handled', 'This task has already been responded to.', isError: true);
        return false;
      }

      await _db.collection('tasks').doc(taskId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (assignedBy.isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': assignedBy,
          'title': 'Task Accepted',
          'message': 'Volunteer has accepted the assigned task.',
          'type': 'task_accepted',
          'entityId': taskId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _snack('Accepted', 'Task accepted!');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to accept task.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Reject Task — guarded against double-reject ─────────────────────────
  Future<bool> rejectTask(String taskId, String assignedBy, String reason) async {
    isSaving.value = true;
    try {
      final doc = await _db.collection('tasks').doc(taskId).get();
      final currentStatus = doc.data()?['status'];
      if (currentStatus != 'assigned') {
        _snack('Already Handled', 'This task has already been responded to.', isError: true);
        return false;
      }

      await _db.collection('tasks').doc(taskId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (assignedBy.isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': assignedBy,
          'title': 'Task Rejected',
          'message': 'Volunteer rejected the task. Reason: $reason. Please reassign.',
          'type': 'task_rejected',
          'entityId': taskId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _snack('Rejected', 'Task rejected. Manager has been notified.');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to reject task.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickProofImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (img != null) {
      proofImage = File(img.path);
      update();
    }
  }

  void clearProofImage() {
    proofImage = null;
    update();
  }

  Future<bool> uploadDeliveryProof(String taskId, String assignedBy) async {
    if (proofImage == null) {
      _snack('Missing Photo', 'Please take a photo of the completed task', isError: true);
      return false;
    }

    isSaving.value = true;
    try {
      final url = await _cloudinary.uploadImage(proofImage!);
      if (url == null) {
        _snack('Error', 'Image upload failed. Try again.', isError: true);
        isSaving.value = false;
        return false;
      }

      await _db.collection('tasks').doc(taskId).update({
        'status': 'delivered',
        'deliveryProofUrl': url,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (assignedBy.isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': assignedBy,
          'title': 'Task Proof Submitted',
          'message': 'Volunteer has submitted completion proof. Please review.',
          'type': 'task_delivered',
          'entityId': taskId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      proofImage = null;
      _snack('Submitted', 'Proof uploaded! Waiting for manager to confirm.');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to upload proof.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _snack(String title, String msg, {bool isError = false}) {
    Get.snackbar(title, msg,
        backgroundColor: isError ? Colors.red[50] : Colors.green[50],
        colorText: isError ? Colors.red[700] : Colors.green[700],
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }
}