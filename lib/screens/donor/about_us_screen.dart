import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFFEAF6EF);
  static const Color _background = Color(0xFFF7FAF8);
  static const Color _text = Color(0xFF1B2A22);
  static const Color _secondaryText = Color(0xFF5F6D65);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // HERO SECTION
              // ----------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      width: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                        fontSize: 22,
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
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ----------------------------------------------------------
              // WHO WE ARE
              // ----------------------------------------------------------
              const _SectionTitle(
                title: 'Who We Are',
                icon: Icons.info_outline_rounded,
              ),

              const SizedBox(height: 10),

              const Text(
                'Little Smiles Orphan Home (LSOH) is dedicated to supporting '
                    'children who need care, compassion and opportunities for a '
                    'better future. Our goal is to create a safe and supportive '
                    'environment where every child can grow with dignity, hope '
                    'and a smile.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: _secondaryText,
                ),
              ),

              const SizedBox(height: 26),

              // ----------------------------------------------------------
              // MISSION
              // ----------------------------------------------------------
              const _InfoCard(
                icon: Icons.favorite_rounded,
                title: 'Our Mission',
                description:
                'To support children in need by providing care, '
                    'resources and opportunities through the help of '
                    'compassionate donors and volunteers.',
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------------
              // COMMUNITY
              // ----------------------------------------------------------
              const _InfoCard(
                icon: Icons.volunteer_activism_rounded,
                title: 'Our Community',
                description:
                'LSOH brings donors, volunteers and the organization '
                    'together so that support can reach the children who '
                    'need it most.',
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------------
              // APPROACH
              // ----------------------------------------------------------
              const _InfoCard(
                icon: Icons.handshake_rounded,
                title: 'Our Approach',
                description:
                'We encourage meaningful donations of funds and useful '
                    'resources while supporting responsible volunteer '
                    'participation in community activities.',
              ),

              const SizedBox(height: 28),

              // ----------------------------------------------------------
              // ABOUT DONATEHUB
              // ----------------------------------------------------------
              const _SectionTitle(
                title: 'About DonateHub',
                icon: Icons.apps_rounded,
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _green.withOpacity(.10),
                  ),
                ),
                child: const Text(
                  'DonateHub is the digital platform created to make it '
                      'easier for supporters of Little Smiles Orphan Home to '
                      'contribute. Donors can support campaigns through fund '
                      'donations or donate useful resources. Volunteers can '
                      'also participate in approved activities and help the '
                      'organization serve the community.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.65,
                    color: Color(0xFF405149),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ----------------------------------------------------------
              // WHAT WE BELIEVE
              // ----------------------------------------------------------
              const _SectionTitle(
                title: 'What We Believe',
                icon: Icons.lightbulb_outline_rounded,
              ),

              const SizedBox(height: 14),

              const _BeliefRow(
                icon: Icons.favorite_border_rounded,
                text: 'Every child deserves care, dignity and hope.',
              ),

              const _BeliefRow(
                icon: Icons.people_outline_rounded,
                text: 'Community support can create meaningful change.',
              ),

              const _BeliefRow(
                icon: Icons.visibility_outlined,
                text:
                'Responsible giving helps resources reach those in need.',
              ),

              const _BeliefRow(
                icon: Icons.auto_awesome_outlined,
                text: 'Small acts of kindness can create big smiles.',
              ),

              const SizedBox(height: 28),

              // ----------------------------------------------------------
              // FOOTER
              // ----------------------------------------------------------
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      width: 80,
                      color: _green.withOpacity(.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Little Smiles Orphan Home • DonateHub',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
// SECTION TITLE
// ==========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6EF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1B6B3A),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2A22),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// INFO CARD
// ==========================================================================

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
    const green = Color(0xFF1B6B3A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: green,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

// ==========================================================================
// BELIEF ROW
// ==========================================================================

class _BeliefRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BeliefRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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