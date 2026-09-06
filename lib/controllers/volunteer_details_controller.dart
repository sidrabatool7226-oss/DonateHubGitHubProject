// ============================================================
// FILE: lib/controllers/volunteer_details_controller.dart
//
// CHANGE: approveVolunteer() now:
//   1. Reads the volunteer's CURRENT verificationStage before
//      updating, to determine online vs physical verification
//      (derived from existing data — Physical_Scheduled → physical,
//      anything else → online).
//   2. Sends the "Volunteer Verification Successful" email via
//      EmailJS exactly once, guarded by a new 'approvalEmailSent'
//      flag on the volunteer's user document.
// Everything else in this file is unchanged.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/email_service.dart';

class VolunteerDetailsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EmailService _emailService = EmailService();

  var isSaving = false.obs;

  // Video call form
  final videoDateController = TextEditingController();
  final videoTimeController = TextEditingController();
  final meetLinkController = TextEditingController();

  // Physical visit form
  final physicalDateController = TextEditingController();
  final physicalTimeController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  // Reject reason
  final rejectReasonController = TextEditingController();

  DateTime? selectedVideoDate;
  TimeOfDay? selectedVideoTime;
  DateTime? selectedPhysicalDate;
  TimeOfDay? selectedPhysicalTime;

  @override
  void onClose() {
    videoDateController.dispose();
    videoTimeController.dispose();
    meetLinkController.dispose();
    physicalDateController.dispose();
    physicalTimeController.dispose();
    locationController.dispose();
    notesController.dispose();
    rejectReasonController.dispose();
    super.onClose();
  }

  // ── Pick Video Call Date ──────────────────────────────────────────────
  Future<void> pickVideoDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F6E4F),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      selectedVideoDate = picked;
      videoDateController.text =
      '${picked.month}/${picked.day}/${picked.year}';
    }
  }

  Future<void> pickVideoTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F6E4F),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      selectedVideoTime = picked;
      videoTimeController.text = picked.format(context);
    }
  }

  // ── Pick Physical Visit Date/Time ────────────────────────────────────
  Future<void> pickPhysicalDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F6E4F),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      selectedPhysicalDate = picked;
      physicalDateController.text =
      '${picked.month}/${picked.day}/${picked.year}';
    }
  }

  Future<void> pickPhysicalTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 11, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0F6E4F),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      selectedPhysicalTime = picked;
      physicalTimeController.text = picked.format(context);
    }
  }

  // ── Schedule Video Call ───────────────────────────────────────────────
  Future<bool> scheduleVideoCall(String volunteerId) async {
    if (videoDateController.text.trim().isEmpty ||
        videoTimeController.text.trim().isEmpty ||
        meetLinkController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill date, time and meeting link',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isSaving.value = true;

    try {
      await _db.collection('users').doc(volunteerId).update({
        'verificationStage': 'Video_Scheduled',
        'videoCallDate': videoDateController.text.trim(),
        'videoCallTime': videoTimeController.text.trim(),
        'videoCallLink': meetLinkController.text.trim(),
        'videoScheduledAt': FieldValue.serverTimestamp(),
        'videoScheduledBy': _auth.currentUser?.uid ?? '',
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'Video Call Scheduled',
        'message':
        'Your verification call is scheduled for ${videoDateController.text} at ${videoTimeController.text}. Join using the link in your app.',
        'type': 'video_call_scheduled',
        'entityId': volunteerId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Scheduled',
        'Video call scheduled and volunteer notified!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to schedule. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Schedule Physical Visit ───────────────────────────────────────────
  Future<bool> schedulePhysicalVisit(String volunteerId) async {
    if (physicalDateController.text.trim().isEmpty ||
        physicalTimeController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill date, time and location',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isSaving.value = true;

    try {
      await _db.collection('users').doc(volunteerId).update({
        'verificationStage': 'Physical_Scheduled',
        'physicalDate': physicalDateController.text.trim(),
        'physicalTime': physicalTimeController.text.trim(),
        'physicalLocation': locationController.text.trim(),
        'physicalNotes': notesController.text.trim(),
        'physicalScheduledAt': FieldValue.serverTimestamp(),
        'physicalScheduledBy': _auth.currentUser?.uid ?? '',
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'Physical Verification Scheduled',
        'message':
        'Please visit ${locationController.text} on ${physicalDateController.text} at ${physicalTimeController.text} for final verification.',
        'type': 'physical_scheduled',
        'entityId': volunteerId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Scheduled',
        'Physical visit scheduled and volunteer notified!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to schedule. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Approve Volunteer ─────────────────────────────────────────────────
  // CHANGED: now reads prior verificationStage to know online vs physical,
  // and sends the verification email exactly once (idempotent).
  Future<bool> approveVolunteer(String volunteerId) async {
    isSaving.value = true;

    try {
      // NEW — read current state BEFORE updating
      final docSnap =
      await _db.collection('users').doc(volunteerId).get();

      final data = docSnap.data() ?? {};

      final String priorStage =
          data['verificationStage'] ?? 'Pending';

      final String volunteerEmail =
          data['email'] ?? '';

      final String volunteerName =
          data['name'] ?? 'Volunteer';

      final bool alreadyEmailed =
          data['approvalEmailSent'] == true;

      final bool isPhysical =
          priorStage == 'Physical_Scheduled';

      await _db.collection('users').doc(volunteerId).update({
        'verificationStage': 'Verified',
        'status': 'active',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': _auth.currentUser?.uid ?? '',
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'Application Approved! 🎉',
        'message':
        'Congratulations! Your volunteer application has been approved. You can now access your dashboard and start receiving tasks.',
        'type': 'volunteer_approved',
        'entityId': volunteerId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // NEW — send email exactly once
      if (!alreadyEmailed && volunteerEmail.isNotEmpty) {
        final bool emailSent =
        await _emailService.sendVolunteerVerificationEmail(
          toEmail: volunteerEmail,
          toName: volunteerName,
          isPhysical: isPhysical,
        );

        if (emailSent) {
          await _db.collection('users').doc(volunteerId).update({
            'approvalEmailSent': true,
          });
        }
      }

      Get.snackbar(
        'Approved',
        'Volunteer approved successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Reject Volunteer (UNCHANGED — no email per requirements) ─────────
  Future<bool> rejectVolunteer(String volunteerId) async {
    if (rejectReasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Reason',
        'Please provide a rejection reason',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isSaving.value = true;

    try {
      await _db.collection('users').doc(volunteerId).update({
        'verificationStage': 'Rejected',
        'status': 'rejected',
        'rejectionReason': rejectReasonController.text.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid ?? '',
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'Application Update',
        'message':
        'We are unable to approve your application at this time. Reason: ${rejectReasonController.text.trim()}',
        'type': 'volunteer_rejected',
        'entityId': volunteerId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      rejectReasonController.clear();

      Get.snackbar(
        'Rejected',
        'Volunteer application rejected.',
        backgroundColor: Colors.orange[50],
        colorText: Colors.orange[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reject. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}