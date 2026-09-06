import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/rewards_overview_controller.dart';
import 'volunteer_details_screen.dart';

class RewardsOverviewScreen extends StatelessWidget {
  const RewardsOverviewScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardsOverviewController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_emerald, _mint], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Rewards & Recognition',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Obx(() => Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.all(4),
                    child: Row(children: [
                      _ToggleBtn(label: 'Donors', icon: Icons.favorite_rounded,
                          isSelected: controller.selectedTab.value == 0, onTap: () => controller.selectedTab.value = 0),
                      _ToggleBtn(label: 'Volunteers', icon: Icons.groups_rounded,
                          isSelected: controller.selectedTab.value == 1, onTap: () => controller.selectedTab.value = 1),
                    ]),
                  )),
                ],
              ),
            ),

            Expanded(
              child: Obx(() => controller.selectedTab.value == 0
                  ? _DonorsRewardsList(controller: controller)
                  : _VolunteersRewardsList(controller: controller)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label; final IconData icon; final bool isSelected; final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.icon, required this.isSelected, required this.onTap});
  static const Color _emerald = Color(0xFF0F6E4F);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: isSelected ? _emerald : Colors.white),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12.5, color: isSelected ? _emerald : Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ==========================================================================
// DONORS REWARDS LIST
// ==========================================================================
class _DonorsRewardsList extends StatelessWidget {
  final RewardsOverviewController controller;
  const _DonorsRewardsList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.donorsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No donors yet', style: TextStyle(color: Colors.grey[500])));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final points = (data['rewardPoints'] ?? 0) as int;
            final donations = (data['totalDonations'] ?? 0) as int;
            final badge = controller.donorBadge(points);
            final icon = controller.donorBadgeIcon(points);
            final isTop3 = index < 3;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(docs[index].id).get(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final name = userData?['name'] ?? 'Donor';
                final email = userData?['email'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: isTop3 ? Border.all(color: Colors.amber.shade300, width: 1.5) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24, backgroundColor: const Color(0xFFE6F5EE),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                style: const TextStyle(color: _emerald, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (isTop3)
                            Positioned(
                              top: -4, right: -4,
                              child: Text(index == 0 ? '🥇' : index == 1 ? '🥈' : '🥉', style: const TextStyle(fontSize: 16)),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(badge, style: const TextStyle(fontSize: 11, color: _emerald, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text('· $donations donations', style: TextStyle(fontSize: 10.5, color: Colors.grey[400])),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$points', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _emerald)),
                          Text('points', style: TextStyle(fontSize: 9.5, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================================================
// VOLUNTEERS REWARDS LIST
// ==========================================================================
class _VolunteersRewardsList extends StatelessWidget {
  final RewardsOverviewController controller;
  const _VolunteersRewardsList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.volunteersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No verified volunteers yet', style: TextStyle(color: Colors.grey[500])));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Volunteer';

            return FutureBuilder<int>(
              future: controller.getVolunteerTaskCount(doc.id),
              builder: (context, taskSnap) {
                final tasks = taskSnap.data ?? 0;
                final badge = controller.volunteerBadge(tasks);
                final icon = controller.volunteerBadgeIcon(tasks);

                return GestureDetector(
                  onTap: () => Get.to(
                        () => VolunteerDetailsScreen(docId: doc.id, data: data),
                    transition: Transition.rightToLeft,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24, backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(data['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text(icon, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(badge, style: const TextStyle(fontSize: 11, color: _emerald, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$tasks', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _emerald)),
                            Text('tasks', style: TextStyle(fontSize: 9.5, color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey[350]),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}