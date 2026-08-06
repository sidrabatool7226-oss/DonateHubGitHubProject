import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
class UserManagementController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;
  var selectedFilter = 'manager'.obs;

  // Create form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Edit form controllers
  final editNameController = TextEditingController();
  final editPhoneController = TextEditingController();

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    editNameController.dispose();
    editPhoneController.dispose();
    super.onClose();
  }

  // ── Clear Form ───────────────────────────────────────────────────────
  void clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    errorMessage.value = '';
  }

  // ── Real-time Users Stream ───────────────────────────────────────────
  Stream<QuerySnapshot> get usersStream => _db
      .collection('users')
      .where('role', isEqualTo: selectedFilter.value)
      .snapshots();

  // ── Create Manager Account ───────────────────────────────────────────
  Future<bool> createManagerAccount() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      errorMessage.value =
      'Please fill all required fields.';
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      errorMessage.value =
      'Password must be at least 6 characters.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Secondary Firebase instance — Admin session safe
      FirebaseApp secondaryApp =
      await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      FirebaseAuth secondaryAuth =
      FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential cred =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final String newUid = cred.user!.uid;
      final String adminUid =
          _auth.currentUser?.uid ?? '';

      // Firestore documents
      await _db.collection('users').doc(newUid).set({
        'uid': newUid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim().toLowerCase(),
        'phone': phoneController.text.trim(),
        'role': 'manager',
        'status': 'active',
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('managers').doc(newUid).set({
        'managerId': newUid,
        'createdBy': adminUid,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out secondary instance
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      clearForm();
      Get.snackbar(
        'Manager Created',
        'Account created successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      errorMessage.value =
      'Error: ${e.toString().replaceAll('firebase_auth/', '')}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update Manager ───────────────────────────────────────────────────
  Future<bool> updateManager(String docId) async {
    if (editNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSaving.value = true;
    try {
      await _db.collection('users').doc(docId).update({
        'name': editNameController.text.trim(),
        'phone': editPhoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Updated',
        'Manager profile updated.',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update manager.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── Toggle Manager Status ────────────────────────────────────────────
  Future<void> toggleManagerStatus(
      String docId, bool isActive) async {
    try {
      await _db.collection('users').doc(docId).update({
        'status': isActive ? 'inactive' : 'active',
      });

      await _db.collection('managers').doc(docId).update({
        'isActive': !isActive,
      });

      Get.snackbar(
        isActive ? 'Deactivated' : 'Activated',
        isActive
            ? 'Manager account deactivated.'
            : 'Manager account activated.',
        backgroundColor:
        isActive ? Colors.red[50] : Colors.green[50],
        colorText:
        isActive ? Colors.red[700] : Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not update status.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}