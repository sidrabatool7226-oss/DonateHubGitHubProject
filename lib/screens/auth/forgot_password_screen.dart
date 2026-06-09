// ============================================================
// FILE: lib/screens/auth/forgot_password_screen.dart
//
// DESIGN: Matches your Login Screen exactly
//  - Full screen background image (background.png)
//  - Teal gradient overlay at top
//  - Circular logo
//  - White title + subtitle
//  - Frosted glass email field
//  - Green "Send Reset Link" button
//  - "Remember your password? Login" link at bottom
//
// HOW TO NAVIGATE HERE from login_screen.dart:
//  Replace the _handleForgotPassword() dialog with:
//
//  void _handleForgotPassword() {
//    Navigator.push(
//      context,
//      MaterialPageRoute(
//        builder: (_) => const ForgotPasswordScreen(),
//      ),
//    );
//  }
//
//  AND add this import at the top of login_screen.dart:
//  import 'forgot_password_screen.dart';
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ── Form & controller ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;

  // ── Firebase instance ────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // SEND PASSWORD RESET EMAIL
  // ==========================================================================
  Future<void> _sendResetLink() async {
    // Step 1: Validate the email field
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 2: Call Firebase to send reset email
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Step 3: Show success message
      _showSnackBar(
        message: 'Reset link sent! Check your email inbox.',
        isSuccess: true,
      );

      // Step 4: Clear the email field after success
      _emailController.clear();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show specific Firebase error message
      _showSnackBar(
        message: _getErrorMessage(e.code),
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        message: 'Something went wrong. Please try again.',
        isSuccess: false,
      );
    }
  }

  // ── Convert Firebase error codes to readable messages ────────────────────
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      default:
        return 'Failed to send reset link. Please try again.';
    }
  }

  // ── Show floating snackbar ────────────────────────────────────────────────
  void _showSnackBar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF2D6A4F)
            : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================================================
  // BUILD UI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches login screen: teal bg so no white gap ever shows
      backgroundColor: const Color(0xFF5BA8A0),

      body: Stack(
        children: [
          // ── Layer 1: Full screen background image ────────────────────────
          // Same technique as login screen — covers 100% of screen
          Positioned.fill(
            child: Container(
              color: const Color(0xFF5BA8A0),
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5BA8A0),
                        Color(0xFF4A9E95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 2: Teal overlay at top (same as login) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.60,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xDD5BA8A0), // Strong teal at top
                    Colors.transparent, // Fades to show background image
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Back button (top-left, over image) ───────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Layer 4: Main scrollable content (same structure as login) ────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Space for back button
                    const SizedBox(height: 56),

                    // ── Circular Logo (identical to login screen) ──────────
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3A8A6E),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.volunteer_activism,
                            size: 44,
                            color: Color(0xFF3A8A6E),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Lock icon inside a frosted circle ──────────────────
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── "Reset Your Password" title (same style as "LOGIN") ─
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // ── Subtitle text ──────────────────────────────────────
                    Text(
                      "Enter your email and we'll send\nyou a reset link",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Email field (same frosted glass style as login) ─────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                        ),
                        // Email icon on the left
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.white.withOpacity(0.85),
                          size: 20,
                        ),
                        // Suffix: small mail icon (same as your login design)
                        suffixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                        // Frosted white fill (same as login)
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.25),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          color: Color(0xFFFFCDD2),
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ── "Send Reset Link" button (same style as "Login") ────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF2D6A4F).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── "Remember your password? Login" (same as login links)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Remember your password? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF40916C), // Vibrant green
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF40916C),
                              decorationThickness: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}