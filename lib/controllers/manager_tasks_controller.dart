import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'inventory_controller.dart';
import '../services/email_service.dart';

class ManagerTasksController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailService _emailService = EmailService();

  var selectedTab = 0.obs;
  var isSaving = false.obs;

  final List<String> tabLabels = const ['Pending', 'Active', 'Delivered', 'Completed'];

  Stream<QuerySnapshot> get approvedDonationsStream => _db
      .collection('donations')
      .where('status', isEqualTo: 'approved')
      .snapshots();

  Stream<QuerySnapshot> get allTasksStream => _db.collection('tasks').snapshots();

  bool isTimedOut(Map<String, dynamic> task) {
    if (task['status'] != 'assigned') return false;
    final ts = task['assignedAt'];
    if (ts == null) return false;
    try {
      final assignedAt = (ts as Timestamp).toDate();
      return DateTime.now().difference(assignedAt).inMinutes >= 60;
    } catch (_) {
      return false;
    }
  }

  Duration? timeRemaining(Map<String, dynamic> task) {
    if (task['status'] != 'assigned') return null;
    final ts = task['assignedAt'];
    if (ts == null) return null;
    try {
      final assignedAt = (ts as Timestamp).toDate();
      final elapsed = DateTime.now().difference(assignedAt);
      final remaining = const Duration(hours: 1) - elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (_) {
      return null;
    }
  }

  // ── Assign volunteer to a donation (Resource Pickup) ────────────────────
  // FIXED: taskCategory is now ALWAYS the literal string 'Resource Pickup'
  // for donation-triggered tasks — previously this fell back to the item's
  // shopping category (Food/Clothes/etc), which never matched any
  // volunteer role and silently broke eligibility filtering.
  Future<bool> assignVolunteer({
    required String donationId,
    required Map<String, dynamic> donationData,
    required String volunteerId,
    required String volunteerName,
  }) async {
    isSaving.value = true;
    try {
      final taskRef = await _db.collection('tasks').add({
        'donationId': donationId,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'taskCategory': 'Resource Pickup', // FIXED — was donationData['category']
        'title': donationData['itemName'] ?? 'Resource Pickup',
        'itemName': donationData['itemName'] ?? '',
        'quantity': donationData['quantity'] ?? 1,
        'donorId': donationData['donorId'] ?? '',
        'donorName': donationData['donorName'] ??
            donationData['userEmail'] ??
            donationData['donorEmail'] ??
            'Donor',
        'pickupAddress': donationData['address'] ?? donationData['pickupAddress'] ?? '',
        'location': donationData['address'] ?? donationData['pickupAddress'] ?? '',
        'status': 'assigned',
        'assignedBy': _auth.currentUser?.uid ?? '',
        'assignedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('donations').doc(donationId).update({
        'status': 'pickup_assigned',
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'New Pickup Task Assigned',
        'message':
        'You have been assigned to collect "${donationData['itemName'] ?? 'items'}". Please respond within 1 hour.',
        'type': 'task_assigned',
        'entityId': taskRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if ((donationData['donorId'] ?? '').toString().isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': donationData['donorId'],
          'title': 'Pickup Scheduled',
          'message': 'A volunteer has been assigned to collect your donation.',
          'type': 'pickup_assigned',
          'entityId': donationId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar('Assigned', 'Task assigned to $volunteerName',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign task.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> reassignVolunteer({
    required String taskId,
    required String oldVolunteerId,
    required String newVolunteerId,
    required String newVolunteerName,
  }) async {
    isSaving.value = true;
    try {
      await _db.collection('tasks').doc(taskId).update({
        'volunteerId': newVolunteerId,
        'volunteerName': newVolunteerName,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'reassignedFrom': oldVolunteerId,
        'reassignCount': FieldValue.increment(1),
      });

      await _db.collection('notifications').add({
        'toUserId': newVolunteerId,
        'title': 'New Task Assigned',
        'message': 'You have been assigned a task. Please respond within 1 hour.',
        'type': 'task_assigned',
        'entityId': taskId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Reassigned', 'Task reassigned to $newVolunteerName',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to reassign.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> completeTask({
    required String taskId,
    required Map<String, dynamic> taskData,
  }) async {
    isSaving.value = true;
    try {
      final donationId = taskData['donationId'];
      final donorId = taskData['donorId'] ?? '';
      final itemName = taskData['itemName'] ?? taskData['title'] ?? 'items';
      final category = taskData['taskCategory'] ?? 'Other';
      final quantity = taskData['quantity'] is String
          ? int.tryParse(taskData['quantity']) ?? 1
          : (taskData['quantity'] as num?)?.toInt() ?? 1;
      Map<String, dynamic> donationData = {};
      if (donationId != null && donationId.toString().isNotEmpty) {
        final donationDocSnap = await _db.collection('donations').doc(donationId).get();
        donationData = donationDocSnap.data() ?? {};
      }
      final bool alreadyEmailed = donationData['completionEmailSent'] == true;

      WriteBatch batch = _db.batch();

      batch.update(_db.collection('tasks').doc(taskId), {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (donationId != null && donationId.toString().isNotEmpty) {
        batch.update(_db.collection('donations').doc(donationId), {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      if (donorId.toString().isNotEmpty) {
        batch.set(
          _db.collection('donors').doc(donorId),
          {
            'rewardPoints': FieldValue.increment(10),
            'totalDonations': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }

      final volunteerId = taskData['volunteerId'] ?? '';
      if (volunteerId.toString().isNotEmpty) {
        batch.set(
          _db.collection('users').doc(volunteerId),
          {
            'rewardPoints': FieldValue.increment(20),
            'completedTasksCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      // Inventory auto-add only applies to actual resource pickups
      if (category == 'Resource Pickup' && donationId != null && donationId.toString().isNotEmpty) {
        try {
          await InventoryController.autoAddFromVolunteer(
            db: _db,
            itemName: itemName,
            category: taskData['category'] ?? 'Other',
            quantity: quantity.toInt(),
            donationId: donationId,
            donorName: taskData['donorName'] ?? 'Donor',
          );
        } catch (_) {}
      }

      if (donorId.toString().isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': donorId,
          'title': '🧡 Thank You — Little Smiles Orphan Home',
          'message':
          'Your donation of "$itemName" has been successfully delivered and completed. You just made a real difference in a child\'s life!',
          'type': 'donation_completed',
          'entityId': donationId ?? '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!alreadyEmailed && donationId != null && donationId.toString().isNotEmpty) {
          final userDoc = await _db.collection('users').doc(donorId).get();
          final userData = userDoc.data() ?? {};
          final String donorEmail = userData['email'] ?? donationData['userEmail'] ?? '';
          final String donorName = userData['name'] ?? 'Donor';

          if (donorEmail.isNotEmpty) {
            final bool emailSent = await _emailService.sendDonationCompletedEmail(
              toEmail: donorEmail,
              toName: donorName,
              amount: '',
              isFund: false,
            );
            if (emailSent) {
              await _db.collection('donations').doc(donationId).update({'completionEmailSent': true});
            }
          }
        }
      }

      Get.snackbar('Completed', 'Task marked as completed!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete task.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}