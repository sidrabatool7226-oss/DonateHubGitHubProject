import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/notifications_controller.dart';
import '../../controllers/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  final Color accentColor;
  const NotificationsScreen({super.key, this.accentColor = const Color(0xFF1B6B3A)});

  static const Color _bg = Color(0xFFF4F6F8);

  static const Map<String, IconData> _icons = {
    'check_circle': Icons.check_circle_rounded,
    'cancel': Icons.cancel_rounded,
    'videocam': Icons.videocam_rounded,
    'location_on': Icons.location_on_rounded,
    'thumb_up': Icons.thumb_up_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'local_shipping': Icons.local_shipping_rounded,
    'assignment': Icons.assignment_rounded,
    'check': Icons.check_rounded,
    'close': Icons.close_rounded,
    'inventory': Icons.inventory_2_rounded,
    'payments': Icons.payments_rounded,
    'person_add': Icons.person_add_rounded,
    'calendar_month': Icons.calendar_month_rounded,
    'wifi_tethering': Icons.wifi_tethering_rounded,
    'notifications': Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: controller.notificationsStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () => controller.markAllAsRead(docs),
                child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
          }

          final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? [])
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _NotificationTile(
                docId: doc.id,
                data: data,
                controller: controller,
                accentColor: accentColor,
                iconMap: _icons,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final NotificationsController controller;
  final Color accentColor;
  final Map<String, IconData> iconMap;

  const _NotificationTile({
    required this.docId,
    required this.data,
    required this.controller,
    required this.accentColor,
    required this.iconMap,
  });

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? 'Notification';
    final String message = data['message'] ?? '';
    final String type = data['type'] ?? '';
    final bool isRead = data['isRead'] == true;
    final iconInfo = controller.iconFor(type);
    final IconData icon = iconMap[iconInfo['icon']] ?? Icons.notifications_rounded;
    final Color color = Color(iconInfo['color']);

    return GestureDetector(
      onTap: () {
        if (!isRead) controller.markAsRead(docId);
        _handleTap(context, type, data);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: isRead ? null : Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(fontSize: 13.5, fontWeight: isRead ? FontWeight.w500 : FontWeight.bold)),
                      ),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                  const SizedBox(height: 6),
                  Text(controller.timeAgo(data['createdAt']), style: TextStyle(fontSize: 10.5, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mirrors fcm_service.dart's routing logic so tapping in-app matches
  // tapping a push notification — same destinations, same behavior.
  Future<void> _handleTap(BuildContext context, String type, Map<String, dynamic> data) async {
    final String entityId = data['entityId'] ?? '';

    try {
      switch (type) {
        case 'volunteer_approved':
          Get.offAllNamed('/volunteer_dashboard');
          break;

        case 'volunteer_rejected':
        case 'video_call_scheduled':
        case 'physical_scheduled':
          Get.offAllNamed('/verification_status');
          break;

        case 'donation_approved':
        case 'donation_rejected':
        case 'donation_completed':
        case 'pickup_assigned':
          if (entityId.isNotEmpty) {
            final doc = await FirebaseFirestore.instance.collection('donations').doc(entityId).get();
            if (doc.exists) {
              Get.toNamed('/donation_detail', arguments: {'docId': doc.id, 'data': doc.data()});
              return;
            }
          }
          break;

        case 'new_donation_submitted':
        case 'new_volunteer_application':
          Get.offAllNamed('/manager_dashboard');
          break;

        default:
          break;
      }
    } catch (_) {}
  }
}