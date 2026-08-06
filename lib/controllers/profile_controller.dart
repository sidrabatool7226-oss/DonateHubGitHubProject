import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var isSaving = false.obs;
  var adminData = <String, dynamic>{}.obs;

  // Feedback observables
  var feedbackList = <Map<String, dynamic>>[].obs;
  var feedbackLoading = false.obs;
  var selectedFeedbackFilter = 'All'.obs;
  var searchQuery = ''.obs;

  // Edit form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final List<String> feedbackFilters = [
    'All',
    'Donor',
    'Volunteer',
    'Reviewed',
    'Pending',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAdminProfile();
    loadFeedback();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // ── Load Admin Profile ───────────────────────────────────────────────
  Future<void> loadAdminProfile() async {
    isLoading.value = true;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        adminData.value = doc.data() as Map<String, dynamic>;
        nameController.text = adminData['name'] ?? '';
        phoneController.text = adminData['phone'] ?? '';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load profile.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update Profile ───────────────────────────────────────────────────
  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Field',
        'Name cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSaving.value = true;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _db.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(
        nameController.text.trim(),
      );

      // Refresh local data
      adminData['name'] = nameController.text.trim();
      adminData['phone'] = phoneController.text.trim();
      adminData.refresh();

      Get.back();
      Get.snackbar(
        'Updated',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update profile.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── Change Password ──────────────────────────────────────────────────
  Future<void> changePassword() async {
    if (newPasswordController.text.trim().isEmpty ||
        currentPasswordController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please fill all password fields.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      Get.snackbar(
        'Mismatch',
        'New password and confirm password do not match.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (newPasswordController.text.trim().length < 6) {
      Get.snackbar(
        'Weak Password',
        'Password must be at least 6 characters.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSaving.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return;

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      // Clear fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.back();
      Get.snackbar(
        'Success',
        'Password changed successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Current password is incorrect.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── Load Feedback ────────────────────────────────────────────────────
  Future<void> loadFeedback() async {
    feedbackLoading.value = true;
    try {
      final snap = await _db
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .get();

      feedbackList.value = snap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // Collection might not exist yet — that's ok
      feedbackList.value = [];
    } finally {
      feedbackLoading.value = false;
    }
  }

  // ── Filtered Feedback ────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredFeedback {
    List<Map<String, dynamic>> list = feedbackList;

    // Filter by type/status
    switch (selectedFeedbackFilter.value) {
      case 'Donor':
        list = list
            .where((f) => (f['userRole'] ?? '') == 'donor')
            .toList();
        break;
      case 'Volunteer':
        list = list
            .where((f) => (f['userRole'] ?? '') == 'volunteer')
            .toList();
        break;
      case 'Reviewed':
        list = list
            .where((f) => (f['isReviewed'] ?? false) == true)
            .toList();
        break;
      case 'Pending':
        list = list
            .where((f) => (f['isReviewed'] ?? false) == false)
            .toList();
        break;
    }

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      list = list
          .where((f) =>
      (f['message'] ?? '')
          .toLowerCase()
          .contains(searchQuery.value.toLowerCase()) ||
          (f['userName'] ?? '')
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    return list;
  }

  // ── Mark as Reviewed ─────────────────────────────────────────────────
  Future<void> markAsReviewed(String docId) async {
    try {
      await _db.collection('feedback').doc(docId).update({
        'isReviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index =
      feedbackList.indexWhere((f) => f['docId'] == docId);
      if (index != -1) {
        feedbackList[index]['isReviewed'] = true;
        feedbackList.refresh();
      }

      Get.snackbar(
        'Marked',
        'Feedback marked as reviewed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update feedback.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}