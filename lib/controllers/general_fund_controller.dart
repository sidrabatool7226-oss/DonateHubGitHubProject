// ============================================================
// FILE: lib/controllers/general_fund_controller.dart (NEW)
//
// PURPOSE
// General Fund is an independent fundraising target (per
// requirements) — NOT attached to a Project, and not a card in
// the 'campaigns' collection since it has no goal/deadline/image,
// just a running received/allocated balance.
//
// FIRESTORE SHAPE
//   general_fund/summary            (single doc)
//     - totalReceived   (incremented by ManagerDonationsController
//                         .approveFundDonation() when a General Fund
//                         donation is approved — see that file)
//     - totalAllocated  (incremented here when a Manager allocates
//                         money to an operational need)
//
//   general_fund_allocations/{id}   (one doc per allocation — the
//                                    "keep allocation history" record)
//     - category, amount, note, allocatedBy, allocatedByName, allocatedAt
//
// A Manager can allocate up to whatever is currently unallocated
// (totalReceived - totalAllocated) — this file enforces that so the
// fund can never show a negative remaining balance.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeneralFundController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isSaving = false.obs;
  var selectedCategory = 'Food'.obs;

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final List<String> categories = const [
    'Food',
    'Utilities',
    'Medical',
    'Maintenance',
    'Emergency',
    'Other',
  ];

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Stream<DocumentSnapshot> get summaryStream =>
      _db.collection('general_fund').doc('summary').snapshots();

  Stream<QuerySnapshot> get allocationsStream => _db
      .collection('general_fund_allocations')
      .orderBy('allocatedAt', descending: true)
      .snapshots();

  double numberFrom(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<bool> allocateFunds({
    required double totalReceived,
    required double totalAllocated,
  }) async {
    final double? amount = double.tryParse(amountController.text.trim());

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

    final double remaining = totalReceived - totalAllocated;

    if (amount > remaining) {
      Get.snackbar(
        'Insufficient Balance',
        'Only Rs. ${remaining.toStringAsFixed(0)} is currently unallocated.',
        backgroundColor: Colors.orange[50],
        colorText: Colors.orange[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isSaving.value = true;
    try {
      final String uid = _auth.currentUser?.uid ?? '';
      String allocatedByName = 'Manager';
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        allocatedByName = (userDoc.data()?['name'] ?? 'Manager').toString();
      } catch (_) {
        // Best-effort only — allocation must not fail over a name lookup.
      }

      await _db.collection('general_fund_allocations').add({
        'category': selectedCategory.value,
        'amount': amount,
        'note': noteController.text.trim(),
        'allocatedBy': uid,
        'allocatedByName': allocatedByName,
        'allocatedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('general_fund').doc('summary').set({
        'totalAllocated': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      amountController.clear();
      noteController.clear();

      Get.snackbar(
        'Allocated',
        'Rs. ${amount.toStringAsFixed(0)} allocated to ${selectedCategory.value}.',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to allocate funds. Please try again.',
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

  String formatDate(dynamic ts) {
    if (ts is! Timestamp) return 'Date not available';
    final date = ts.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}