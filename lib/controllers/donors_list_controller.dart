import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DonorsListController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var donors = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _bindDonors();
  }

  void _bindDonors() {
    _db.collection('users').where('role', isEqualTo: 'donor').snapshots().listen(
          (snap) async {
        final List<Map<String, dynamic>> list = [];
        for (final doc in snap.docs) {
          final userData = Map<String, dynamic>.from(doc.data());
          userData['uid'] = doc.id;

          // Merge reward points/totalDonations from the 'donors' collection
          final donorDoc = await _db.collection('donors').doc(doc.id).get();
          final donorData = donorDoc.data();
          userData['rewardPoints'] = donorData?['rewardPoints'] ?? 0;
          userData['totalDonations'] = donorData?['totalDonations'] ?? 0;

          list.add(userData);
        }
        list.sort((a, b) => (b['rewardPoints'] as int).compareTo(a['rewardPoints'] as int));
        donors.value = list;
        isLoading.value = false;
      },
      onError: (_) => isLoading.value = false,
    );
  }

  List<Map<String, dynamic>> get filtered {
    if (searchQuery.value.trim().isEmpty) return donors;
    final q = searchQuery.value.toLowerCase();
    return donors.where((d) {
      final name = (d['name'] ?? '').toString().toLowerCase();
      final email = (d['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  String badgeFor(int pts) {
    if (pts >= 500) return 'Platinum 💎';
    if (pts >= 200) return 'Gold 🥇';
    if (pts >= 100) return 'Silver 🥈';
    if (pts >= 50) return 'Bronze 🥉';
    return 'New Donor 🌱';
  }
}