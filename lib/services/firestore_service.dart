import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // GET CAMPAIGN NAMES
  // ==========================================
  Future<List<String>> getCampaignNames() async {
    try {
      final snapshot = await _db.collection('campaigns').get();

      return snapshot.docs
          .map((doc) => doc['name']?.toString())
          .where((name) => name != null && name.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      print('Error fetching campaigns: $e');
      return [];
    }
  }

  // ==========================================
  // SAVE DONATION (Resource Donation)
  // ==========================================
  Future<Map<String, dynamic>> saveDonation({
    required String itemName,
    required String category,
    required String quantity,
    required String description,
    required String campaignName,
    required String logisticsType,
    required String address,
    List<String>? imageUrls,
  }) async {
    try {
      final docRef = await _db.collection('donations').add({
        'itemName': itemName,
        'category': category,
        'quantity': quantity,
        'description': description,
        'campaignName': campaignName,
        'logisticsType': logisticsType,
        'address': address,
        'imageUrls': imageUrls ?? [],
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'id': docRef.id};
    } catch (e) {
      print('Error saving donation: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==========================================
  // GET ALL CAMPAIGNS (full data)
  // ==========================================
  Stream<QuerySnapshot> getCampaignsStream() {
    return _db.collection('campaigns').snapshots();
  }
}