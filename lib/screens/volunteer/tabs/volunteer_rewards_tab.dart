import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_rewards_controller.dart';

class VolunteerRewardsTab extends StatelessWidget {
  const VolunteerRewardsTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerRewardsController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }

          final points = controller.rewardPoints.value;
          final tasks = controller.completedTasksCount.value;
          final next = controller.nextTierInfo;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.volunteer_activism_rounded, color: Colors.amber, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text('$points', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                      const Text('Reward Points', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(controller.badgeIcon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(controller.badgeName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                      // ── Progress to next tier ─────────────────
                      if (next['target'] != null)
                        _NextTierCard(current: tasks, target: next['target'], nextName: next['name'])
                      else
                        _MaxTierCard(),
                      const SizedBox(height: 16),

                      // ── Stats ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              icon: Icons.task_alt_rounded,
                              value: '$tasks',
                              label: 'Completed Tasks',
                              color: _green,
                              bg: const Color(0xFFE8F5E9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: Icons.star_rounded,
                              value: '$points',
                              label: 'Total Points',
                              color: Colors.amber[700]!,
                              bg: Colors.amber[50]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Badge Collection ────────────────────────
                      _BadgeCollection(completedTasks: tasks),
                      const SizedBox(height: 16),

                      // ── Recent Completed Tasks ──────────────────
                      _RecentTasksCard(controller: controller),
                      const SizedBox(height: 16),

                      // ── How points work ─────────────────────────
                      _HowItWorksCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NextTierCard extends StatelessWidget {
  final int current;
  final int target;
  final String nextName;
  const _NextTierCard({required this.current, required this.target, required this.nextName});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: _green, size: 18),
              const SizedBox(width: 6),
              const Text('Next Badge', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(nextName, style: const TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(_green)),
          ),
          const SizedBox(height: 8),
          Text('${target - current} more completed tasks needed', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _MaxTierCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const Row(children: [
        Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
        SizedBox(width: 12),
        Text('You have reached the highest tier!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;
  const _StatBox({required this.icon, required this.value, required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _BadgeCollection extends StatelessWidget {
  final int completedTasks;
  const _BadgeCollection({required this.completedTasks});

  @override
  Widget build(BuildContext context) {
    final badges = [
      {'name': 'New', 'target': 0, 'icon': '🌱', 'color': Colors.grey[400]!},
      {'name': 'Rising Star', 'target': 5, 'icon': '⭐', 'color': Colors.orange[400]!},
      {'name': 'Dedicated', 'target': 15, 'icon': '🎖️', 'color': Colors.blue[400]!},
      {'name': 'Community Hero', 'target': 30, 'icon': '🏅', 'color': Colors.purple[400]!},
      {'name': 'Legend', 'target': 50, 'icon': '👑', 'color': Colors.amber[700]!},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFF1B6B3A), size: 16),
            SizedBox(width: 6),
            Text('Badge Collection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((badge) {
              final earned = completedTasks >= (badge['target'] as int);
              return Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: earned ? (badge['color'] as Color).withOpacity(0.15) : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: earned ? badge['color'] as Color : Colors.grey[300]!, width: earned ? 2 : 1),
                    ),
                    child: Center(child: Text(badge['icon'] as String, style: TextStyle(fontSize: 24, color: earned ? null : Colors.grey.withOpacity(0.4)))),
                  ),
                  const SizedBox(height: 6),
                  Text(badge['name'] as String, style: TextStyle(fontSize: 9.5, color: earned ? badge['color'] as Color : Colors.grey[400], fontWeight: earned ? FontWeight.w600 : FontWeight.normal)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentTasksCard extends StatelessWidget {
  final VolunteerRewardsController controller;
  const _RecentTasksCard({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Recent Completed Tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          if (controller.recentCompletedTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('No completed tasks yet', style: TextStyle(color: Colors.grey[400], fontSize: 13))),
            )
          else
            ...controller.recentCompletedTasks.map((task) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check_rounded, color: _green, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task['itemName'] ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(controller.timeAgo(task['completedAt']), style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const Text('+20 pts', style: TextStyle(fontSize: 11.5, color: _green, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          const SizedBox(height: 8),
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
        border: Border.all(color: _green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(children: [
            Icon(Icons.info_outline, color: _green, size: 16),
            SizedBox(width: 6),
            Text('How Points Work', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _green)),
          ]),
          SizedBox(height: 10),
          Text('🚚  Every completed delivery = 20 points', style: TextStyle(fontSize: 12, color: _green)),
          SizedBox(height: 6),
          Text('✅  Points are added once manager confirms delivery proof', style: TextStyle(fontSize: 12, color: _green)),
        ],
      ),
    );
  }
}