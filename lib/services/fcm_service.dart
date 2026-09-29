// ============================================================
// FILE: lib/services/fcm_service.dart
// CHANGE: Android-specific local-notification code moved to
// local_notif_mobile.dart / local_notif_stub.dart (see
// local_notif_service.dart switch). Everything else UNCHANGED.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'local_notif_service.dart';
import '../screens/donor/donor_donations_tab.dart';
import '../screens/volunteer/screens/volunteer_task_detail_screen.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalNotifHelper _localNotif = LocalNotifHelper();

  RemoteMessage? _pendingTapMessage;

  Future<void> initialize() async {
    await _localNotif.init(onTap: _handleTap);

    // ── React to login/logout — save/remove FCM token ──────────────────
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveTokenForUser(user.uid);
      }
    });

    _fcm.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        });
      }
    });

    // ── Foreground messages ─────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // ── Background tap (app was backgrounded, user tapped tray) ────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleTap(message.data['type'] ?? '', message.data['entityId'] ?? '');
    });

    // ── Terminated tap (app was fully closed, opened via notification) ─
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _pendingTapMessage = initialMessage;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_pendingTapMessage != null) {
          _handleTap(
            _pendingTapMessage!.data['type'] ?? '',
            _pendingTapMessage!.data['entityId'] ?? '',
          );
          _pendingTapMessage = null;
        }
      });
    }
  }

  Future<void> _saveTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('FCM token save error: $e');
    }
  }

  static Future<void> removeCurrentDeviceToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? '';
    final entityId = message.data['entityId'] ?? '';

    _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: '$type|$entityId',
    );
  }

  // ── Route mapping based on existing app screens/routes only ────────────
  Future<void> _handleTap(String type, String entityId) async {
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
            final doc = await FirebaseFirestore.instance
                .collection('donations')
                .doc(entityId)
                .get();
            if (doc.exists) {
              Get.to(() => DonationDetailScreen(
                docId: doc.id,
                data: doc.data() as Map<String, dynamic>,
              ));
              return;
            }
          }
          Get.offAllNamed('/donor_dashboard');
          break;

        case 'task_assigned':
          if (entityId.isNotEmpty) {
            final doc = await FirebaseFirestore.instance
                .collection('tasks')
                .doc(entityId)
                .get();
            if (doc.exists) {
              Get.to(() => VolunteerTaskDetailScreen(
                taskId: doc.id,
                data: doc.data() as Map<String, dynamic>,
              ));
              return;
            }
          }
          Get.offAllNamed('/volunteer_dashboard');
          break;

        case 'new_donation_submitted':
        case 'new_volunteer_application':
          Get.offAllNamed('/manager_dashboard');
          break;

        default:
          break;
      }
    } catch (e) {
      print('Notification tap routing error: $e');
    }
  }
}