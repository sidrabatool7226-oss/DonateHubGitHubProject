import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'volunteer_applications_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  String managerName = '';
  int _currentNavIndex = 0;

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryGreen = Color(0xFF2E7D6B);

  @override
  void initState() {
    super.initState();
    _loadManagerName();
  }

  Future<void> _loadManagerName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        managerName = doc.data()?['name'] ?? 'Manager';
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Merges volunteer-application events and donation events into one
  // chronologically sorted activity feed, using real Firestore data only.
  Stream<List<_ActivityItem>> _recentActivityStream() {
    final volunteersStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();

    final donationsStream = FirebaseFirestore.instance
        .collection('donations')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();

    return volunteersStream.asyncMap((volunteerSnap) async {
      final donationSnap = await donationsStream.first;

      final items = <_ActivityItem>[];

      for (final doc in volunteerSnap.docs) {
        final data = doc.data();
        final isPending = data['status'] == 'pending';
        final ts = data['createdAt'] as Timestamp?;
        items.add(_ActivityItem(
          icon: isPending ? Icons.person_add_alt_1 : Icons.check,
          iconColor: isPending ? Colors.orange : primaryGreen,
          iconBg: isPending
              ? Colors.orange.withOpacity(0.15)
              : primaryGreen.withOpacity(0.15),
          title: isPending
              ? 'New volunteer application from'
              : 'Volunteer verified:',
          boldText: data['name'] ?? 'Unknown',
          time: ts?.toDate(),
        ));
      }

      for (final doc in donationSnap.docs) {
        final data = doc.data();
        final ts = data['timestamp'] as Timestamp?;
        final donor = data['donorName'] ?? data['campaignName'] ?? 'Donor';
        items.add(_ActivityItem(
          icon: Icons.volunteer_activism,
          iconColor: primaryGreen,
          iconBg: primaryGreen.withOpacity(0.15),
          title: 'Donation received from',
          boldText: donor,
          time: ts?.toDate(),
        ));
      }

      items.sort((a, b) {
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        return b.time!.compareTo(a.time!);
      });

      return items.take(8).toList();
    });
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            Text(
              managerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: primaryBlue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              // ---- Stat cards (2x2 grid) ----
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'volunteer')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statCard(
                          icon: Icons.people_alt_outlined,
                          label: 'Pending Volunteers',
                          value: count.toString(),
                          iconColor: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const VolunteerApplicationsScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('donations')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statCard(
                          icon: Icons.favorite_border,
                          label: 'Pending Donations',
                          value: count.toString(),
                          iconColor: primaryBlue,
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // Assumes a 'tasks' collection with a 'status' field.
                      // Returns 0 safely if the collection doesn't exist yet.
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('status', isEqualTo: 'active')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statCard(
                          icon: Icons.assignment_outlined,
                          label: 'Active Tasks',
                          value: count.toString(),
                          iconColor: primaryBlue,
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('status', isEqualTo: 'completed')
                          .where('completedAt',
                          isGreaterThanOrEqualTo: DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day))
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statCard(
                          icon: Icons.check_circle_outline,
                          label: 'Completed Today',
                          value: count.toString(),
                          iconColor: primaryGreen,
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Recent Activity (fills remaining space, scrolls internally only) ----
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All',
                                  style: TextStyle(color: primaryBlue)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: StreamBuilder<List<_ActivityItem>>(
                          stream: _recentActivityStream(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final items = snapshot.data!;
                            if (items.isEmpty) {
                              return const Center(
                                child: Text('No recent activity',
                                    style: TextStyle(color: Colors.grey)),
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: item.iconBg,
                                    child: Icon(item.icon,
                                        color: item.iconColor, size: 20),
                                  ),
                                  title: Text.rich(
                                    TextSpan(
                                      text: '${item.title} ',
                                      style: const TextStyle(fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: item.boldText,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  subtitle: Text(_timeAgo(item.time),
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VolunteerApplicationsScreen(),
              ),
            ).then((_) => setState(() => _currentNavIndex = 0));
          }
          // index 2 (Donations) and 3 (Tasks) screens can be wired here
          // the same way once those screens exist.
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: 'Volunteers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Donations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style:
                    const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style:
              const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple data holder used only inside this file to build the merged feed.
class _ActivityItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String boldText;
  final DateTime? time;

  _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.boldText,
    required this.time,
  });
}