import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DonorRewardsTab extends StatelessWidget {
  const DonorRewardsTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('donors')
              .doc(uid)
              .snapshots(),
          builder: (context, donorSnap) {
            final donorData = donorSnap.data?.data()
            as Map<String, dynamic>?;
            final int points =
                donorData?['rewardPoints'] ?? 0;
            final int totalDonations =
                donorData?['totalDonations'] ?? 0;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                        20, 24, 20, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B6B3A),
                          Color(0xFF2D8A52)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Star icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Reward Points',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Badge
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.2),
                            borderRadius:
                            BorderRadius.circular(
                                20),
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _getBadge(points),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Progress to next badge ─
                        _NextBadgeCard(points: points),
                        const SizedBox(height: 16),

                        // ── Stats ──────────────────
                        Row(
                          children: [
                            _RewardStat(
                              icon: Icons
                                  .volunteer_activism_rounded,
                              value:
                              '$totalDonations',
                              label:
                              'Total Donations',
                              color: _green,
                              bg: const Color(
                                  0xFFE8F5E9),
                            ),
                            const SizedBox(width: 12),
                            _RewardStat(
                              icon: Icons.star_rounded,
                              value: '$points',
                              label: 'Points Earned',
                              color:
                              Colors.amber[700]!,
                              bg: Colors.amber[50]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Badges section ─────────
                        _BadgesSection(
                            points: points),
                        const SizedBox(height: 16),

                        // ── How points work ────────
                        _HowItWorksCard(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getBadge(int points) {
    if (points >= 500) return 'Platinum Donor 💎';
    if (points >= 200) return 'Gold Donor 🥇';
    if (points >= 100) return 'Silver Donor 🥈';
    if (points >= 50) return 'Bronze Donor 🥉';
    return 'New Donor 🌱';
  }
}

class _NextBadgeCard extends StatelessWidget {
  final int points;
  const _NextBadgeCard({required this.points});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    int nextTarget;
    String nextBadge;

    if (points < 50) {
      nextTarget = 50;
      nextBadge = 'Bronze Donor';
    } else if (points < 100) {
      nextTarget = 100;
      nextBadge = 'Silver Donor';
    } else if (points < 200) {
      nextTarget = 200;
      nextBadge = 'Gold Donor';
    } else if (points < 500) {
      nextTarget = 500;
      nextBadge = 'Platinum Donor';
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text(
              'You have reached the highest tier!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final double progress =
        points / nextTarget.toDouble();
    final int remaining = nextTarget - points;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: _green, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Next Badge',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                nextBadge,
                style: const TextStyle(
                  fontSize: 13,
                  color: _green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                  _green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining more points needed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _RewardStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  final int points;
  const _BadgesSection({required this.points});

  @override
  Widget build(BuildContext context) {
    final badges = [
      {
        'name': 'New Donor',
        'points': 0,
        'icon': '🌱',
        'color': Colors.grey[400]!
      },
      {
        'name': 'Bronze',
        'points': 50,
        'icon': '🥉',
        'color': Colors.brown[400]!
      },
      {
        'name': 'Silver',
        'points': 100,
        'icon': '🥈',
        'color': Colors.grey[600]!
      },
      {
        'name': 'Gold',
        'points': 200,
        'icon': '🥇',
        'color': Colors.amber[700]!
      },
      {
        'name': 'Platinum',
        'points': 500,
        'icon': '💎',
        'color': Colors.blue[400]!
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: Color(0xFF1B6B3A), size: 16),
              SizedBox(width: 6),
              Text(
                'Badge Collection',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,
            children: badges.map((badge) {
              final bool earned =
                  points >= (badge['points'] as int);
              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: earned
                          ? (badge['color'] as Color)
                          .withOpacity(0.15)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: earned
                            ? badge['color'] as Color
                            : Colors.grey[300]!,
                        width: earned ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badge['icon'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          color: earned
                              ? null
                              : Colors.grey
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge['name'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: earned
                          ? badge['color'] as Color
                          : Colors.grey[400],
                      fontWeight: earned
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '${badge['points']}pts',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  color: _green, size: 16),
              SizedBox(width: 6),
              Text(
                'How Points Work',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PointRule(
              icon: '💰',
              text:
              'Every Rs. 100 fund donation = 1 point'),
          _PointRule(
              icon: '📦',
              text:
              'Every resource donation = 10 points'),
          _PointRule(
              icon: '✅',
              text:
              'Points are added after donation is completed'),
        ],
      ),
    );
  }
}

class _PointRule extends StatelessWidget {
  final String icon;
  final String text;

  const _PointRule(
      {required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B6B3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}