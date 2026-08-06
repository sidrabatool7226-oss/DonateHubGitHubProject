import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonorCampaignController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = false.obs;
  var selectedTab = 0.obs; // 0 = Campaigns, 1 = Events
  var donationAmount = ''.obs;
  var selectedPaymentMethod = 'Easypaisa'.obs;

  final amountController = TextEditingController();

  final List<String> paymentMethods = [
    'Easypaisa',
    'JazzCash',
    'Bank Transfer',
    'Other',
  ];

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  // ── Campaigns Stream ─────────────────────────────────────────────────
  Stream<QuerySnapshot> get campaignsStream => _db
      .collection('campaigns')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── Events Stream ────────────────────────────────────────────────────
  Stream<QuerySnapshot> get eventsStream => _db
      .collection('events')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── Donate to Campaign ───────────────────────────────────────────────
  Future<bool> donateToCampaign({
    required String campaignId,
    required String campaignName,
    required String paymentProofUrl,
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

    double? amount =
    double.tryParse(amountController.text.trim());
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

    isLoading.value = true;
    try {
      final uid = _auth.currentUser?.uid ?? '';
      final email =
          _auth.currentUser?.email ?? '';

      // Save donation
      await _db.collection('donations').add({
        'donorId': uid,
        'userEmail': email,
        'type': 'fund',
        'campaignId': campaignId,
        'campaignName': campaignName,
        'amount': amount,
        'paymentMethod':
        selectedPaymentMethod.value,
        'paymentProofUrl': paymentProofUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update campaign collected amount
      await _db
          .collection('campaigns')
          .doc(campaignId)
          .update({
        'collectedAmount':
        FieldValue.increment(amount),
      });

      amountController.clear();
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