import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get notificationsStream => _db
      .collection('notifications')
      .where('toUserId', isEqualTo: uid)
      .snapshots();

  Future<void> markAsRead(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).update({'isRead': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = _db.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  // Icon + color per notification type — keeps the list visually scannable
  Map<String, dynamic> iconFor(String type) {
    switch (type) {
      case 'volunteer_approved':
        return {'icon': 'check_circle', 'color': 0xFF1B6B3A};
      case 'volunteer_rejected':
        return {'icon': 'cancel', 'color': 0xFFC0392B};
      case 'video_call_scheduled':
        return {'icon': 'videocam', 'color': 0xFF2563EB};
      case 'physical_scheduled':
        return {'icon': 'location_on', 'color': 0xFF7C3AED};
      case 'donation_approved':
        return {'icon': 'thumb_up', 'color': 0xFF2563EB};
      case 'donation_rejected':
        return {'icon': 'cancel', 'color': 0xFFC0392B};
      case 'donation_completed':
        return {'icon': 'volunteer_activism', 'color': 0xFF1B6B3A};
      case 'pickup_assigned':
        return {'icon': 'local_shipping', 'color': 0xFFDB7C26};
      case 'task_assigned':
        return {'icon': 'assignment', 'color': 0xFF0F6E4F};
      case 'task_accepted':
        return {'icon': 'check', 'color': 0xFF1B6B3A};
      case 'task_rejected':
        return {'icon': 'close', 'color': 0xFFC0392B};
      case 'task_delivered':
        return {'icon': 'inventory', 'color': 0xFF2563EB};
      case 'new_donation_submitted':
        return {'icon': 'payments', 'color': 0xFF6A1B9A};
      case 'new_volunteer_application':
        return {'icon': 'person_add', 'color': 0xFF0F6E4F};
      case 'availability_updated':
        return {'icon': 'calendar_month', 'color': 0xFF0F6E4F};
      case 'volunteer_status_change':
        return {'icon': 'wifi_tethering', 'color': 0xFF2563EB};
      default:
        return {'icon': 'notifications', 'color': 0xFF616161};
    }
  }
}