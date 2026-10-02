import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ManagerVolunteersController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var selectedTab = 0.obs; // 0 Pending, 1 Scheduled, 2 Approved, 3 Rejected
  var searchQuery = ''.obs;

  final List<String> tabLabels = const [
    'Pending',
    'Scheduled',
    'Approved',
    'Rejected',
  ];

  List<String> get _stagesForTab {
    switch (selectedTab.value) {
      case 0:
        return ['Pending', 'Form_Reviewed'];
      case 1:
        return ['Video_Scheduled', 'Physical_Scheduled'];
      case 2:
        return ['Verified'];
      case 3:
        return ['Rejected'];
      default:
        return ['Pending'];
    }
  }

  Stream<QuerySnapshot> get volunteersStream => _db
      .collection('users')
      .where('role', isEqualTo: 'volunteer')
      .where('verificationStage', whereIn: _stagesForTab)
      .orderBy('createdAt', descending: true)
      .snapshots();

  List<QueryDocumentSnapshot> filterBySearch(
      List<QueryDocumentSnapshot> docs) {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return docs;
    // CHANGED — every word typed must match name, email, phone or category
    final terms = q.split(RegExp(r'\s+'));
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final text = [
        (data['name'] ?? '').toString(),
        (data['email'] ?? '').toString(),
        (data['mobileNumber'] ?? data['phone'] ?? '').toString(),
        ((data['categories'] as List?) ?? const []).join(' '),
      ].join(' ').toLowerCase();
      return terms.every((t) => text.contains(t));
    }).toList();
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}