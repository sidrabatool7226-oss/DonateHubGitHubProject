import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class RewardsOverviewController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var selectedTab = 0.obs; // 0 Donors, 1 Volunteers

  Stream<QuerySnapshot> get donorsStream => _db
      .collection('donors')
      .orderBy('rewardPoints', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get volunteersStream => _db
      .collection('users')
      .where('role', isEqualTo: 'volunteer')
      .where('verificationStage', isEqualTo: 'Verified')
      .snapshots();

  String donorBadge(int points) {
    if (points >= 500) return 'Platinum';
    if (points >= 200) return 'Gold';
    if (points >= 100) return 'Silver';
    if (points >= 50) return 'Bronze';
    return 'New Donor';
  }

  String donorBadgeIcon(int points) {
    if (points >= 500) return '💎';
    if (points >= 200) return '🥇';
    if (points >= 100) return '🥈';
    if (points >= 50) return '🥉';
    return '🌱';
  }

  String volunteerBadge(int tasks) {
    if (tasks >= 50) return 'Legend';
    if (tasks >= 30) return 'Community Hero';
    if (tasks >= 15) return 'Dedicated Helper';
    if (tasks >= 5) return 'Rising Star';
    return 'New Volunteer';
  }

  String volunteerBadgeIcon(int tasks) {
    if (tasks >= 50) return '👑';
    if (tasks >= 30) return '🏅';
    if (tasks >= 15) return '🎖️';
    if (tasks >= 5) return '⭐';
    return '🌱';
  }

  Future<int> getVolunteerTaskCount(String volunteerId) async {
    final snap = await _db
        .collection('tasks')
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snap.docs.length;
  }
}