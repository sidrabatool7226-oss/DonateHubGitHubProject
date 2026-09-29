import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // NEW — for the rounded "DonateHub" font

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Auto navigate after 2 seconds — UNCHANGED, same as before.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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