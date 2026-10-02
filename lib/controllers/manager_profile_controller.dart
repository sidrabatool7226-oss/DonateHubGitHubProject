import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerProfileController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = true.obs;
  var isSaving = false.obs;
  var managerData = <String, dynamic>{}.obs;

  // CHANGED — now saved in Firestore (users/{uid}.pushNotifications) and
  // respected by the notification backend. The "Email Alerts" toggle was
  // removed: no emails are ever sent to managers, so it controlled nothing.
  var pushNotifications = true.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
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

  Future<void> loadProfile() async {
    isLoading.value = true;
    final uid = _auth.currentUser?.uid ?? '';
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      managerData.value = doc.data() as Map<String, dynamic>;
      nameController.text = managerData['name'] ?? '';
      // FIXED (Bug 6) — admin-created managers store 'mobileNumber', not 'phone',
      // so their own profile showed no phone. Read either; expose it as 'phone'
      // because that is the key the profile screen already reads.
      final String savedPhone =
      (managerData['mobileNumber'] ?? managerData['phone'] ?? '').toString();
      if (savedPhone.isNotEmpty) managerData['phone'] = savedPhone;
      phoneController.text = savedPhone;

      // NEW — push preference (missing field = enabled, the default)
      pushNotifications.value = managerData['pushNotifications'] != false;
    }
    isLoading.value = false;
  }

  // NEW — turn push notifications on/off for this account. The backend skips
  // sending push to users who have it switched off; the in-app Notifications
  // list keeps working either way.
  Future<void> setPushNotifications(bool value) async {
    final bool previous = pushNotifications.value;
    pushNotifications.value = value;
    try {
      final uid = _auth.currentUser?.uid ?? '';
      await _db.collection('users').doc(uid).update({'pushNotifications': value});
      managerData['pushNotifications'] = value;
    } catch (e) {
      pushNotifications.value = previous; // could not save — put the switch back
      Get.snackbar('Error', 'Could not update notification setting.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Name cannot be empty',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }

    // NEW — phone is optional, but if entered it must be exactly 11 digits
    final String phone = phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\d{11}$').hasMatch(phone)) {
      Get.snackbar('Invalid Phone', 'Phone number must be exactly 11 digits (e.g. 03001234567).',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }

    isSaving.value = true;
    try {
      final uid = _auth.currentUser?.uid ?? '';
      await _db.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'mobileNumber': phoneController.text.trim(), // FIXED (Bug 6) — keep both fields in sync
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _auth.currentUser?.updateDisplayName(nameController.text.trim());
      managerData['name'] = nameController.text.trim();
      managerData['phone'] = phoneController.text.trim();
      managerData.refresh();
      Get.back();
      Get.snackbar('Updated', 'Profile updated successfully!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } catch (e) {
      Get.snackbar('Error', 'Could not update profile.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changePassword() async {
    if (currentPasswordController.text.trim().isEmpty ||
        newPasswordController.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Please fill all password fields',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar('Mismatch', 'New passwords do not match',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    // CHANGED — minimum password length is now 8 (was 6), same as Admin
    if (newPasswordController.text.trim().length < 8) {
      Get.snackbar('Weak Password', 'Minimum 8 characters required',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    isSaving.value = true;
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPasswordController.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPasswordController.text.trim());

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      Get.back();
      Get.snackbar('Success', 'Password changed successfully!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } catch (e) {
      Get.snackbar('Error', 'Current password is incorrect.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}