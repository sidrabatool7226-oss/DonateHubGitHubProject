import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // NEW — for the rounded "DonateHub" font
import 'package:firebase_auth/firebase_auth.dart'; // FIXED (Bug 9)
import 'package:cloud_firestore/cloud_firestore.dart'; // FIXED (Bug 9)
import 'package:flutter/foundation.dart' show kIsWeb; // FIXED (Bug 9)
import '../../services/auth_service.dart'; // FIXED (Bug 9)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // FIXED (Bug 9) — work out where to go while the splash is showing, so the
    // 2-second splash is unchanged and the decision is usually ready by then.
    final Future<String> routeFuture = _resolveStartRoute();
    // Auto navigate after 2 seconds — UNCHANGED, same as before.
    Future.delayed(const Duration(seconds: 2), () async {
      final String route = await routeFuture;
      if (mounted) {
        Navigator.pushReplacementNamed(context, route); // FIXED (Bug 9) — was always '/login'
      }
    });
  }

  // FIXED (Bug 9) — the splash always went to /login, so users had to sign in on
  // every app launch and on every web refresh even though Firebase Auth keeps the
  // session. This restores it, using the SAME destinations the login screens use.
  // Any problem (no user, offline, timeout, unknown role) falls back to '/login',
  // which is exactly what happened before.
  Future<String> _resolveStartRoute() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return '/login';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic> data = {};
      if (doc.exists) {
        data = doc.data() as Map<String, dynamic>;
      } else if ((user.email ?? '').toLowerCase() ==
          AuthService.adminEmail.toLowerCase()) {
        // Same first-login bootstrap rule AuthService.loginUser applies to the admin.
        data = {'role': 'admin'};
      } else {
        await AuthService().signOut();
        return '/login';
      }

      // Deactivated accounts must not be restored (same rule as login).
      if ((data['status'] ?? 'active').toString() == 'inactive') {
        await AuthService().signOut();
        return '/login';
      }

      final String role = (data['role'] ?? '').toString();

      if (role == 'admin') {
        return kIsWeb ? '/admin_dashboard_web' : '/admin_dashboard';
      }
      if (role == 'manager') {
        return kIsWeb ? '/manager_dashboard_web' : '/manager_dashboard';
      }

      // The web panel is Admin/Manager only (same rule as LoginScreenWeb).
      if (kIsWeb) {
        await AuthService().signOut();
        return '/login';
      }

      if (role == 'donor') return '/donor_dashboard';
      if (role == 'volunteer') {
        // Same as login: incomplete profile -> form, otherwise the verification screen
        // (which itself forwards a Verified volunteer to the dashboard).
        return data['isProfileComplete'] == true
            ? '/verification_status'
            : '/volunteer_form';
      }
      return '/login';
    } catch (_) {
      return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full screen background image ─────────────────────
          // UNCHANGED asset — this already IS the teal gradient + hands +
          // heart photo shown in the Canva screenshot, so no separate
          // overlay gradient is needed on top of it anymore (removed the
          // old synthetic teal gradient layer — this real photo already
          // has that exact color baked in, and stacking a second gradient
          // on top of it was making the top slightly darker than the
          // screenshot).
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
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
                );
              },
            ),
          ),

          // ── Layer 2: Main content ───────────────────────────────────────
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Circular Logo — CHANGED: bigger, and no longer
                  // wrapped in an extra white circle + border. logo.png
                  // already has its own white background and green ring
                  // baked in (matches the screenshot exactly) — the old
                  // extra Container was drawing a SECOND ring around that,
                  // which is why the logo looked smaller/different before.
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              child: const Icon(
                                Icons.volunteer_activism,
                                size: 70,
                                color: Color(0xFF3A8A6E),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── DonateHub text — CHANGED: now uses Baloo 2 (the
                  // rounded, bold display font from the Canva screenshot)
                  // via google_fonts instead of the default system font.
                  Text(
                    'DonateHub',
                    style: GoogleFonts.baloo2(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A3A2A),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}