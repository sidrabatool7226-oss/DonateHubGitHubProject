import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'donor_campaigns_tab.dart';

class DonorHomeTab extends StatefulWidget {
  const DonorHomeTab({super.key});

  @override
  State<DonorHomeTab> createState() => _DonorHomeTabState();
}

class _DonorHomeTabState extends State<DonorHomeTab> {
  // ── Brand green colors ────────────────────────────────────────────────
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bgGray = Color(0xFFF4F6F8);

  // ── Firebase ──────────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Get logged-in donor name ──────────────────────────────────────────
  Future<String> _getDonorName() async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) {
        return 'donor';
      }

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

      // ─────────────────────────────────────────────────────────────────
      // APP BAR
      // ─────────────────────────────────────────────────────────────────
      appBar: _buildAppBar(),

      // ─────────────────────────────────────────────────────────────────
      // HOME BODY
      // ─────────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card
            _WelcomeCard(
              getDonorName: _getDonorName,
              green: _green,
            ),

            const SizedBox(height: 20),

            // 2. Active Campaigns
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DonorCampaignsTab(),
                ),
              ),
              child: const _SectionTitle(
                title: 'Active Campaigns',
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DonorCampaignsTab(),
                ),
              ),
              child: _CampaignsRow(
                db: _db,
              ),
            ),

            const SizedBox(height: 24),

            // 3. How would you like to help?
            const _SectionTitle(
              title: 'How would you like to help?',
            ),

            const SizedBox(height: 12),

            // ───────────────────────────────────────────────────────────
            // DONATE ITEMS
            // Existing route — NOT changing your donation flow
            // ───────────────────────────────────────────────────────────
            _DonationActionCard(
              title: 'Donate Items',
              subtitle: 'Clothes, food, toys & supplies',
              imageAsset: 'assets/images/donate_items.png',
              buttonColor: _green,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/donate_items',
                );
              },
            ),

            const SizedBox(height: 14),

            // ───────────────────────────────────────────────────────────
            // DONATE FUNDS
            // Existing route — NOT changing your donation flow
            // ───────────────────────────────────────────────────────────
            _DonationActionCard(
              title: 'Donate Funds',
              subtitle: 'Make a monetary contribution',
              imageAsset: 'assets/images/donate_funds.png',
              buttonColor: _lightGreen,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/donate_funds',
                );
              },
            ),

            // Bottom space
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // APP BAR
  // =========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,

      title: Row(
        children: [
          // DonateHub D logo
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
}

// ============================================================================
// WELCOME CARD
// ============================================================================

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
        final name = snapshot.data ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            0,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                green,
                const Color(0xFF2D8A52),
              ],
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
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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

              // Heart decoration
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

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
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

// ============================================================================
// CAMPAIGNS ROW
// ============================================================================

class _CampaignsRow extends StatelessWidget {
  final FirebaseFirestore db;

  const _CampaignsRow({
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('campaigns')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Could not load campaigns.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isActive'] == true;
        }).toList();

        // Empty
        if (docs.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'No active campaigns yet.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        // Campaign cards
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data()
              as Map<String, dynamic>;

              return _CampaignCard(
                data: data,
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// SINGLE CAMPAIGN CARD
// ============================================================================

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CampaignCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String title =
        data['title'] ?? 'Campaign';

    final String description =
        data['description'] ?? '';

    final double goal =
    (data['goalAmount'] ?? 0).toDouble();

    final double collected =
    (data['collectedAmount'] ?? 0).toDouble();

    final String imageUrl =
        data['image'] ?? '';

    final String endDate =
        data['endDate'] ?? '';

    final double progress = goal > 0
        ? (collected / goal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(
        right: 14,
      ),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // Campaign image
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                  _imagePlaceholder(),
              loadingBuilder:
                  (_, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

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
                  overflow:
                  TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Progress row
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
                      'Rs. ${_fmt(collected)} / Rs. ${_fmt(goal)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(0xFF1B6B3A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Progress bar
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(4),
                  child:
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor:
                    const Color(0xFFE0E0E0),
                    valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
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

// ============================================================================
// DONATION ACTION CARD
// ============================================================================

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
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
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
          // Image
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image.asset(
              imageAsset,
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 175,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        buttonColor
                            .withOpacity(0.15),
                        buttonColor
                            .withOpacity(0.05),
                      ],
                      begin:
                      Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          title ==
                              'Donate Items'
                              ? Icons
                              .inventory_2_outlined
                              : Icons
                              .attach_money_rounded,
                          size: 54,
                          color: buttonColor
                              .withOpacity(0.6),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          subtitle,
                          style: TextStyle(
                            color: buttonColor
                                .withOpacity(
                                0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Button
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onTap,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  buttonColor,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
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