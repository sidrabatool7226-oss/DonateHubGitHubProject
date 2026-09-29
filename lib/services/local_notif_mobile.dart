import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifHelper {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'donatehub_android_studio_channel',
    'DonateHub Notifications',
    description: 'Important updates from DonateHub',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init({required void Function(String type, String entityId) onTap}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final parts = response.payload!.split('|');
          final type = parts.isNotEmpty ? parts[0] : '';
          final entityId = parts.length > 1 ? parts[1] : '';
          onTap(type, entityId);
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void show({required int id, required String? title, required String? body, required String payload}) {
    _plugin.show(
      id,
      title,
      body,
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
      payload: payload,
    );
  }
}