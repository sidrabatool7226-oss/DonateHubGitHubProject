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

  Future<bool> donateToCampaign({
    String? campaignId,
    String? campaignName,
    required String paymentProofUrl,
    String transactionId = '',
    double? ocrAmount,
    String? ocrTransactionId,
    String? ocrPaymentMethod,
    String? ocrPaymentDate,
    bool ocrProcessed = false,
    String donorPhone = '',
    String donorCnic = '',
  }) async {
    if (amountController.text.trim().isEmpty) {
      Get.snackbar('Missing Amount', 'Please enter donation amount',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    }

    double? amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    }

    if (transactionId.trim().isNotEmpty) {
      final isDupe = await isDuplicateTransaction(transactionId);
      if (isDupe) {
        Get.snackbar('Duplicate Transaction',
            'This transaction receipt has already been submitted.',
            backgroundColor: Colors.red[50], colorText: Colors.red[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return false;
      }
    }

    isLoading.value = true;

    try {
      final uid = _auth.currentUser?.uid ?? '';
      final email = _auth.currentUser?.email ?? '';

      final donationRef = await _db.collection('donations').add({
        'donorId': uid,
        'userEmail': email,
        'type': 'fund',
        'campaignId': campaignId,
        'campaignName': campaignName ?? 'General Fund',
        'amount': amount,
        'paymentMethod': selectedPaymentMethod.value,
        'paymentProofUrl': paymentProofUrl,
        'transactionId': transactionId.trim(),
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
      // NEW — notify all managers about the new fund donation
      final managersSnap = await _db.collection('users').where('role', isEqualTo: 'manager').get();
      for (var manager in managersSnap.docs) {
        await _db.collection('notifications').add({
          'toUserId': manager.id,
          'title': '💰 New Donation Received',
          'message': 'A new donation has been submitted and is waiting for review.',
          'type': 'new_donation_submitted',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // NOTE: campaign 'collectedAmount' is intentionally NOT updated
      // here anymore — it only updates after Manager/Admin approval
      // (see ManagerDonationsController.approveFundDonation, Phase 4).

      amountController.clear();

      final reviewersSnap = await _db
          .collection('users')
          .where('role', whereIn: ['manager', 'admin'])
          .get();
      for (var reviewer in reviewersSnap.docs) {
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
      }

      Get.snackbar('Donation Submitted',
          'Your donation has been submitted for verification',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit donation',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}