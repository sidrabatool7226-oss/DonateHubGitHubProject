import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/manager_home_controller.dart';
import '../screens/manager_volunteers_list_screen.dart';
import '../screens/manager_donations_list_screen.dart';
import '../tabs/manager_tasks_tab.dart';
import '../screens/fund_donation_detail_screen.dart';
import '../screens/resource_donation_detail_screen.dart';
import '../screens/manager_campaigns_screen.dart';

class ManagerHomeTab extends StatelessWidget {
  const ManagerHomeTab({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerHomeController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(controller: controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  children: [
                    _StatsGrid(controller: controller),
                    const SizedBox(height: 12),
                    _CampaignsButton(controller: controller),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _RecentActivityCard(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// HEADER
// ==========================================================================

class _Header extends StatelessWidget {
  final ManagerHomeController controller;

  const _Header({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_emerald, _mint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Obx(
            () => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.managerName.value.isEmpty
                        ? 'Manager'
                        : controller.managerName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// STATS GRID
// ==========================================================================

class _StatsGrid extends StatelessWidget {
  final ManagerHomeController controller;

  const _StatsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard(
            icon: Icons.person_search_rounded,
            label: 'Pending Volunteers',
            value: '${controller.pendingVolunteers.value}',
            color: const Color(0xFFDB7C26),
            bg: const Color(0xFFFFF3E4),
            onTap: () => Get.to(
                  () => const ManagerVolunteersListScreen(),
              transition: Transition.rightToLeft,
            ),
          ),
          _StatCard(
            icon: Icons.volunteer_activism_rounded,
            label: 'Pending Donations',
            value: '${controller.pendingDonations.value}',
            color: const Color(0xFFC0392B),
            bg: const Color(0xFFFCEBEA),
            onTap: () => Get.to(
                  () => const ManagerDonationsListScreen(),
              transition: Transition.rightToLeft,
            ),
          ),
          _StatCard(
            icon: Icons.assignment_rounded,
            label: 'Active Tasks',
            value: '${controller.activeTasks.value}',
            color: const Color(0xFF0F6E4F),
            bg: const Color(0xFFE6F5EE),
            onTap: () => Get.to(
                  () => const ManagerTasksTab(),
              transition: Transition.rightToLeft,
            ),
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed Today',
            value: '${controller.completedToday.value}',
            color: const Color(0xFF2FBF87),
            bg: const Color(0xFFE6F9F1),
            onTap: () => Get.to(
                  () => const ManagerTasksTab(),
              transition: Transition.rightToLeft,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14251E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// RECENT ACTIVITY
// ==========================================================================

class _RecentActivityCard extends StatelessWidget {
  final ManagerHomeController controller;

  const _RecentActivityCard({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  bool _isFund(Map<String, dynamic> data) {
    return data['type'] == 'fund' ||
        data.containsKey('amount') ||
        data.containsKey('verifiedAmount') ||
        data.containsKey('paymentProofUrl') ||
        data.containsKey('proofUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14251E),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _emerald,
                    strokeWidth: 2,
                  ),
                );
              }

              final items = controller.recentActivity;

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No recent activity yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 58,
                ),
                itemBuilder: (context, index) {
                  final item = Map<String, dynamic>.from(items[index]);

                  final bool isFund = _isFund(item);
                  final String status =
                  (item['status'] ?? 'pending').toString();

                  return GestureDetector(
                    onTap: () {
                      final docId = (item['id'] ?? '').toString();

                      if (docId.isEmpty) return;

                      if (isFund) {
                        Get.to(
                              () => FundDonationDetailScreen(
                            docId: docId,
                            data: item,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      } else {
                        Get.to(
                              () => ResourceDonationDetailScreen(
                            docId: docId,
                            data: item,
                          ),
                          transition: Transition.rightToLeft,
                        );
                      }
                    },
                    child: _ActivityTile(
                      icon: isFund
                          ? Icons.payments_rounded
                          : Icons.inventory_2_rounded,
                      iconBg: isFund
                          ? const Color(0xFFE6F5EE)
                          : const Color(0xFFFFF3E4),
                      iconColor: isFund
                          ? const Color(0xFF0F6E4F)
                          : const Color(0xFFDB7C26),
                      title: isFund
                          ? 'Fund donation — Rs. ${item['verifiedAmount'] ?? item['amount'] ?? 0}'
                          : 'Resource — ${item['itemName'] ?? 'Item'}',
                      subtitle:
                      '${item['userEmail'] ?? item['donorEmail'] ?? item['donorName'] ?? 'Donor'}',
                      time: controller.timeAgo(item['createdAt']),
                      status: status,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final String status;

  const _ActivityTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusLabel;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF1565C0);
        statusBg = const Color(0xFFE3F2FD);
        statusLabel = 'Approved';
        break;

      case 'completed':
        statusColor = const Color(0xFF0F6E4F);
        statusBg = const Color(0xFFE6F5EE);
        statusLabel = 'Completed';
        break;

      case 'rejected':
        statusColor = const Color(0xFFC0392B);
        statusBg = const Color(0xFFFCEBEA);
        statusLabel = 'Rejected';
        break;

      case 'pickup_assigned':
        statusColor = const Color(0xFF1565C0);
        statusBg = const Color(0xFFE3F2FD);
        statusLabel = 'Pickup Assigned';
        break;

      default:
        statusColor = const Color(0xFFDB7C26);
        statusBg = const Color(0xFFFFF3E4);
        statusLabel = 'Pending';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14251E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle · $time',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 9.5,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CAMPAIGNS
// ==========================================================================

class _CampaignsButton extends StatelessWidget {
  final ManagerHomeController controller;

  const _CampaignsButton({
    required this.controller,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
              () => const ManagerCampaignsScreen(),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('campaigns')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            double totalCollected = 0;

            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalCollected += _number(data['collectedAmount']);
              }
            }

            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EE),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: _emerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campaigns',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14251E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Collected: Rs. ${totalCollected.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                      () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F9F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.activeCampaigns.value} Active',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _emerald,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _mint,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}