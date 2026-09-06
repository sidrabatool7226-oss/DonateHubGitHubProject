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

  // ── Create task and assign to ONE selected volunteer ──────────────────
  Future<bool> createAndAssignTask({
    required String volunteerId,
    required String volunteerName,
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
    try {
      final taskRef = await _db.collection('tasks').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'taskCategory': selectedCategory.value,
        'location': locationController.text.trim(),
        'instructions': instructionsController.text.trim(),
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
        '${selectedCategory.value}: "${titleController.text.trim()}" has been assigned to you.',
        'type': 'task_assigned',
        'entityId': taskRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearForm();
      _snack('Task Assigned', 'Task assigned to $volunteerName');
      return true;
    } catch (e) {
      _snack('Error', 'Failed to create task.', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _snack(String title, String msg, {bool isError = false}) {
    Get.snackbar(title, msg,
        backgroundColor: isError ? Colors.red[50] : Colors.green[50],
        colorText: isError ? Colors.red[700] : Colors.green[700],
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
  }
}