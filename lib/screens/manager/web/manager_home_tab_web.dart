import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_home_controller.dart';
import '../screens/manager_volunteers_list_screen.dart';
import '../screens/manager_donations_list_screen.dart';
import '../tabs/manager_tasks_tab.dart';
import '../screens/fund_donation_detail_screen.dart';
import '../screens/resource_donation_detail_screen.dart';

class ManagerHomeTabWeb extends StatelessWidget {
  const ManagerHomeTabWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerHomeController());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(icon: Icons.person_search_rounded, label: 'Pending Volunteers',
                  value: '${controller.pendingVolunteers.value}', color: const Color(0xFFDB7C26), bg: const Color(0xFFFFF3E4),
                  onTap: () => Get.to(() => const ManagerVolunteersListScreen(), transition: Transition.rightToLeft)),
              _StatCard(icon: Icons.volunteer_activism_rounded, label: 'Pending Donations',
                  value: '${controller.pendingDonations.value}', color: const Color(0xFFC0392B), bg: const Color(0xFFFCEBEA),
                  onTap: () => Get.to(() => const ManagerDonationsListScreen(), transition: Transition.rightToLeft)),
              _StatCard(icon: Icons.assignment_rounded, label: 'Active Tasks',
                  value: '${controller.activeTasks.value}', color: const Color(0xFF0F6E4F), bg: const Color(0xFFE6F5EE),
                  onTap: () => Get.to(() => const ManagerTasksTab(), transition: Transition.rightToLeft)),
              _StatCard(icon: Icons.check_circle_rounded, label: 'Completed Today',
                  value: '${controller.completedToday.value}', color: const Color(0xFF2FBF87), bg: const Color(0xFFE6F9F1),
                  onTap: () => Get.to(() => const ManagerTasksTab(), transition: Transition.rightToLeft)),
            ],
          )),
          const SizedBox(height: 20),
          _RecentActivityCard(controller: controller),
          const SizedBox(height: 20),
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

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final ManagerHomeController controller;
  const _RecentActivityCard({required this.controller});

  bool _isFund(Map<String, dynamic> data) =>
      data['type'] == 'fund' || data.containsKey('amount') || data.containsKey('verifiedAmount') ||
          data.containsKey('paymentProofUrl') || data.containsKey('proofUrl');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final items = controller.recentActivity;
            if (items.isEmpty) {
              return Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No recent activity yet', style: TextStyle(color: Colors.grey[400]))));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 58),
              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index]);
                final isFund = _isFund(item);
                final status = (item['status'] ?? 'pending').toString();
                return ListTile(
                  onTap: () {
                    final docId = (item['id'] ?? '').toString();
                    if (docId.isEmpty) return;
                    if (isFund) {
                      Get.to(() => FundDonationDetailScreen(docId: docId, data: item), transition: Transition.rightToLeft);
                    } else {
                      Get.to(() => ResourceDonationDetailScreen(docId: docId, data: item), transition: Transition.rightToLeft);
                    }
                  },
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: isFund ? const Color(0xFFE6F5EE) : const Color(0xFFFFF3E4), borderRadius: BorderRadius.circular(11)),
                    child: Icon(isFund ? Icons.payments_rounded : Icons.inventory_2_rounded, size: 18,
                        color: isFund ? const Color(0xFF0F6E4F) : const Color(0xFFDB7C26)),
                  ),
                  title: Text(
                    isFund ? 'Fund donation — Rs. ${item['verifiedAmount'] ?? item['amount'] ?? 0}' : 'Resource — ${item['itemName'] ?? 'Item'}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${item['userEmail'] ?? item['donorEmail'] ?? item['donorName'] ?? 'Donor'} · ${controller.timeAgo(item['createdAt'])}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  trailing: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}