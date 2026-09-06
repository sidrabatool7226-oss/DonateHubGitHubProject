// ============================================================
// FILE: lib/services/firestore_service.dart
//
// CHANGE: saveDonation() now internally captures the currently
// logged-in donor's UID and email and stores them as 'donorId'
// and 'userEmail' on the donation document. This is the SAME
// field naming already used by fund donations
// (donor_campaign_controller.dart), for consistency.
//
// IMPORTANT: The method SIGNATURE is unchanged — no new required
// parameters — so donate_form_screen.dart needs ZERO modification.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===============================
  // GET CAMPAIGN NAMES
  // ===============================
  Future<List<String>> getCampaignNames() async {
    try {
      final snapshot = await _db.collection('campaigns').get();

      return snapshot.docs
          .map((doc) => doc['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching campaigns: $e');
      return [];
    }
  }

  // ===============================
  // SAVE DONATION (FIXED — donorId/email now captured)
  // ===============================
  Future<Map<String, dynamic>> saveDonation({
    required String itemName,
    required String category,
    required String quantity,
    required String description,
    required String campaignName,
    required String logisticsType,
    required String address,
    required List<String> imageUrls,
    String donorPhone = '',
    String donorCnic = '',
    String receiptImageUrl = '',
  }) async {
    try {
      // NEW — capture currently logged-in donor's identity
      final currentUser = FirebaseAuth.instance.currentUser;

      await _db.collection('donations').add({
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'description': description,
        'campaignName': campaignName,
        'logisticsType': logisticsType,
        'address': address,
        'imageUrls': imageUrls,
        'donorPhone': donorPhone,
        'donorCnic': donorCnic,
        'receiptImageUrl': receiptImageUrl,
        'donorId': currentUser?.uid ?? '',       // NEW
        'userEmail': currentUser?.email ?? '',   // NEW — matches fund donation field naming
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // NEW — notify all managers about the new donation
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
      return {
        'success': true,
        'message': 'Donation saved successfully'
      };
    } catch (e) {
      print('Error saving donation: $e');

      return {
        'success': false,
        'message': 'Failed to save donation'
      };
    }
  }
}