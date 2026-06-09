// ============================================================
// FILE: lib/screens/auth/splash_screen.dart
//
// DESIGN MATCH:
//  - Full screen background image (hands holding heart)
//  - Circular logo (Little Smiles Orphan Home) in center-top
//  - "DonateHub" text below logo
//  - Dark green "Continue to App →" button at bottom
// ============================================================

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Full screen background image ─────────────────────
          // This is the hands-holding-heart photo in your design.
          // Make sure you add it at: assets/images/background.png
          // If you don't have a separate background image, remove this
          // and the teal color from Layer 2 will show instead.
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              // If background.png is missing, show a teal color instead
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5BA8A0), // Teal top (matches your design)
                        Color(0xFF4A9E95), // Slightly darker teal bottom
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Layer 2: Light teal overlay at top (to match your design) ─
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC5BA8A0), // Semi-transparent teal
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Main content ──────────────────────────────────────
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  // ── Top spacer ─────────────────────────────────────────
                  const SizedBox(height: 48),

                  // ── Circular Logo ──────────────────────────────────────
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF3A8A6E), // Dark green border
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        // Fallback if logo is missing
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.volunteer_activism,
                            size: 60,
                            color: Color(0xFF3A8A6E),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── "DonateHub" text ───────────────────────────────────
                  const Text(
                    'DonateHub',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A2A), // Dark green text
                      letterSpacing: 1.2,
                    ),
                  ),

                  // ── Spacer pushes button to bottom ─────────────────────
                  const Spacer(),

                  // ── "Continue to App" Button ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Go to Login Screen
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2D6A4F), // Dark green button
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}