import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ManagerCampaignsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var activeCampaigns = 0.obs;

  final RxList<QueryDocumentSnapshot<Map<String, dynamic>>> campaigns =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _bindCampaigns();
  }

  void _bindCampaigns() {
    isLoading.value = true;

    _db
        .collection('campaigns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        campaigns.assignAll(snapshot.docs);

        activeCampaigns.value = snapshot.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length;

        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> donationsStreamForCampaign({
    required String campaignId,
    required String campaignName,
  }) {
    return _db
        .collection('donations')
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getCampaignDonations({
    required String campaignId,
    required String campaignName,
  }) async {
    try {
      final snapshot = await _db.collection('donations').get();

      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());

        final storedCampaignId =
        (data['campaignId'] ?? '').toString().trim();

        final storedCampaignName =
        (data['campaignName'] ?? '').toString().trim();

        final matchesId = campaignId.isNotEmpty &&
            storedCampaignId.isNotEmpty &&
            storedCampaignId == campaignId;

        final matchesName = campaignName.isNotEmpty &&
            storedCampaignName.isNotEmpty &&
            storedCampaignName == campaignName;

        if (matchesId || matchesName) {
          data['id'] = doc.id;
          result.add(data);
        }
      }

      result.sort((a, b) {
        final aTime = _timestampValue(a['createdAt'] ?? a['timestamp']);
        final bTime = _timestampValue(b['createdAt'] ?? b['timestamp']);

        return bTime.compareTo(aTime);
      });

      return result;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchDonorProfile(
      String? donorId,
      ) async {
    if (donorId == null || donorId.trim().isEmpty) {
      return null;
    }

    try {
      final doc = await _db.collection('users').doc(donorId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data();
    } catch (_) {
      return null;
    }
  }

  double getAmount(Map<String, dynamic> data) {
    final value =
        data['verifiedAmount'] ?? data['amount'] ?? data['claimedAmount'] ?? 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  DateTime _timestampValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String formatDate(dynamic value) {
    final date = _timestampValue(value);

    if (date.millisecondsSinceEpoch == 0) {
      return 'Date not available';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }
}