import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_nav_controller.dart';
import '../screens/admin_donors_list_screen.dart';
import '../screens/admin_volunteers_list_screen.dart';
import '../screens/admin_donations_list_screen.dart';
import '../screens/admin_donation_details_screen.dart';
import '../screens/admin_online_volunteers_screen.dart'; // NEW

class AdminHomeTabWeb extends StatelessWidget {
  const AdminHomeTabWeb({super.key});

  static const Color _green = Color(0xFF1B6B3A);

  bool _isApprovedVolunteer(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final stage = (data['verificationStage'] ?? '').toString().trim().toLowerCase();
    return stage == 'verified' || status == 'approved' || status == 'verified' || status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                stream: db.collection('users').where('role', isEqualTo: 'donor').snapshots(),
                label: 'Total Donors', icon: Icons.favorite_rounded,
                color: const Color(0xFF1565C0), lightColor: const Color(0xFFE3F2FD),
                onTap: () => Get.to(() => const AdminDonorsListScreen(), transition: Transition.rightToLeft),
              ),
              _StatCard(
                stream: db.collection('users').where('role', isEqualTo: 'volunteer').snapshots(),
                countFilter: _isApprovedVolunteer,
                label: 'Volunteers', icon: Icons.groups_rounded,
                color: const Color(0xFF6A1B9A), lightColor: const Color(0xFFF3E5F5),
                onTap: () => Get.to(() => const AdminVolunteersListScreen(), transition: Transition.rightToLeft),
              ),
              _StatCard(
                stream: db.collection('donations').snapshots(),
                countFilter: (data) {                                    // ADD
                  final s = (data['status'] ?? '').toString().trim().toLowerCase();
                  return s == 'approved' || s == 'completed' || s == 'complete';
                },
                label: 'Total Donations', icon: Icons.volunteer_activism_rounded,
                color: const Color(0xFF1B6B3A), lightColor: const Color(0xFFE8F5E9),
                onTap: () => Get.to(() => const AdminDonationsListScreen(
                  mode: AdminDonationsListMode.approvedAndCompleted, title: 'Approved & Completed',
                ), transition: Transition.rightToLeft),
              ),
              _StatCard(
                stream: db.collection('donations').where('status', isEqualTo: 'pending').snapshots(),
                label: 'Pending', icon: Icons.pending_actions_rounded,
                color: const Color(0xFFE65100), lightColor: const Color(0xFFFFF3E0), isAlert: true,
                onTap: () => Get.to(() => const AdminDonationsListScreen(
                  mode: AdminDonationsListMode.pending, title: 'Pending Donations',
                ), transition: Transition.rightToLeft),
              ),
              _StatCard(
                stream: db.collection('campaigns').where('isActive', isEqualTo: true).snapshots(),
                label: 'Campaigns', icon: Icons.campaign_rounded,
                color: const Color(0xFF00838F), lightColor: const Color(0xFFE0F7FA),
                onTap: () => Get.find<AdminNavController>().openCampaignsEventsTab(0),
              ),
              _StatCard(
                stream: db.collection('users').where('role', isEqualTo: 'volunteer').where('isOnline', isEqualTo: true).snapshots(),
                countFilter: _isApprovedVolunteer,
                label: 'Online Now', icon: Icons.online_prediction_rounded,
                color: const Color(0xFF2E7D32), lightColor: const Color(0xFFE8F5E9),
                onTap: () => Get.to(() => const AdminOnlineVolunteersScreen(), transition: Transition.rightToLeft),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _ActionBtn(label: 'Add Campaign', icon: Icons.add_circle_outline_rounded, color: const Color(0xFF1B6B3A), onTap: () => Get.find<AdminNavController>().openCampaignsEventsTab(0))),
              const SizedBox(width: 12),
              Expanded(child: _ActionBtn(label: 'Add Event', icon: Icons.event_available_rounded, color: const Color(0xFF1565C0), onTap: () => Get.find<AdminNavController>().openCampaignsEventsTab(1))),
              const SizedBox(width: 12),
              Expanded(child: _ActionBtn(label: 'Inventory', icon: Icons.inventory_rounded, color: const Color(0xFF6A1B9A), onTap: () => Get.find<AdminNavController>().changeTab(2))),
            ],
          ),
          const SizedBox(height: 20),
          _RecentDonationsCard(db: db),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final bool isAlert;
  final VoidCallback? onTap;
  final bool Function(Map<String, dynamic>)? countFilter;

  const _StatCard({
    required this.stream, required this.label, required this.icon,
    required this.color, required this.lightColor, this.isAlert = false,
    this.onTap, this.countFilter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = countFilter == null
              ? snapshot.data!.docs.length
              : snapshot.data!.docs.where((d) => countFilter!(d.data() as Map<String, dynamic>)).length;
        }
        return GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Text(snapshot.connectionState == ConnectionState.waiting ? '—' : '$count',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: color)),
                          if (isAlert && count > 0) ...[
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _RecentDonationsCard extends StatelessWidget {
  final FirebaseFirestore db;
  const _RecentDonationsCard({required this.db});

  bool _isFund(Map<String, dynamic> data) =>
      data['type'] == 'fund' || data.containsKey('amount') || data.containsKey('paymentProofUrl');

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
          Padding(
            // CHANGED — more breathing room, matching the stat cards' padding scale
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Donations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), // CHANGED — 15 -> 17
              Text('Latest 3', style: TextStyle(fontSize: 12.5, color: Colors.grey[500])), // CHANGED — 11 -> 12.5
            ]),
          ),
          const Divider(height: 1),
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('donations').orderBy('createdAt', descending: true).limit(3).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No donations yet', style: TextStyle(color: Colors.grey[400], fontSize: 14))));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isFund = _isFund(data);
                  return MouseRegion( // NEW — web affordance, matches the stat cards' clickable feel
                    cursor: SystemMouseCursors.click,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6), // CHANGED — was default (~16)
                      onTap: () => Get.to(() => AdminDonationDetailsScreen(donationId: doc.id, initialData: data), transition: Transition.rightToLeft),
                      leading: Container(
                        width: 46, height: 46, // CHANGED — was 36x36, now matches the stat card icon size
                        decoration: BoxDecoration(
                          color: isFund ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12), // CHANGED — was 10, matches stat cards' 12
                        ),
                        child: Icon(isFund ? Icons.payments_rounded : Icons.inventory_2_rounded, size: 22, // CHANGED — was 18
                            color: isFund ? const Color(0xFF1565C0) : const Color(0xFF1B6B3A)),
                      ),
                      title: Text(isFund ? 'Rs. ${data['verifiedAmount'] ?? data['amount'] ?? '0'}' : (data['itemName'] ?? 'Resource'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), // CHANGED — 13 -> 15
                      subtitle: Text(data['donorName'] ?? data['userEmail'] ?? data['donorEmail'] ?? '', style: TextStyle(fontSize: 12.5, color: Colors.grey[500])), // CHANGED — 11 -> 12.5
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}