import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

class CampaignController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedImage = Rxn<File>();

  // Form controllers
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final goalController = TextEditingController();
  final endDateController = TextEditingController();

  // Needs checkboxes
  var selectedNeeds = <String>[].obs;

  final List<String> allNeeds = [
    'Food',
    'Clothes',
    'Books',
    'Furniture',
    'Medicine',
    'Stationery',
    'Shoes',
    'Blankets',
  ];

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    goalController.dispose();
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

  // ── Toggle Need ──────────────────────────────────────────────────────
  void toggleNeed(String need) {
    if (selectedNeeds.contains(need)) {
      selectedNeeds.remove(need);
    } else {
      selectedNeeds.add(need);
    }
  }

  // ── Clear Form ───────────────────────────────────────────────────────
  void clearForm() {
    titleController.clear();
    descController.clear();
    goalController.clear();
    endDateController.clear();
    selectedImage.value = null;
    selectedNeeds.clear();
  }

  // ── Add Campaign ─────────────────────────────────────────────────────
  Future<bool> addCampaign() async {
    if (titleController.text.trim().isEmpty ||
        descController.text.trim().isEmpty ||
        goalController.text.trim().isEmpty) {
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
      // Upload image
      String imageUrl = '';
      if (selectedImage.value != null) {
        String? url = await _cloudinary.uploadImage(selectedImage.value!);
        if (url != null) imageUrl = url;
      }

      // Save to Firestore
      await _db.collection('campaigns').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'goalAmount': double.tryParse(goalController.text.trim()) ?? 0,
        'collectedAmount': 0,
        'image': imageUrl,
        'endDate': endDateController.text.trim(),
        'needs': selectedNeeds.toList(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      clearForm();
      Get.snackbar(
        'Success',
        'Campaign added successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add campaign. Try again.',
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

  // ── Delete Campaign ──────────────────────────────────────────────────
  Future<void> deleteCampaign(String docId) async {
    try {
      await _db.collection('campaigns').doc(docId).delete();
      Get.snackbar(
        'Deleted',
        'Campaign removed.',
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
        .collection('campaigns')
        .doc(docId)
        .update({'isActive': !current});
  }

  // ── Real-time Stream ─────────────────────────────────────────────────
  Stream<QuerySnapshot> get campaignsStream => _db
      .collection('campaigns')
      .orderBy('createdAt', descending: true)
      .snapshots();
}