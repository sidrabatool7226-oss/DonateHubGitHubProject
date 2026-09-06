// ============================================================
// FILE: lib/screens/donor/contact_us_screen.dart
//
// Organization: Little Smiles Orphan Home (by Volunteers Power
// Pakistan / VPP). App: DonateHub.
//
// Data source: https://littlesmilesorphanhome.org/ (verified)
// Phone, email, address, and all 4 social links below are the
// organization's real, published details — nothing invented.
//
// NOTE ON IMAGES: The header logo and volunteer-section image
// are left as clean icon-based placeholders rather than pulling
// photos of children from the org's gallery, since that needs a
// human to pick/verify the right photo. See asset paths noted
// in the placeholder widgets below.
//
// NOTE ON DEPENDENCY: uses url_launcher for tel:/mailto:/maps/
// social links. Add to pubspec.yaml if not already present:
//   url_launcher: ^6.3.1
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // ── Reuse DonateHub's existing green palette ────────────────────────────
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _greenLight = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  // ── Verified organization details ───────────────────────────────────────
  static const String _orgName = 'Little Smiles Orphan Home';
  static const String _orgSubtitle = 'By Volunteers Power Pakistan (VPP)';
  static const String _phone = '0335 5251494';
  static const String _phoneDialCode = '03355251494';
  static const String _email = 'info@littlesmilesorphanhome.org';
  static const String _address =
      'H# 369, St# 17, D Block, PWD, Islamabad';

  static const String _facebookUrl =
      'https://www.facebook.com/littlesmilesorphanhome/';
  static const String _instagramUrl =
      'https://www.instagram.com/littlesmilesorphanhome/';
  static const String _youtubeUrl =
      'https://youtube.com/volunteerspowerpakistan';
  static const String _tiktokUrl =
      'https://www.tiktok.com/@littlesmilesorphanhome';

  // ── URL launch helper (shared by all buttons below) ─────────────────────
  Future<void> _launch(String url, {String errorLabel = 'this link'}) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch failed');
    } catch (_) {
      Get.snackbar(
        'Could not open',
        'Unable to open $errorLabel on this device.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _callUs() => _launch('tel:$_phoneDialCode', errorLabel: 'the dialer');

  void _emailUs() => _launch('mailto:$_email', errorLabel: 'your email app');

  void _getDirections() {
    final query = Uri.encodeComponent('$_orgName, $_address');
    _launch(
      'https://www.google.com/maps/dir/?api=1&destination=$query',
      errorLabel: 'Google Maps',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(green: _green, greenLight: _greenLight),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── About ────────────────────────────────────────
                    _SectionTitle('About Little Smiles'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Text(
                        'Little Smiles Orphan Home, a welfare project by '
                            'Volunteers Power Pakistan (VPP), provides a safe '
                            'and caring home for orphaned and vulnerable '
                            'children across Pakistan. Beyond shelter, the '
                            'organization focuses on education, emotional '
                            'support, and real opportunities for a brighter '
                            'future for every child in its care.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Location ─────────────────────────────────────
                    _SectionTitle('Our Location'),
                    const SizedBox(height: 10),
                    _LocationCard(
                      green: _green,
                      orgName: _orgName,
                      address: _address,
                      onGetDirections: _getDirections,
                    ),

                    const SizedBox(height: 22),

                    // ── Get in Touch ─────────────────────────────────
                    _SectionTitle('Get in Touch'),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F2FD),
                      label: 'Phone',
                      value: _phone,
                      buttonLabel: 'Call Us',
                      onTap: _callUs,
                    ),
                    const SizedBox(height: 10),
                    _ContactTile(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF6A1B9A),
                      iconBg: const Color(0xFFF3E5F5),
                      label: 'Email',
                      value: _email,
                      buttonLabel: 'Email Us',
                      onTap: _emailUs,
                    ),

                    const SizedBox(height: 22),

                    // ── Become a Volunteer ───────────────────────────
                    _SectionTitle('Become a Volunteer'),
                    const SizedBox(height: 10),
                    _PromoCard(
                      green: _green,
                      greenLight: _greenLight,
                      icon: Icons.volunteer_activism_rounded,
                      // Placeholder — replace image via a background
                      // decoration once you've picked an official photo
                      // from https://littlesmilesorphanhome.org/gallery/
                      // and added it as assets/images/volunteer_activity.jpg
                      text:
                      'Join hands with us to support children and help '
                          'create a brighter future.',
                      buttonLabel: 'Join as a Volunteer',
                      onTap: () {
                        // Existing volunteer application route in main.dart.
                        // Update this if you've since built a different
                        // volunteer-application screen.
                        Get.toNamed('/volunteer_form');
                      },
                    ),

                    const SizedBox(height: 22),

                    // ── Support / Donate ─────────────────────────────
                    _SectionTitle('Support Little Smiles'),
                    const SizedBox(height: 10),
                    _DonateCard(
                      green: _green,
                      greenLight: _greenLight,
                      onTap: () => Get.toNamed('/donate_funds'),
                    ),

                    const SizedBox(height: 22),

                    // ── Social ────────────────────────────────────────
                    _SectionTitle('Follow Little Smiles'),
                    const SizedBox(height: 12),
                    _SocialRow(
                      onFacebook: () =>
                          _launch(_facebookUrl, errorLabel: 'Facebook'),
                      onInstagram: () =>
                          _launch(_instagramUrl, errorLabel: 'Instagram'),
                      onYoutube: () =>
                          _launch(_youtubeUrl, errorLabel: 'YouTube'),
                      onTiktok: () =>
                          _launch(_tiktokUrl, errorLabel: 'TikTok'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// HEADER
// ==========================================================================
class _Header extends StatelessWidget {
  final Color green;
  final Color greenLight;
  const _Header({required this.green, required this.greenLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [green, greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              const Text(
                'Contact Us',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 38), // balances back button
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                // Logo placeholder — swap for the official logo once
                // saved as assets/images/little_smiles_logo.png
                // (source: littlesmilesorphanhome.org)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: green, size: 34),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Little Smiles Orphan Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By Volunteers Power Pakistan (VPP)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SHARED HELPERS
// ==========================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==========================================================================
// LOCATION CARD
// ==========================================================================
class _LocationCard extends StatelessWidget {
  final Color green;
  final String orgName;
  final String address;
  final VoidCallback onGetDirections;

  const _LocationCard({
    required this.green,
    required this.orgName,
    required this.address,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orgName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(address,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[600],
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stylised location visual — not a fake map screenshot,
          // just a lightweight visual accent above the real action.
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, color: green.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text('PWD, Islamabad',
                    style: TextStyle(
                        color: green.withOpacity(0.8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGetDirections,
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CONTACT TILE (Phone / Email)
// ==========================================================================
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: iconColor.withOpacity(0.1),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonLabel,
                style: TextStyle(
                    color: iconColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// PROMO CARD (Volunteer)
// ==========================================================================
class _PromoCard extends StatelessWidget {
  final Color green;
  final Color greenLight;
  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PromoCard({
    required this.green,
    required this.greenLight,
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Placeholder banner — replace with an official volunteer/
          // activity photo (assets/images/volunteer_activity.jpg)
          Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [green.withOpacity(0.12), greenLight.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Icon(icon, color: green.withOpacity(0.55), size: 46),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[700], height: 1.5)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(buttonLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// DONATE CARD
// ==========================================================================
class _DonateCard extends StatelessWidget {
  final Color green;
  final Color greenLight;
  final VoidCallback onTap;

  const _DonateCard({
    required this.green,
    required this.greenLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [green, greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your support can help provide care, education and '
                      'opportunities for children in need.',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: green,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Donate Now',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SOCIAL ROW
// ==========================================================================
class _SocialRow extends StatelessWidget {
  final VoidCallback onFacebook;
  final VoidCallback onInstagram;
  final VoidCallback onYoutube;
  final VoidCallback onTiktok;

  const _SocialRow({
    required this.onFacebook,
    required this.onInstagram,
    required this.onYoutube,
    required this.onTiktok,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SocialButton(
          icon: Icons.facebook_rounded,
          color: const Color(0xFF1877F2),
          onTap: onFacebook,
        ),
        const SizedBox(width: 12),
        _SocialButton(
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFFC2185B),
          onTap: onInstagram,
        ),
        const SizedBox(width: 12),
        _SocialButton(
          icon: Icons.play_circle_fill_rounded,
          color: const Color(0xFFFF0000),
          onTap: onYoutube,
        ),
        const SizedBox(width: 12),
        _SocialButton(
          icon: Icons.music_note_rounded,
          color: const Color(0xFF1A1A1A),
          onTap: onTiktok,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}