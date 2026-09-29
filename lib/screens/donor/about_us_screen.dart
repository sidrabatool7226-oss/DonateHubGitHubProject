import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://littlesmilesorphanhome.org/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _green,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.volunteer_activism_rounded,
                                color: _green,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Little Smiles Orphan Home',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Powered by DonateHub',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFC0392B),
                    title: 'Our Mission',
                    body:
                    'Little Smiles Orphan Home is dedicated to providing shelter, care, education and essential support to orphaned and underprivileged children. Every child deserves a safe home, a proper education, and the chance to grow up with dignity and hope.',
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.hub_rounded,
                    iconColor: _green,
                    title: 'What is DonateHub?',
                    body:
                    'DonateHub is the official donation management platform of Little Smiles Orphan Home. It connects generous donors and dedicated volunteers directly with the children and causes that need them most — making giving transparent, simple, and impactful.',
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.volunteer_activism_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'How Donors Help',
                    body:
                    'Donors can contribute through fund donations or by donating essential resources such as clothes, food, books and other supplies. Every donation is verified by our team before it reaches the children, ensuring your generosity is used responsibly.',
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'How Volunteers Help',
                    body:
                    'Our volunteers give their time and skills across many roles — resource pickup and delivery, teaching, medical camps, relief distribution, event management, blood donation drives, and more. Their dedication is what turns donations into real, lasting impact.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _green.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '"Every act of generosity has the power to create a little more happiness."',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: _green, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openWebsite,
                            icon: const Icon(Icons.language_rounded, size: 18),
                            label: const Text('Visit Our Website'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              side: const BorderSide(color: _green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6)),
        ],
      ),
    );
  }
}