import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/admin_profile_screen.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _StatsGrid(db: db),
                    ),
                    const SizedBox(height: 12),
                    _QuickActions(),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 3,
                      child: _RecentActivity(db: db),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Greeting
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Little Smiles Orphan Home',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Notification bell
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Profile icon
          GestureDetector(
            onTap: () => Get.to(
                  () => const AdminProfileScreen(),
              transition: Transition.rightToLeft,
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// STATS GRID
// ==========================================================================
class _StatsGrid extends StatelessWidget {
  final FirebaseFirestore db;
  const _StatsGrid({required this.db});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          stream: db.collection('users').where('role', isEqualTo: 'donor').snapshots(),
          label: 'Total Donors',
          icon: Icons.favorite_rounded,
          color: const Color(0xFF1565C0),
          lightColor: const Color(0xFFE3F2FD),
        ),
        _StatCard(
          stream: db.collection('users').where('role', isEqualTo: 'volunteer').snapshots(),
          label: 'Volunteers',
          icon: Icons.groups_rounded,
          color: const Color(0xFF6A1B9A),
          lightColor: const Color(0xFFF3E5F5),
        ),
        _StatCard(
          stream: db.collection('donations').snapshots(),
          label: 'Total Donations',
          icon: Icons.volunteer_activism_rounded,
          color: const Color(0xFF1B6B3A),
          lightColor: const Color(0xFFE8F5E9),
        ),
        _StatCard(
          stream: db.collection('donations').where('status', isEqualTo: 'pending').snapshots(),
          label: 'Pending',
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFE65100),
          lightColor: const Color(0xFFFFF3E0),
          isAlert: true,
        ),
        _StatCard(
          stream: db.collection('campaigns').where('isActive', isEqualTo: true).snapshots(),
          label: 'Campaigns',
          icon: Icons.campaign_rounded,
          color: const Color(0xFF00838F),
          lightColor: const Color(0xFFE0F7FA),
        ),
        _StatCard(
          stream: db.collection('users').where('role', isEqualTo: 'volunteer').where('isOnline', isEqualTo: true).snapshots(),
          label: 'Online Now',
          icon: Icons.online_prediction_rounded,
          color: const Color(0xFF2E7D32),
          lightColor: const Color(0xFFE8F5E9),
        ),
      ],
    );
  }
}

// ==========================================================================
// STAT CARD
// ==========================================================================
class _StatCard extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final bool isAlert;

  const _StatCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
    required this.lightColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          snapshot.connectionState == ConnectionState.waiting ? '—' : '$count',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (isAlert && count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================================
// QUICK ACTIONS
// ==========================================================================
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          label: 'Add Campaign',
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF1B6B3A),
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          label: 'Add Event',
          icon: Icons.event_available_rounded,
          color: const Color(0xFF1565C0),
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          label: 'Inventory',
          icon: Icons.inventory_rounded,
          color: const Color(0xFF6A1B9A),
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// RECENT ACTIVITY
// ==========================================================================
class _RecentActivity extends StatelessWidget {
  final FirebaseFirestore db;
  const _RecentActivity({required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Donations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Latest 3',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('donations')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B6B3A),
                      strokeWidth: 2,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No donations yet',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String type = data['type'] ?? 'resource';
                    final String status = data['status'] ?? 'pending';
                    final bool isFund = type == 'fund';

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFund
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isFund
                              ? Icons.payments_rounded
                              : Icons.inventory_2_rounded,
                          size: 18,
                          color: isFund
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF1B6B3A),
                        ),
                      ),
                      title: Text(
                        isFund
                            ? 'Rs. ${data['amount'] ?? '0'}'
                            : (data['itemName'] ?? 'Resource'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        data['userEmail'] ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      trailing: _StatusBadge(status: status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// STATUS BADGE
// ==========================================================================
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green[700]!;
        bgColor = Colors.green[50]!;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red[700]!;
        bgColor = Colors.red[50]!;
        label = 'Rejected';
        break;
      case 'completed':
        color = const Color(0xFF1565C0);
        bgColor = const Color(0xFFE3F2FD);
        label = 'Completed';
        break;
      default:
        color = Colors.orange[700]!;
        bgColor = Colors.orange[50]!;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}