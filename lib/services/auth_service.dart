// ============================================================
// FILE: lib/services/auth_service.dart
// WHAT IT DOES: Handles all Firebase Authentication + Firestore
//
// CHANGED: signUpUser() now accepts username, country, mobileNumber,
// and either cnic (Pakistan) or passportNumber (other countries).
// Only the relevant identity field is saved — never both, never fake.
// Everything else in this file is unchanged.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'fcm_service.dart'; // NEW
class AuthService {
  // ── Firebase instances ──────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Admin credentials (hardcoded — only admin can login, not signup) ─
  static const String adminEmail = 'donatehubadmin@gmail.com';
  static const String adminPassword = 'hastiapnihababkisihy221025';

  // ── Get currently logged-in user ──────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Listen to login/logout changes in real time ───────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========================================================================
  // SIGN UP — for donor and Volunteer only
  // ========================================================================
  Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String username, // NEW
    required String email,
    required String password,
    required String role, // 'donor' or 'volunteer'
    required String country, // NEW
    required String mobileNumber, // NEW — includes dial code, e.g. +923001234567
    String? cnic, // NEW — only for Pakistan
    String? passportNumber, // NEW — only for non-Pakistan
  }) async {
    try {
      // Step 1: Create account in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User user = result.user!;

      // Step 2: Update display name
      await user.updateDisplayName(name.trim());

      // Step 3: Decide status and isProfileComplete based on role
      String status = (role == 'volunteer') ? 'pending' : 'active';
      bool isProfileComplete = (role == 'volunteer') ? false : true;

      // Step 4: Build Firestore data — only save the relevant identity field
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'name': name.trim(),
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'status': status,
        'isProfileComplete': isProfileComplete,
        'country': country,
        'mobileNumber': mobileNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (country == 'Pakistan') {
        if (cnic != null && cnic.trim().isNotEmpty) {
          userData['cnic'] = cnic.trim();
        }
      } else {
        if (passportNumber != null && passportNumber.trim().isNotEmpty) {
          userData['passportNumber'] = passportNumber.trim();
        }
      }

      // Step 5: Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set(userData);

      return {
        'success': true,
        'message': 'Account created successfully!',
        'role': role,
        'isProfileComplete': isProfileComplete,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }

  // ========================================================================
  // LOGIN — for donor, Volunteer, and Admin (UNCHANGED)
  // ========================================================================
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User user = result.user!;

      if (email.trim().toLowerCase() == adminEmail.toLowerCase()) {
        DocumentSnapshot adminDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (!adminDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': 'Admin',
            'email': adminEmail,
            'role': 'admin',
            'status': 'active',
            'isProfileComplete': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return {
          'success': true,
          'role': 'admin',
          'isProfileComplete': true,
        };
      }

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found. Please sign up again.',
        };
      }

      Map<String, dynamic> userData =
      userDoc.data() as Map<String, dynamic>;

      return {
        'success': true,
        'role': userData['role'],
        'isProfileComplete': userData['isProfileComplete'],
        'status': userData['status'],
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
      };
    }
  }

  // ========================================================================
  // GOOGLE SIGN-IN (UNCHANGED)
  // ========================================================================
  Future<Map<String, dynamic>> signInWithGoogle({
    String role = 'donor',
  }) async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in was cancelled.',
        };
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result =
      await _auth.signInWithCredential(credential);
      User user = result.user!;

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData =
        userDoc.data() as Map<String, dynamic>;
        return {
          'success': true,
          'role': userData['role'],
          'isProfileComplete': userData['isProfileComplete'],
          'status': userData['status'],
        };
      } else {
        String status = (role == 'volunteer') ? 'pending' : 'active';
        bool isProfileComplete = (role == 'volunteer') ? false : true;

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': (user.email ?? '').toLowerCase(),
          'role': role,
          'status': status,
          'isProfileComplete': isProfileComplete,
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'role': role,
          'isProfileComplete': isProfileComplete,
          'status': status,
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign-in failed. Please try again.',
      };
    }
  }

  // ========================================================================
  // SIGN OUT
  // ========================================================================
  Future<void> signOut() async {
    // NEW — remove this device's FCM token before signing out
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await FcmService.removeCurrentDeviceToken(uid);
    }
    await _googleSignIn.signOut().catchError((_) {});
    await _auth.signOut();
  }
  // ========================================================================
  // FORGOT PASSWORD (UNCHANGED)
  // ========================================================================
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset link sent to your email.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    }
  }

  // ========================================================================
  // GET USER DATA from Firestore (UNCHANGED)
  // ========================================================================
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Private: Convert Firebase error codes → readable messages (UNCHANGED)
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}