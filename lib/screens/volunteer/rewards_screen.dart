import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const Color primaryGreen = Color(0xFF1FA15C);

  // Fixed point-based milestone tiers (app-level, not editable from Firestore).
  static const List<Map<String, dynamic>> _milestones = [
    {'name': 'Starter', 'threshold': 0},
    {'name': 'Helper', 'threshold': 250},
    {'name': 'Pro Volunteer', 'threshold': 500},
    {'name': 'Champion', 'threshold': 1000},
    {'name': 'Legend', 'threshold': 2000},
  ];

  Map<String, dynamic> _nextMilestone(int points) {
    for (final m in _milestones) {
      if (points < m['threshold']) return m;
    }
    return _milestones.last;
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'quick_starter':
        return Icons.flash_on;
      case 'speed_runner':
        return Icons.directions_run;
      case 'reliable_runner':
        return Icons.shield_outlined;
      case 'team_player':
        return Icons.groups_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Text('D',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            const Text('DonateHub',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
          ],
        ),
        actions: [
          Stack(
            children: [
              const Icon(Icons.notifications_none, color: Colors.black87),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          const Icon(Icons.settings_outlined, color: Colors.black87),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final points = (userData['points'] ?? 0) as int;
            final tasksDone = (userData['tasksDone'] ?? 0) as int;
            final successRate = (userData['successRate'] ?? 0).toString();
            final rating = (userData['rating'] ?? 0).toString();
            final earnedIds = List<String>.from(userData['earnedBadgeIds'] ?? []);

            final next = _nextMilestone(points);
            final progress = (points / (next['threshold'] == 0 ? 1 : next['threshold']))
                .clamp(0.0, 1.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Rewards',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  // Points card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF1E50E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Your Points',
                                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(points.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Icon(Icons.workspace_premium_outlined,
                                color: Colors.white, size: 34),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Next badge: ${next['name']} (${next['threshold']} pts)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text('Performance',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          value: tasksDone.toString(),
                          label: 'Tasks Done',
                          color: const Color(0xFFE6F6EC),
                          textColor: primaryGreen,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statBox(
                          value: '$successRate%',
                          label: 'Success Rate',
                          color: const Color(0xFFE8EEFD),
                          textColor: const Color(0xFF2962FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statBox(
                          value: rating,
                          label: 'Rating',
                          color: const Color(0xFFF3E8FD),
                          textColor: const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('Earned Badges',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('badges')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, badgeSnapshot) {
                      if (!badgeSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final allBadges = badgeSnapshot.data!.docs;
                      final earned = allBadges
                          .where((doc) => earnedIds.contains(doc.id))
                          .toList();
                      final upcoming = allBadges
                          .where((doc) => !earnedIds.contains(doc.id))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (earned.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('No badges earned yet',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            )
                          else
                            ...earned.map((doc) {
                              final b = doc.data() as Map<String, dynamic>;
                              return _badgeTile(
                                icon: _iconForKey(b['iconKey'] ?? ''),
                                title: b['title'] ?? '',
                                subtitle: b['description'] ?? '',
                                points: '+${b['pointsReward'] ?? 0}',
                                earned: true,
                              );
                            }),

                          const SizedBox(height: 18),
                          const Text('Upcoming Badges',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),

                          if (upcoming.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('All badges earned! 🎉',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            )
                          else
                            ...upcoming.map((doc) {
                              final b = doc.data() as Map<String, dynamic>;
                              return _badgeTile(
                                icon: _iconForKey(b['iconKey'] ?? ''),
                                title: b['title'] ?? '',
                                subtitle: b['description'] ?? '',
                                points: '+${b['pointsReward'] ?? 0}',
                                earned: false,
                              );
                            }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statBox({
    required String value,
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (icon != null) Icon(icon, color: textColor, size: 16),
          Text(value,
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _badgeTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String points,
    required bool earned,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: earned ? primaryGreen.withOpacity(0.12) : Colors.grey.shade200,
            child: Icon(icon, color: earned ? primaryGreen : Colors.grey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(points,
              style: TextStyle(
                  color: earned ? primaryGreen : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}