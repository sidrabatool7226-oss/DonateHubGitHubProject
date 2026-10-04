import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ManagerHomeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var managerName = ''.obs;
  var isLoading = true.obs;

  var pendingVolunteers = 0.obs;
  var pendingDonations = 0.obs;
  var activeTasks = 0.obs;
  var completedTasks = 0.obs;
  var activeCampaigns = 0.obs;
  var recentActivity = <Map<String, dynamic>>[].obs;

  static const List<String> _pendingStages = [
    'Pending',
    'Form_Reviewed',
    'Video_Scheduled',
    'Video_Completed',
    'Physical_Scheduled',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadManagerName();
    _bindCounts();
    _loadRecentActivity();
  }

  Future<void> _loadManagerName() async {
    final uid = _auth.currentUser?.uid ?? '';
    final doc = await _db.collection('users').doc(uid).get();
    managerName.value = (doc.data()?['name'] ?? 'Manager').toString();
  }

  void _bindCounts() {

    _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .snapshots()
        .listen((snap) {
      pendingVolunteers.value = snap.docs.where((doc) {
        final data = doc.data();
        final stage = (data['verificationStage'] ?? 'Pending').toString();
        final status = (data['status'] ?? 'pending').toString().toLowerCase();
        return _pendingStages.contains(stage) ||
            (status == 'pending' && stage != 'Rejected');
      }).length;
    });

    // Pending donations (fund + resource)
    _db
        .collection('donations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) => pendingDonations.value = snap.docs.length);

    // Active tasks
    _db
        .collection('tasks')
        .where('status', whereIn: ['assigned', 'accepted'])
        .snapshots()
        .listen((snap) => activeTasks.value = snap.docs.length);

    _db
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) => completedTasks.value = snap.docs.length);

    // Active campaigns
    _db
        .collection('campaigns')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snap) {
        activeCampaigns.value = snap.docs.length;
      },
    );
  }

  void _loadRecentActivity() {
    isLoading.value = true;

    _db
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      final items = snap.docs.map((doc) {
        final d = Map<String, dynamic>.from(doc.data());
        d['id'] = doc.id;
        return d;
      }).toList();

      recentActivity.value = items;
      isLoading.value = false;
    });
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}