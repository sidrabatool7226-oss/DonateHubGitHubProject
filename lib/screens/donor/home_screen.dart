// ============================================================
// FILE: lib/screens/donor/home_screen.dart
//
// MERGED DESIGN:
//   Screen A → AppBar, welcome card, campaigns, impact stats,
//               bottom nav
//   Screen B → Donate Items & Donate Funds image cards
//
// FIRESTORE: Fetches campaigns + donor name in real-time
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Which bottom-nav tab is active ──────────────────────────────────────
  int _currentNavIndex = 0;

  // ── Brand green colors (used everywhere) ────────────────────────────────
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bgGray = Color(0xFFF4F6F8);

  // ── Firebase instances ──────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Get the logged-in donor's name from Firestore ───────────────────────
  Future<String> _getDonorName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'donor';

      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'donor';
      }
      return _auth.currentUser?.displayName ?? 'donor';
    } catch (_) {
      return 'donor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: _buildAppBar(),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card (green, shows donor name from Firestore)
            _WelcomeCard(getDonorName: _getDonorName, green: _green),

            const SizedBox(height: 20),

            // 2. Campaigns Section (horizontal scroll from Firestore)
            _SectionTitle(title: 'Active Campaigns'),
            const SizedBox(height: 10),
            _CampaignsRow(db: _db),

            const SizedBox(height: 24),

            // 3. "How would you like to help?" Section
            _SectionTitle(title: 'How would you like to help?'),
            const SizedBox(height: 12),

            // Donate Items card (Screen B style — image + button)
            _DonationActionCard(
              title: 'Donate Items',
              subtitle: 'Clothes, food, toys & supplies',
              imageAsset: 'assets/images/donate_items.png',
              buttonColor: _green,
              onTap: () =>
                  Navigator.pushNamed(context, '/donate_items'),
            ),

            const SizedBox(height: 14),

            // Donate Funds card (Screen B style — charity jar image)
            _DonationActionCard(
              title: 'Donate Funds',
              subtitle: 'Make a monetary contribution',
              imageAsset: 'assets/images/donate_funds.png',
              buttonColor: _lightGreen,
              onTap: () =>
                  Navigator.pushNamed(context, '/donate_funds'),
            ),

            const SizedBox(height: 24),

            // 4. Your Impact This Year (stats card)
            _ImpactCard(db: _db, uid: _auth.currentUser?.uid ?? ''),

            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================================================
  // APPBAR
  // ==========================================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,

      // "D" logo + "DonateHub" title
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'DonateHub',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentNavIndex == 0,
                activeColor: _green,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _NavItem(
                icon: Icons.volunteer_activism_rounded,
                label: 'Impact',
                isActive: _currentNavIndex == 1,
                activeColor: _green,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.card_giftcard_rounded,
                label: 'Rewards',
                isActive: _currentNavIndex == 2,
                activeColor: _green,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentNavIndex == 3,
                activeColor: _green,
                onTap: () => setState(() => _currentNavIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// WIDGET: Welcome Card (green gradient, shows real donor name)
// ==============================================================================
class _WelcomeCard extends StatelessWidget {
  final Future<String> Function() getDonorName;
  final Color green;

  const _WelcomeCard({
    required this.getDonorName,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDonorName(),
      builder: (context, snapshot) {
        // While loading, show a shimmer placeholder
        final name = snapshot.data ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [green, const Color(0xFF2D8A52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name.isEmpty
                              ? 'Welcome back! 👋'
                              : 'Welcome back, $name! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thank you for making a difference',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Decorative circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WIDGET: Section Title
// ==============================================================================
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ==============================================================================
// WIDGET: Campaigns Row (horizontal scroll from Firestore)
// ==============================================================================
class _CampaignsRow extends StatelessWidget {
  final FirebaseFirestore db;

  const _CampaignsRow({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Fetch campaigns AND events from the same 'campaigns' collection
      // Admin can add documents with a 'type' field: 'campaign' or 'event'
      stream: db
          .collection('campaigns')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // ── Loading state ─────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
              ),
            ),
          );
        }

        // ── Error state ───────────────────────────────────────────────
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Could not load campaigns.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // ── Empty state ───────────────────────────────────────────────
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No active campaigns yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // ── Campaign cards list ───────────────────────────────────────
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data() as Map<String, dynamic>;
              return _CampaignCard(data: data);
            },
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WIDGET: Single Campaign Card
// ==============================================================================
class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CampaignCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Safely read Firestore fields
    final String title = data['title'] ?? 'Campaign';
    final String description = data['description'] ?? '';
    final double goal = (data['goalAmount'] ?? 0).toDouble();
    final double collected =
    (data['collectedAmount'] ?? 0).toDouble();
    final String imageUrl = data['image'] ?? '';
    final String endDate = data['endDate'] ?? '';

    // Progress percentage (0.0 → 1.0)
    final double progress =
    (goal > 0) ? (collected / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _imagePlaceholder(),
              loadingBuilder:
                  (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _imagePlaceholder();
              },
            )
                : _imagePlaceholder(),
          ),

          // Campaign details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Progress bar row
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${_fmt(collected)} / \$${_fmt(goal)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B6B3A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Green progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor:
                    const Color(0xFFE0E0E0),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1B6B3A),
                    ),
                  ),
                ),

                if (endDate.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Ends on $endDate',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Format large numbers: 18000 → "18,000"
  String _fmt(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color(0xFF1B6B3A),
      ),
    );
  }
}

// ==============================================================================
// WIDGET: Donation Action Card (Screen B style — big image + button)
// ==============================================================================
class _DonationActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color buttonColor;
  final VoidCallback onTap;

  const _DonationActionCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Big image (Screen B style) ─────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image.asset(
              imageAsset,
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              // If asset not found, show a nice placeholder
              errorBuilder: (_, __, ___) => Container(
                height: 175,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      buttonColor.withOpacity(0.15),
                      buttonColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        title == 'Donate Items'
                            ? Icons.inventory_2_outlined
                            : Icons.attach_money_rounded,
                        size: 54,
                        color: buttonColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: buttonColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Button below image ─────────────────────────────────────
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(30),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGET: Impact Stats Card (Screen A bottom card)
// ==============================================================================
class _ImpactCard extends StatelessWidget {
  final FirebaseFirestore db;
  final String uid;

  const _ImpactCard({
    required this.db,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('donor_stats').doc(uid).get(),
      builder: (context, snapshot) {
        // Default values shown while loading or if no data yet
        double donated = 0;
        int donations = 0;
        int points = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data =
          snapshot.data!.data() as Map<String, dynamic>;
          donated = (data['totalDonated'] ?? 0).toDouble();
          donations = (data['totalDonations'] ?? 0) as int;
          points = (data['points'] ?? 0) as int;
        }

        return Container(
          margin:
          const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Impact This Year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value:
                    '\$${donated.toStringAsFixed(0)}',
                    label: 'Donated',
                    color: const Color(0xFF1B6B3A),
                  ),
                  _Divider(),
                  _StatItem(
                    value: '$donations',
                    label: 'Donations',
                    color: const Color(0xFF1565C0),
                  ),
                  _Divider(),
                  _StatItem(
                    value: '${points.toStringAsFixed(0)}',
                    label: 'Points',
                    color: const Color(0xFF6A1B9A),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Small divider between stat items
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }
}

// Single stat number + label
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// WIDGET: Bottom Navigation Item
// ==============================================================================
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration:
              const Duration(milliseconds: 200),
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              margin: EdgeInsets.only(
                bottom: isActive ? 3 : 0,
              ),
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),

            Icon(
              icon,
              size: 26,
              color: isActive
                  ? activeColor
                  : Colors.grey[400],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isActive
                    ? activeColor
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}