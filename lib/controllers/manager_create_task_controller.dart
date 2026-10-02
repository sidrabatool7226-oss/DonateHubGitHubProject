import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerCreateTaskController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isSaving = false.obs;
  var isLoadingVolunteers = false.obs;
  var selectedCategory = Rxn<String>();
  var matchingVolunteers = <Map<String, dynamic>>[].obs;

  // NEW — filters / helpers for the volunteer list
  var onlineOnly = false.obs; // show only volunteers who are online right now
  var selectedBloodGroup = Rxn<String>(); // Blood Donation tasks only; null = any group
  var selectedDateRx = Rxn<DateTime>(); // mirrors selectedDate so the list can react to it
  var activeTaskCounts = <String, int>{}.obs; // volunteerId -> assigned/accepted tasks
  var assigningVolunteerId = ''.obs; // NEW — which volunteer's button was pressed

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final instructionsController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  static const List<String> taskCategories = [
    'Volunteering & Management',
    'Emergency Response',
    'Blood Donation',
    'Relief Distribution',
    'Medical Camps',
    'Ration Drive',
    'Teaching',
    'Event Management',
  ];

  static const List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  // NEW — which donor groups can give to a recipient group (standard red-cell
  // compatibility). Used only to shortlist volunteers; the manager still decides.
  static const Map<String, List<String>> _donorsFor = {
    'O-': ['O-'],
    'O+': ['O+', 'O-'],
    'A-': ['A-', 'O-'],
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'AB-': ['AB-', 'A-', 'B-', 'O-'],
    'AB+': ['AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-'],
  };

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    instructionsController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    instructionsController.clear();
    dateController.clear();
    timeController.clear();
    selectedCategory.value = null;
    selectedDate = null;
    selectedTime = null;
    matchingVolunteers.clear();
    onlineOnly.value = false; // NEW
    selectedBloodGroup.value = null; // NEW
    selectedDateRx.value = null; // NEW
    activeTaskCounts.clear(); // NEW
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F6E4F))),
        child: child!,
      ),
    );
    if (picked != null) {
      selectedDate = picked;
      selectedDateRx.value = picked; // NEW
      dateController.text = '${picked.month}/${picked.day}/${picked.year}';
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F6E4F))),
        child: child!,
      ),
    );
    if (picked != null) {
      selectedTime = picked;
      timeController.text = picked.format(context);
    }
  }

  // ── Category select → find eligible verified volunteers ──────────────
  Future<void> onCategorySelected(String category) async {
    selectedCategory.value = category;
    if (category != 'Blood Donation') selectedBloodGroup.value = null; // NEW
    isLoadingVolunteers.value = true;
    matchingVolunteers.clear();

    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('verificationStage', isEqualTo: 'Verified')
          .where('categories', arrayContains: category)
          .get();

      matchingVolunteers.value = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] = doc.id;
        return data;
      }).toList();

      // NEW — how many open tasks (assigned / accepted) each volunteer already has
      try {
        final taskSnap = await _db
            .collection('tasks')
            .where('status', whereIn: ['assigned', 'accepted'])
            .get();
        final counts = <String, int>{};
        for (final t in taskSnap.docs) {
          final vid = (t.data()['volunteerId'] ?? '').toString();
          if (vid.isNotEmpty) counts[vid] = (counts[vid] ?? 0) + 1;
        }
        activeTaskCounts.value = counts;
      } catch (_) {
        activeTaskCounts.clear(); // best-effort only
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load matching volunteers.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isLoadingVolunteers.value = false;
    }
  }

  List<Map<String, dynamic>> availableDaysFor(Map<String, dynamic> volunteer) {
    final schedule = volunteer['availabilitySchedule'];
    if (schedule is! List) return [];
    return schedule
        .whereType<Map>()
        .where((e) => e['isAvailable'] == true)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // NEW — the list the screen actually shows. Call it inside an Obx: it reads
  // every Rx value it depends on (online toggle, blood group, task date,
  // task counts), so the list refreshes when any of them changes.
  //  • Blood Donation + a blood group chosen → only compatible donors, exact group first
  //  • sorted: exact blood match → online now → available on the task's weekday
  //    → fewer open tasks → name
  //  • each item carries ready-made fields used by the card:
  //    _availableOnDate, _scheduleText, _activeTasks, _showBlood
  List<Map<String, dynamic>> get visibleVolunteers {
    final bool onlyOnline = onlineOnly.value;
    final String? need = selectedBloodGroup.value;
    final DateTime? date = selectedDateRx.value;
    final Map<String, int> counts = Map<String, int>.from(activeTaskCounts);
    final bool isBlood = selectedCategory.value == 'Blood Donation';
    final List<String>? allowed = need == null ? null : (_donorsFor[need] ?? const <String>[]);

    final DateTime day = date ?? DateTime.now();
    final String dayName = _weekdays[day.weekday - 1];
    final String dayLabel = date == null ? 'Today' : dayName.substring(0, 3);

    final List<Map<String, dynamic>> out = [];
    for (final raw in matchingVolunteers) {
      final v = Map<String, dynamic>.from(raw);
      final String bg = (v['bloodGroup'] ?? '').toString().trim().toUpperCase();

      if (onlyOnline && v['isOnline'] != true) continue;
      if (allowed != null && !allowed.contains(bg)) continue;

      bool availableOnDate = false;
      String scheduleText = 'No schedule set';
      final schedule = v['availabilitySchedule'];
      if (schedule is List && schedule.isNotEmpty) {
        scheduleText = 'Not available on $dayLabel';
        for (final e in schedule) {
          if (e is Map && (e['day'] ?? '').toString().toLowerCase() == dayName.toLowerCase()) {
            if (e['isAvailable'] == true) {
              availableOnDate = true;
              final String st = (e['startTime'] ?? '').toString();
              final String en = (e['endTime'] ?? '').toString();
              scheduleText = st.isNotEmpty && en.isNotEmpty
                  ? '$dayLabel: $st – $en'
                  : 'Available $dayLabel';
            }
            break;
          }
        }
      }

      v['_availableOnDate'] = availableOnDate;
      v['_scheduleText'] = scheduleText;
      v['_activeTasks'] = counts[v['uid']] ?? 0;
      v['_showBlood'] = isBlood;
      v['_exactBlood'] = need != null && bg == need;
      out.add(v);
    }

    int rank(bool b) => b ? 0 : 1;
    out.sort((a, b) {
      int c = rank(a['_exactBlood'] == true).compareTo(rank(b['_exactBlood'] == true));
      if (c != 0) return c;
      c = rank(a['isOnline'] == true).compareTo(rank(b['isOnline'] == true));
      if (c != 0) return c;
      c = rank(a['_availableOnDate'] == true).compareTo(rank(b['_availableOnDate'] == true));
      if (c != 0) return c;
      c = (a['_activeTasks'] as int).compareTo(b['_activeTasks'] as int);
      if (c != 0) return c;
      return (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase());
    });
    return out;
  }

  // ── Create task and assign to ONE selected volunteer ──────────────────
  // showMessage: the screen passes false and shows the message itself AFTER it
  // has closed (Get.back() closes an open snackbar instead of the screen).
  Future<bool> createAndAssignTask({
    required String volunteerId,
    required String volunteerName,
    bool showMessage = true,
  }) async {
    if (titleController.text.trim().isEmpty) {
      _snack('Missing Title', 'Please enter a task title', isError: true);
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      _snack('Missing Description', 'Please enter a task description', isError: true);
      return false;
    }
    if (selectedCategory.value == null) {
      _snack('Missing Category', 'Please select a task category', isError: true);
      return false;
    }
    if (dateController.text.trim().isEmpty || timeController.text.trim().isEmpty) {
      _snack('Missing Date/Time', 'Please select date and time', isError: true);
      return false;
    }

    isSaving.value = true;
    assigningVolunteerId.value = volunteerId; // NEW
    try {
      final taskRef = await _db.collection('tasks').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'taskCategory': selectedCategory.value,
        'location': locationController.text.trim(),
        'instructions': instructionsController.text.trim(),
        // NEW — only for Blood Donation tasks where a blood group was chosen
        if (selectedCategory.value == 'Blood Donation' && selectedBloodGroup.value != null)
          'requiredBloodGroup': selectedBloodGroup.value,
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'status': 'assigned',
        'assignedBy': _auth.currentUser?.uid ?? '',
        'assignedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('notifications').add({
        'toUserId': volunteerId,
        'title': 'New Task Assigned',
        'message':
        '${selectedCategory.value}: "${titleController.text.trim()}" has been assigned to you.'
            '${selectedCategory.value == 'Blood Donation' && selectedBloodGroup.value != null ? ' Blood group needed: ${selectedBloodGroup.value}.' : ''}',
        'type': 'task_assigned',
        'entityId': taskRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearForm();
      if (showMessage) _snack('Task Assigned', 'Task assigned to $volunteerName');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to create task.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
      assigningVolunteerId.value = ''; // NEW
    }
  }

  void _snack(String title, String msg, {bool isError = false}) {
    Get.snackbar(title, msg,
        backgroundColor: isError ? Colors.red[50] : Colors.green[50],
        colorText: isError ? Colors.red[700] : Colors.green[700],
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }
}