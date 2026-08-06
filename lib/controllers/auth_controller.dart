import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Observable variables — .obs lagao to UI automatically update hogi
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var currentUserRole = ''.obs;

  // ========================================================================
  // LOGIN
  // ========================================================================
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Firebase se login karo
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Firestore se role fetch karo
      await _routeByRole(credential.user!.uid);

    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Login failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ========================================================================
  // ROLE CHECK — sahi dashboard pe bhejo
  // ========================================================================
  Future<void> _routeByRole(String uid) async {
    DocumentSnapshot userDoc =
    await _db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      errorMessage.value = 'User data not found. Please sign up again.';
      return;
    }

    Map<String, dynamic> userData =
    userDoc.data() as Map<String, dynamic>;
    String role = userData['role'] ?? '';
    currentUserRole.value = role;

    if (role == 'admin') {
      Get.offAllNamed('/admin_dashboard');

    } else if (role == 'manager') {
      Get.offAllNamed('/manager_dashboard');

    } else if (role == 'donor') {
      Get.offAllNamed('/donor_dashboard');

    } else if (role == 'volunteer') {
      // Volunteer ka verification check karo
      String stage = userData['verificationStage'] ?? 'Pending';
      if (stage == 'Verified') {
        Get.offAllNamed('/volunteer_dashboard');
      } else {
        Get.offAllNamed('/verification_status');
      }
    } else {
      errorMessage.value = 'Unknown role. Please contact support.';
    }
  }

  // ========================================================================
  // LOGOUT
  // ========================================================================
  Future<void> logout() async {
    await _auth.signOut();
    currentUserRole.value = '';
    Get.offAllNamed('/login');
  }

  // ========================================================================
  // ERROR MESSAGES
  // ========================================================================
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}