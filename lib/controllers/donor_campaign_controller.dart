// ============================================================
// FILE: lib/controllers/donor_campaign_controller.dart
//
// CHANGE FROM PHASE 2: campaign 'collectedAmount' increment
// REMOVED from submission — moved to Manager/Admin approval
// (ManagerDonationsController.approveFundDonation(), Phase 4).
// This ensures pending/unverified money never appears in
// campaign totals. Everything else unchanged from Phase 2.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonorCampaignController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = false.obs;
  var selectedTab = 0.obs;
  var donationAmount = ''.obs;
  var selectedPaymentMethod = 'jazzcash'.obs;

  final amountController = TextEditingController();

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  Stream<QuerySnapshot> get campaignsStream => _db
      .collection('campaigns')
      .where('isActive', isEqualTo: true)
      .snapshots();

  Stream<QuerySnapshot> get eventsStream => _db
      .collection('events')
      .where('isActive', isEqualTo: true)
      .snapshots();

  // ── Duplicate transaction check — reused by Manager review too ────────
  // Blocks re-use of the same transaction ID across pending/approved/
  // completed donations. Rejected donations' IDs are exempt (may have
  // been rejected due to an honest mistake, not fraud).
  Future<bool> isDuplicateTransaction(String transactionId,
      {String? excludeDonationId}) async {
    if (transactionId.trim().isEmpty) return false;

    final snap = await _db
        .collection('donations')
        .where('transactionId', isEqualTo: transactionId.trim())
        .get();

    return snap.docs.any((doc) {
      if (excludeDonationId != null && doc.id == excludeDonationId) {
        return false;
      }

      final status = (doc.data())['status'];
      return status != 'rejected';
    });
  }

  // NEW — Duplicate SCREENSHOT check. isDuplicateTransaction() above only
  // compares the transaction ID text extracted by OCR — someone could
  // lightly edit an old real screenshot (changing the visible number just
  // enough that OCR reads something different) and slip past that check
  // with the same underlying image. This compares the actual uploaded
  // FILE instead, via a SHA-256 hash of its bytes, so re-submitting the
  // exact same image is caught even if its extracted text differs.
  // Same exemption as above — a rejected donation's image hash is not
  // held against a later, legitimate resubmission.
  Future<bool> isDuplicateImageHash(String imageHash,
      {String? excludeDonationId}) async {
    if (imageHash.trim().isEmpty) return false;

    final snap = await _db
        .collection('donations')
        .where('imageHash', isEqualTo: imageHash.trim())
        .get();

    return snap.docs.any((doc) {
      if (excludeDonationId != null && doc.id == excludeDonationId) {
        return false;
      }

      final status = (doc.data())['status'];
      return status != 'rejected';
    });
  }

  Future<bool> donateToCampaign({
    String? campaignId,
    String? campaignName,

    // NEW — 'campaign' | 'project' | 'general_fund'. Campaign/Project
    // keep working exactly as before via campaignId/campaignName
    // (which CampaignController's auto-sync listener matches on);
    // this is additive, generic tagging so Admin/Manager "Funds" views
    // can always answer "where did this donation go?" per the common
    // donation-target architecture.
    String donationTargetType = 'campaign',

    String? generalFundPurpose,

    required String paymentProofUrl,
    String transactionId = '',
    String imageHash = '',
    double? ocrAmount,
    String? ocrTransactionId,
    String? ocrPaymentMethod,
    String? ocrPaymentDate,
    bool ocrProcessed = false,
    String donorPhone = '',
    String donorCnic = '',
  }) async {
    if (amountController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Amount',
        'Please enter donation amount',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    double? amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    if (transactionId.trim().isNotEmpty) {
      bool isDupe = false;

      try {
        isDupe = await isDuplicateTransaction(transactionId);
      } catch (_) {
        // Duplicate check is best-effort.
        // Do not block a valid submission if Firestore read permission
        // or network is temporarily unavailable.
      }

      if (isDupe) {
        Get.snackbar(
          'Duplicate Transaction',
          'This transaction receipt has already been submitted.',
          backgroundColor: Colors.red[50],
          colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return false;
      }
    }

    // NEW — catches re-use of the exact same screenshot file even if its
    // extracted transaction ID text happens to differ.
    if (imageHash.trim().isNotEmpty) {
      bool isDupeImage = false;

      try {
        isDupeImage = await isDuplicateImageHash(imageHash);
      } catch (_) {
        // Duplicate image check is best-effort for the same reason.
      }

      if (isDupeImage) {
        Get.snackbar(
          'Duplicate Screenshot',
          'This exact payment screenshot has already been submitted before.',
          backgroundColor: Colors.red[50],
          colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return false;
      }
    }

    isLoading.value = true;

    try {
      final uid = _auth.currentUser?.uid ?? '';
      final email = _auth.currentUser?.email ?? '';

      // NEW — General Fund has a fixed, well-known name/id.
      final String targetName =
      donationTargetType == 'general_fund'
          ? 'General Support Fund'
          : (campaignName ?? 'General Support Fund');

      final String? targetId =
      donationTargetType == 'general_fund'
          ? 'GENERAL'
          : campaignId;

      final donationRef = await _db.collection('donations').add({
        'donorId': uid,
        'userEmail': email,
        'type': 'fund',
        'campaignId': campaignId,
        'campaignName': targetName,

        // NEW — generic donation-target fields.
        'donationTargetType': donationTargetType,
        'donationTargetId': targetId,
        'donationTargetName': targetName,

        if (donationTargetType == 'general_fund' &&
            generalFundPurpose != null)
          'generalFundPurpose': generalFundPurpose,

        'amount': amount,
        'paymentMethod': selectedPaymentMethod.value,
        'paymentProofUrl': paymentProofUrl,
        'transactionId': transactionId.trim(),
        'imageHash': imageHash.trim(),
        'donorPhone': donorPhone,
        'donorCnic': donorCnic,
        'ocrAmount': ocrAmount,
        'ocrTransactionId': ocrTransactionId,
        'ocrPaymentMethod': ocrPaymentMethod,
        'ocrPaymentDate': ocrPaymentDate,
        'ocrProcessed': ocrProcessed,
        'status': 'pending',
        'fundsAdded': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // NEW — notify all managers about the new fund donation.
      // Notifications are best-effort and must never make a successful
      // donation submission fail.
      try {
        final managersSnap = await _db
            .collection('users')
            .where('role', isEqualTo: 'manager')
            .get();

        for (var manager in managersSnap.docs) {
          try {
            await _db.collection('notifications').add({
              'toUserId': manager.id,
              'title': '💰 New Donation Received',
              'message':
              'A new donation has been submitted and is waiting for review.',
              'type': 'new_donation_submitted',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Notification failure must not fail the donation.
          }
        }
      } catch (_) {
        // Notification query failure must not fail the donation.
      }

      // NOTE: campaign 'collectedAmount' is intentionally NOT updated
      // here anymore — it only updates after Manager/Admin approval
      // (see ManagerDonationsController.approveFundDonation, Phase 4).

      amountController.clear();

      try {
        final reviewersSnap = await _db
            .collection('users')
            .where(
          'role',
          whereIn: ['manager', 'admin'],
        )
            .get();

        for (var reviewer in reviewersSnap.docs) {
          try {
            await _db.collection('notifications').add({
              'toUserId': reviewer.id,
              'title': '💰 New Fund Donation',
              'message':
              'A new fund donation of Rs. ${amount.toStringAsFixed(0)} has been submitted for verification.',
              'type': 'new_donation_submitted',
              'entityId': donationRef.id,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Notification failure must not fail the donation.
          }
        }
      } catch (_) {
        // Notification query failure must not fail the donation.
      }

      Get.snackbar(
        'Donation Submitted',
        'Your donation has been submitted for verification',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit donation',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }
}