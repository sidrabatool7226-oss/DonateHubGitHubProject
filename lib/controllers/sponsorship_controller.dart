// ============================================================
// FILE: lib/controllers/sponsorship_controller.dart (NEW)
//
// PURPOSE
// Owns the Sponsor-a-Child data workflow, kept separate from
// DonorCampaignController per the original requirement:
// "Sponsorship should have its own sponsorship information and
// workflow" — distinct from one-time Campaign/Project donations.
//
// TWO COLLECTIONS ARE WRITTEN ON SUBMIT:
//   1. 'sponsorships' (NEW) — the ongoing monthly commitment
//      record: who, which child, which categories, how much.
//   2. 'donations' (EXISTING, reused) — this specific payment,
//      tagged with donationTargetType/Id/Name so Admin/Manager
//      "Funds" views can tell where the money went, exactly like
//      Campaign/Project donations already work. This is what
//      keeps sponsorship payments inside the SAME approval queue
//      Manager already uses (status: 'pending' -> reviewed).
//
// Deliberately does NOT set 'campaignId'/'campaignName' on the
// donation doc — those fields are what CampaignController's
// auto-sync listener matches on to update a Campaign/Project's
// collectedAmount. Sponsorship's "coverage" is a different
// concept (current active monthly commitments, not a lifetime
// sum — see the comment in campaign_controller.dart), computed
// here via activeSponsorshipsForChild() instead.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SponsorshipController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isSubmitting = false.obs;

  /// All children currently open for sponsorship.
  Stream<QuerySnapshot> get childrenStream => _db
      .collection('campaigns')
      .where('category', isEqualTo: 'sponsorship')
      .where('isActive', isEqualTo: true)
      .snapshots();

  /// Manager-approved sponsorships for one child — used to grey out
  /// already-covered categories on the picker and to compute current
  /// monthly coverage. Only 'active' (approved) commitments count;
  /// a 'pending' submission does not block another donor from also
  /// picking the same category (Manager can catch true duplicates
  /// during review, the same way duplicate transaction IDs are
  /// already caught for Campaign donations).
  Stream<QuerySnapshot> activeSponsorshipsForChild(String childId) =>
      _db
          .collection('sponsorships')
          .where('childId', isEqualTo: childId)
          .where('status', isEqualTo: 'active')
          .snapshots();

  /// Categories already covered by an active sponsor, unioned across
  /// every active sponsorship for this child. A 'full' sponsorship is
  /// treated as covering every category name.
  static Set<String> coveredCategories(
      List<QueryDocumentSnapshot> activeSponsorships,
      List<String> allCategoryNames,
      ) {
    final covered = <String>{};

    for (final doc in activeSponsorships) {
      final data = doc.data() as Map<String, dynamic>;

      if ((data['sponsorshipType'] ?? '') == 'full') {
        covered.addAll(allCategoryNames);
        continue;
      }

      final cats = data['selectedCategories'];

      if (cats is List) {
        covered.addAll(cats.map((e) => e.toString()));
      }
    }

    return covered;
  }

  /// Current total monthly amount actively being sponsored for a child
  /// (sum of active sponsorships' monthlyAmount) — this is the "collected"
  /// figure to show against the Rs. 30,000 goal, NOT a lifetime donation
  /// total (see file header).
  static int currentMonthlyCoverage(
      List<QueryDocumentSnapshot> activeSponsorships) {
    int total = 0;

    for (final doc in activeSponsorships) {
      final data = doc.data() as Map<String, dynamic>;
      final amt = data['monthlyAmount'];

      if (amt is num) {
        total += amt.toInt();
      }
    }

    return total;
  }

  Future<bool> isDuplicateTransaction(String transactionId) async {
    if (transactionId.trim().isEmpty) return false;

    final snap = await _db
        .collection('donations')
        .where(
      'transactionId',
      isEqualTo: transactionId.trim(),
    )
        .get();

    return snap.docs.any((doc) {
      final status = (doc.data())['status'];
      return status != 'rejected';
    });
  }

  // NEW — same reasoning as donor_campaign_controller.dart's version:
  // catches re-submission of the exact same screenshot file even if a
  // slightly-edited copy makes OCR extract a different transaction ID.
  Future<bool> isDuplicateImageHash(String imageHash) async {
    if (imageHash.trim().isEmpty) return false;

    final snap = await _db
        .collection('donations')
        .where(
      'imageHash',
      isEqualTo: imageHash.trim(),
    )
        .get();

    return snap.docs.any((doc) {
      final status = (doc.data())['status'];
      return status != 'rejected';
    });
  }

  Future<bool> submitSponsorship({
    required String childId,
    required String childName,
    required String sponsorshipType,
    required List<String> selectedCategories,
    required Map<String, int> categoryAmounts,
    required int monthlyAmount,
    required String paymentMethod,
    required String paymentProofUrl,
    String transactionId = '',
    String imageHash = '',
    double? ocrAmount,
    String? ocrTransactionId,
    String? ocrPaymentMethod,
    String? ocrPaymentDate,
    bool ocrProcessed = false,
    required String donorPhone,
    required String donorCnic,
  }) async {
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

    // NEW — catches re-use of the exact same screenshot file.
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

    isSubmitting.value = true;

    try {
      final uid = _auth.currentUser?.uid ?? '';
      final email = _auth.currentUser?.email ?? '';

      String donorName = email;

      try {
        final userDoc = await _db
            .collection('users')
            .doc(uid)
            .get();

        donorName =
            (userDoc.data()?['name'] ?? email).toString();
      } catch (_) {
        // Best-effort only — submission must not fail over a name lookup.
      }

      // 1) The ongoing monthly commitment record.
      final sponsorshipRef =
      await _db.collection('sponsorships').add({
        'donorId': uid,
        'donorName': donorName,
        'donorEmail': email,
        'childId': childId,
        'childName': childName,
        'sponsorshipType': sponsorshipType,
        'selectedCategories': selectedCategories,
        'categoryAmounts': categoryAmounts,
        'monthlyAmount': monthlyAmount,

        // Becomes 'active' once Manager approves this first payment
        // (see ManagerDonationsController in Phase 3).
        'status': 'pending',
        'startDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2) This specific payment — same 'donations' collection ("Funds")
      // Campaign/Project donations already use, so it goes through the
      // exact same Manager approval queue.
      final donationRef =
      await _db.collection('donations').add({
        'donorId': uid,
        'userEmail': email,
        'type': 'fund',
        'donationTargetType': 'sponsorship',
        'donationTargetId': childId,
        'donationTargetName': childName,
        'sponsorshipId': sponsorshipRef.id,
        'sponsorshipType': sponsorshipType,
        'selectedCategories': selectedCategories,
        'amount': monthlyAmount,
        'paymentMethod': paymentMethod,
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

      // Notify Managers/Admins.
      // Notifications are best-effort and must never make a successful
      // sponsorship payment submission fail.
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
              'title': '💚 New Sponsorship Payment',
              'message':
              '$donorName submitted a Rs. $monthlyAmount sponsorship payment for $childName.',
              'type': 'new_donation_submitted',
              'entityId': donationRef.id,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Notification failure must not fail the sponsorship.
          }
        }
      } catch (_) {
        // Notification query failure must not fail the sponsorship.
      }

      Get.snackbar(
        'Submitted',
        'Your sponsorship has been submitted for verification.',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit sponsorship. Please try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}