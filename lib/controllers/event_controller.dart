import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class EventController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedImage = Rxn<File>();

  // Form controllers
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  // Selected dates
  DateTime? startDate;
  DateTime? endDate;

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.onClose();
  }

  // ── Pick Image ───────────────────────────────────────────────────────
  Future<void> pickImage() async {
    final XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  // ── Clear Form ───────────────────────────────────────────────────────
  void clearForm() {
    titleController.clear();
    descController.clear();
    locationController.clear();
    startDateController.clear();
    endDateController.clear();
    selectedImage.value = null;
    startDate = null;
    endDate = null;
  }

  // ── Pick Start Date ──────────────────────────────────────────────────
  Future<void> pickStartDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B6B3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      startDate = picked;
      startDateController.text =
      '${picked.day}/${picked.month}/${picked.year}';
      // End date reset karo agar start date baad ki ho
      if (endDate != null && endDate!.isBefore(picked)) {
        endDate = null;
        endDateController.clear();
      }
    }
  }

  // ── Pick End Date ────────────────────────────────────────────────────
  Future<void> pickEndDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B6B3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      endDate = picked;
      endDateController.text =
      '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  // ── Add Event ────────────────────────────────────────────────────────
  Future<bool> addEvent() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        startDateController.text.trim().isEmpty ||
        endDateController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill all required fields',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }

    isLoading.value = true;

    try {
      // Image upload
      String imageUrl = '';
      if (selectedImage.value != null) {
        String? url = await _cloudinary.uploadImage(selectedImage.value!);
        if (url != null) imageUrl = url;
      }

      // Firestore mein save
      await _db.collection('events').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'location': locationController.text.trim(),
        'startDate': startDate != null
            ? Timestamp.fromDate(startDate!)
            : FieldValue.serverTimestamp(),
        'endDate': endDate != null
            ? Timestamp.fromDate(endDate!)
            : FieldValue.serverTimestamp(),
        'startDateStr': startDateController.text.trim(),
        'endDateStr': endDateController.text.trim(),
        'image': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearForm();
      Get.snackbar(
        'Success',
        'Event added successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add event. Try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete Event ─────────────────────────────────────────────────────
  Future<void> deleteEvent(String docId) async {
    try {
      await _db.collection('events').doc(docId).delete();
      Get.snackbar(
        'Deleted',
        'Event removed.',
        backgroundColor: Colors.orange[50],
        colorText: Colors.orange[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not delete. Try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Toggle Active ────────────────────────────────────────────────────
  Future<void> toggleActive(String docId, bool current) async {
    await _db
        .collection('events')
        .doc(docId)
        .update({'isActive': !current});
  }

  // ── Real-time Stream ─────────────────────────────────────────────────
  Stream<QuerySnapshot> get eventsStream => _db
      .collection('events')
      .orderBy('createdAt', descending: true)
      .snapshots();
}