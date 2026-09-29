// ============================================================
// FILE: lib/screens/donor/donor_leaderboard_screen.dart (NEW)
//
// PURPOSE
// Donor-facing "Community Leaderboard" — the piece that did not
// exist before this feature. Two parts:
//   1. "Your Rank" — always shown to the donor about THEMSELVES,
//      regardless of their own privacy choice (it's their own data).
//   2. Public list — only donors with showOnLeaderboard == true
//      appear here, in their TRUE rank position (not renumbered),
//      so the list stays honest about where the visible donors
//      actually stand, without revealing who is hidden.
//
// Reuses RewardsOverviewController's badge logic (badge tiers,
// icons) instead of duplicating it — the Manager/Admin internal
// view and this donor-facing view always agree on what a
// "Gold Donor" etc. means.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/rewards_overview_controller.dart';

class DonorLeaderboardScreen extends StatelessWidget {
  const DonorLeaderboardScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardsOverviewController());
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Leaderboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Text('See how your giving compares', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('donors').orderBy('rewardPoints', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _green));
                  }

                  // NEW — surfaces a read failure (e.g. a security-rules
                  // issue) clearly instead of the screen just looking
                  // permanently empty with no explanation.
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 40, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load the leaderboard.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final int myIndex = docs.indexWhere((d) => d.id == myUid);
                  final int myRank = myIndex >= 0 ? myIndex + 1 : 0;
                  final int myPoints = myIndex >= 0 ? ((docs[myIndex].data() as Map)['rewardPoints'] ?? 0) as int : 0;

                  // Only donors who opted in appear below, at their TRUE
                  // rank — private donors are skipped, not renumbered in.
                  final visible = <MapEntry<int, QueryDocumentSnapshot>>[];
                  for (int i = 0; i < docs.length; i++) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    if (d['showOnLeaderboard'] == true) visible.add(MapEntry(i + 1, docs[i]));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Your Rank — always visible to yourself ──────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _green.withOpacity(0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                child: Text(
                                  myRank > 0 ? '#$myRank' : '—',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    myRank > 0 ? 'Your Rank — $myPoints points' : 'Not ranked yet',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    myRank > 0 ? 'Out of ${docs.length} donors · only visible to you' : 'Make a donation to join the ranking',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('Top Donors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),

                      if (visible.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Icon(Icons.visibility_off_outlined, size: 36, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text('No donors are visible on the leaderboard yet.',
                                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                            ],
                          ),
                        )
                      else
                        ...visible.take(10).map((entry) {
                          final int rank = entry.key;
                          final data = entry.value.data() as Map<String, dynamic>;
                          final bool isMe = entry.value.id == myUid;
                          final int points = (data['rewardPoints'] ?? 0) as int;
                          final badge = controller.donorBadge(points);
                          final icon = controller.donorBadgeIcon(points);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(entry.value.id).get(),
                            builder: (context, userSnap) {
                              final name = (userSnap.data?.data() as Map<String, dynamic>?)?['name'] ?? 'Donor';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: rank <= 3 ? Border.all(color: Colors.amber.shade300, width: 1.5) : null,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        rank <= 3 ? (rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉') : '#$rank',
                                        style: TextStyle(fontSize: rank <= 3 ? 16 : 13, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFE6F5EE),
                                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                          style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('$name${isMe ? ' (You)' : ''}',
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                          Row(children: [
                                            Text(icon, style: const TextStyle(fontSize: 11)),
                                            const SizedBox(width: 4),
                                            Text(badge, style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Text('$points', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _green)),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}