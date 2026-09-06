import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VolunteerHomeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = true.obs;
  var volunteerName = ''.obs;
  var isOnline = false.obs;
  var isSavingSchedule = false.obs;

  var pendingTasks = 0.obs;
  var activeTasks = 0.obs;
  var completedTasks = 0.obs;

  // Weekly availability — day -> {isAvailable, startTime, endTime}
  var weeklySchedule = <String, Map<String, dynamic>>{}.obs;

  final List<String> daysOfWeek = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String get uid => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _initSchedule();
    _bindVolunteerData();
    _bindTaskCounts();
  }

  void _initSchedule() {
    for (var day in daysOfWeek) {
      weeklySchedule[day] = {
        'isAvailable': false,
        'startTime': '09:00 AM',
        'endTime': '05:00 PM',
      };
    }
  }

  void _bindVolunteerData() {
    _db.collection('users').doc(uid).snapshots().listen((doc) {
      final data = doc.data();
      if (data != null) {
        volunteerName.value = data['name'] ?? 'Volunteer';
        isOnline.value = data['isOnline'] ?? false;

        final savedSchedule = data['availabilitySchedule'] as List?;
        if (savedSchedule != null) {
          for (var entry in savedSchedule) {
            final day = entry['day'];
            if (day != null && daysOfWeek.contains(day)) {
              weeklySchedule[day] = {
                'isAvailable': entry['isAvailable'] ?? false,
                'startTime': entry['startTime'] ?? '09:00 AM',
                'endTime': entry['endTime'] ?? '05:00 PM',
              };
            }
          }
          weeklySchedule.refresh();
        }
      }
      isLoading.value = false;
    });
  }

  void _bindTaskCounts() {
    _db
        .collection('tasks')
        .where('volunteerId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      int pending = 0, active = 0, completed = 0;
      for (var doc in snap.docs) {
        final status = doc.data()['status'] ?? '';
        if (status == 'assigned') pending++;
        if (status == 'accepted') active++;
        if (status == 'completed') completed++;
      }
      pendingTasks.value = pending;
      activeTasks.value = active;
      completedTasks.value = completed;
    });
  }

  // ── Toggle Online/Offline ────────────────────────────────────────────
  Future<void> toggleOnlineStatus(bool value) async {
    isOnline.value = value;
    await _db.collection('users').doc(uid).update({
      'isOnline': value,
      'lastStatusChange': FieldValue.serverTimestamp(),
    });

    // Notify all managers
    final managersSnap =
    await _db.collection('users').where('role', isEqualTo: 'manager').get();
    for (var manager in managersSnap.docs) {
      await _db.collection('notifications').add({
        'toUserId': manager.id,
        'title': value ? 'Volunteer Online' : 'Volunteer Offline',
        'message':
        '${volunteerName.value} is now ${value ? 'available' : 'unavailable'} for tasks.',
        'type': 'volunteer_status_change',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Get.snackbar(
      value ? 'You are Online' : 'You are Offline',
      value
          ? 'You can now receive task assignments'
          : 'You will not receive new tasks',
      backgroundColor: value ? Colors.green[50] : Colors.grey[100],
      colorText: value ? Colors.green[700] : Colors.grey[700],
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  // ── Toggle Day Availability ───────────────────────────────────────────
  void toggleDayAvailability(String day) {
    final current = weeklySchedule[day]!;
    weeklySchedule[day] = {
      ...current,
      'isAvailable': !(current['isAvailable'] as bool),
    };
    weeklySchedule.refresh();
  }

  // ── Update Time for a Day ─────────────────────────────────────────────
  void updateDayTime(String day, String startTime, String endTime) {
    final current = weeklySchedule[day]!;
    weeklySchedule[day] = {
      ...current,
      'startTime': startTime,
      'endTime': endTime,
    };
    weeklySchedule.refresh();
  }

  // ── Save Schedule to Firestore ────────────────────────────────────────
  Future<void> saveSchedule() async {
    isSavingSchedule.value = true;
    try {
      final scheduleList = daysOfWeek.map((day) {
        final entry = weeklySchedule[day]!;
        return {
          'day': day,
          'isAvailable': entry['isAvailable'],
          'startTime': entry['startTime'],
          'endTime': entry['endTime'],
        };
      }).toList();

      await _db.collection('users').doc(uid).update({
        'availabilitySchedule': scheduleList,
        'scheduleUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Notify managers about updated schedule
      final availableDays = daysOfWeek
          .where((d) => weeklySchedule[d]!['isAvailable'] == true)
          .toList();

      final managersSnap =
      await _db.collection('users').where('role', isEqualTo: 'manager').get();
      for (var manager in managersSnap.docs) {
        await _db.collection('notifications').add({
          'toUserId': manager.id,
          'title': 'Availability Updated',
          'message':
          '${volunteerName.value} updated their availability${availableDays.isNotEmpty ? ': ${availableDays.join(', ')}' : '.'}',
          'type': 'availability_updated',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        'Saved',
        'Your availability schedule has been updated!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save schedule. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSavingSchedule.value = false;
    }
  }
}