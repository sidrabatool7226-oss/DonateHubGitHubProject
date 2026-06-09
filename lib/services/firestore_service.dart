import 'package:cloud_firestore/cloud_firestore.dart';

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
  // SAVE DONATION (FIXED)
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
  }) async {
    try {
      await _db.collection('donations').add({
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'description': description,
        'campaignName': campaignName,
        'logisticsType': logisticsType,
        'address': address,
        'imageUrls': imageUrls,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

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