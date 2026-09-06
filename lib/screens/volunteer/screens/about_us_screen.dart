// about_us_screen.dart

import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFFEAF6EF);
  static const Color _text = Color(0xFF1B2A22);
  static const Color _muted = Color(0xFF617068);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _green,
                borderRadius:
                BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 42,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Little Smiles Orphan Home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Making a difference, one smile at a time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.88),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Who We Are',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Little Smiles Orphan Home (LSOH) is dedicated '
                  'to supporting children who need care, compassion '
                  'and opportunities for a better future. Our goal '
                  'is to create a safe and supportive environment '
                  'where every child can grow with dignity, hope '
                  'and a smile.',
              style: TextStyle(
                fontSize: 14,
                height: 1.65,
                color: _muted,
              ),
            ),

            const SizedBox(height: 24),

            const _InfoCard(
              icon: Icons.favorite_rounded,
              title: 'Our Mission',
              description:
              'To support children in need by providing '
                  'care, resources and opportunities through '
                  'the help of compassionate donors and '
                  'volunteers.',
            ),

            const SizedBox(height: 12),

            const _InfoCard(
              icon: Icons.volunteer_activism_rounded,
              title: 'Our Community',
              description:
              'LSOH brings donors, volunteers and the '
                  'organization together so that support can '
                  'reach the children who need it most.',
            ),

            const SizedBox(height: 12),

            const _InfoCard(
              icon: Icons.handshake_rounded,
              title: 'Our Approach',
              description:
              'We encourage meaningful donations of funds '
                  'and useful resources while supporting '
                  'responsible volunteer participation in '
                  'community activities.',
            ),

            const SizedBox(height: 26),

            const Text(
              'About DonateHub',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: _green.withOpacity(.10),
                ),
              ),
              child: const Text(
                'DonateHub is the digital platform created '
                    'to make it easier for supporters of Little '
                    'Smiles Orphan Home to contribute. Donors can '
                    'support campaigns through fund donations or '
                    'donate useful resources. Volunteers can also '
                    'participate in approved activities and help '
                    'the organization serve the community.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.65,
                  color: Color(0xFF405149),
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'What We Believe',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
            const SizedBox(height: 12),

            const _BeliefRow(
              text:
              'Every child deserves care, dignity and hope.',
            ),
            const _BeliefRow(
              text:
              'Community support can create meaningful change.',
            ),
            const _BeliefRow(
              text:
              'Responsible giving helps resources reach those in need.',
            ),
            const _BeliefRow(
              text:
              'Small acts of kindness can create big smiles.',
            ),

            const SizedBox(height: 28),

            Center(
              child: Text(
                'Little Smiles Orphan Home • DonateHub',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B6B3A),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2A22),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: Color(0xFF68766E),
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

class _BeliefRow extends StatelessWidget {
  final String text;

  const _BeliefRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF1B6B3A),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF526159),
              ),
            ),
          ),
        ],
      ),
    );
  }
}