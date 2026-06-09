// ============================================================
// FILE: lib/services/auth_service.dart
// WHAT IT DOES: Handles all Firebase Authentication + Firestore
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // ── Firebase instances ──────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Admin credentials (hardcoded — only admin can login, not signup) ────
  static const String adminEmail = 'admin@donatehub.com';
  static const String adminPassword = 'Admin@123';

  // ── Get currently logged-in user ────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Listen to login/logout changes in real time ─────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========================================================================
  // SIGN UP — for donor and Volunteer only
  // ========================================================================
  Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String email,
    required String password,
    required String role, // 'donor' or 'volunteer'
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

      // Step 4: Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'status': status,
        'isProfileComplete': isProfileComplete,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Account created successfully!',
        'role': role,
        'isProfileComplete': isProfileComplete,
      };
    } on FirebaseAuthException catch (e) {
      // Return friendly error messages
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
  // LOGIN — for donor, Volunteer, and Admin
  // ========================================================================
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Sign in with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User user = result.user!;

      // Step 2: Handle Admin login (create admin doc if first time)
      if (email.trim().toLowerCase() == adminEmail.toLowerCase()) {
        DocumentSnapshot adminDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (!adminDoc.exists) {
          // First time admin login — create admin doc
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

      // Step 3: Get user data from Firestore for donors/volunteers
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
  // GOOGLE SIGN-IN
  // ========================================================================
  Future<Map<String, dynamic>> signInWithGoogle({
    String role = 'donor', // default role for Google sign-in
  }) async {
    try {
      // Step 1: Open Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in was cancelled.',
        };
      }

      // Step 2: Get auth tokens
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Step 3: Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in to Firebase
      UserCredential result =
      await _auth.signInWithCredential(credential);
      User user = result.user!;

      // Step 5: Check if user already exists in Firestore
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Existing user — return their saved role
        Map<String, dynamic> userData =
        userDoc.data() as Map<String, dynamic>;
        return {
          'success': true,
          'role': userData['role'],
          'isProfileComplete': userData['isProfileComplete'],
          'status': userData['status'],
        };
      } else {
        // New user — save to Firestore with selected role
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
    await _googleSignIn.signOut().catchError((_) {});
    await _auth.signOut();
  }

  // ========================================================================
  // FORGOT PASSWORD
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
  // GET USER DATA from Firestore
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

  // ── Private: Convert Firebase error codes → readable messages ──────────
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