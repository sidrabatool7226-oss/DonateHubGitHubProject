import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class VolunteerRewardsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = true.obs;
  var rewardPoints = 0.obs;
  var completedTasksCount = 0.obs;
  var recentCompletedTasks = <Map<String, dynamic>>[].obs;

  String get uid => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _bindVolunteerData();
    _bindCompletedTasks();
  }

  void _bindVolunteerData() {
    _db.collection('users').doc(uid).snapshots().listen((doc) {
      final data = doc.data();
      rewardPoints.value = (data?['rewardPoints'] ?? 0) as int;
      completedTasksCount.value = (data?['completedTasksCount'] ?? 0) as int;
      isLoading.value = false;
    });
  }

  void _bindCompletedTasks() {
    _db
        .collection('tasks')
        .where('volunteerId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final aTs = a['completedAt'] as Timestamp?;
          final bTs = b['completedAt'] as Timestamp?;
          if (aTs == null || bTs == null) return 0;
          return bTs.compareTo(aTs);
        });
      recentCompletedTasks.value = list.take(10).toList();
    });
  }

  String get badgeName {
    final t = completedTasksCount.value;
    if (t >= 50) return 'Legend';
    if (t >= 30) return 'Community Hero';
    if (t >= 15) return 'Dedicated Helper';
    if (t >= 5) return 'Rising Star';
    return 'New Volunteer';
  }

  String get badgeIcon {
    final t = completedTasksCount.value;
    if (t >= 50) return '👑';
    if (t >= 30) return '🏅';
    if (t >= 15) return '🎖️';
    if (t >= 5) return '⭐';
    return '🌱';
  }

  Map<String, dynamic> get nextTierInfo {
    final t = completedTasksCount.value;
    if (t < 5) return {'target': 5, 'name': 'Rising Star'};
    if (t < 15) return {'target': 15, 'name': 'Dedicated Helper'};
    if (t < 30) return {'target': 30, 'name': 'Community Hero'};
    if (t < 50) return {'target': 50, 'name': 'Legend'};
    return {'target': null, 'name': null};
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}