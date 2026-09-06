// ============================================================
// FILE: lib/services/fcm_service.dart (NEW)
// Handles: token save/refresh/multi-device, foreground local
// notification display, tap navigation (foreground/background/terminated)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../screens/donor/donor_donations_tab.dart';
import '../screens/volunteer/screens/volunteer_task_detail_screen.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // NAYA — manifest ke sath match
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'donatehub_android_studio_channel',
    'DonateHub Notifications',
    description: 'Important updates from DonateHub',
    importance: Importance.high,
    playSound: true,
  );

  RemoteMessage? _pendingTapMessage;

  Future<void> initialize() async {
    // ── Local notifications setup (for foreground display) ─────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final parts = response.payload!.split('|');
          final type = parts.isNotEmpty ? parts[0] : '';
          final entityId = parts.length > 1 ? parts[1] : '';
          _handleTap(type, entityId);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

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
      // Delay to let splash/auth routing settle first
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

  // Call this from logout flows to remove this device's token
  static Future<void> removeCurrentDeviceToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (_) {
      // Non-fatal — logout should proceed regardless
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? '';
    final entityId = message.data['entityId'] ?? '';

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
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
        // Manager dashboard opens on Home tab — pending counts are
        // visible there. Deep-linking to a specific tab isn't
        // supported by the current ManagerDashboard implementation.
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