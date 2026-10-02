import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_home_controller.dart';
import '../screens/manager_volunteers_list_screen.dart';
import '../screens/manager_donations_list_screen.dart';
import '../tabs/manager_tasks_tab.dart';
import '../screens/fund_donation_detail_screen.dart';
import '../screens/resource_donation_detail_screen.dart';
import '../screens/manager_campaigns_screen.dart'; // FIXED (Bug 8) — was only reachable from the mobile Home tab
import '../screens/general_fund_screen.dart'; // FIXED (Bug 8) — was only reachable from the mobile Home tab
import '../../shared/financial_summary_screen.dart'; // FIXED (Bug 8) — screen existed but nothing linked to it

class ManagerHomeTabWeb extends StatelessWidget {
  final VoidCallback? onGoToActiveTasks; // NEW
  final VoidCallback? onGoToCompletedTasks; // NEW — opens Tasks page on its "Completed" section
  const ManagerHomeTabWeb({super.key, this.onGoToActiveTasks, this.onGoToCompletedTasks});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerHomeController());

    // Stat cards and quick-access cards are a fixed grid that spans the full
    // width of the page: 4 / 3 across on desktop, 2 on tablet, 1 on a narrow
    // window. Each card is sized from the available width so nothing is left empty.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        const double gap = 22;
        final int statCols = w >= 900 ? 4 : (w >= 560 ? 2 : 1);
        final int actionCols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
        final double statW = ((w - gap * (statCols - 1)) / statCols).floorToDouble();
        final double actionW = ((w - gap * (actionCols - 1)) / actionCols).floorToDouble();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Overview'),
              Obx(() => Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _StatCard(width: statW, icon: Icons.person_search_rounded, label: 'Pending Volunteers',
                      value: '${controller.pendingVolunteers.value}', color: const Color(0xFFDB7C26),
                      onTap: () => Get.to(() => const ManagerVolunteersListScreen(), transition: Transition.rightToLeft)),
                  _StatCard(width: statW, icon: Icons.volunteer_activism_rounded, label: 'Pending Donations',
                      value: '${controller.pendingDonations.value}', color: const Color(0xFFC0392B),
                      onTap: () => Get.to(() => const ManagerDonationsListScreen(), transition: Transition.rightToLeft)),
                  _StatCard(width: statW, icon: Icons.assignment_rounded, label: 'Active Tasks',
                      value: '${controller.activeTasks.value}', color: const Color(0xFF0F6E4F),
                      onTap: () {
                        if (onGoToActiveTasks != null) {
                          onGoToActiveTasks!();
                        } else {
                          Get.to(() => const ManagerTasksTab(), transition: Transition.rightToLeft);
                        }
                      }),
                  _StatCard(width: statW, icon: Icons.check_circle_rounded, label: 'Completed Today',
                      value: '${controller.completedToday.value}', color: const Color(0xFF2FBF87),
                      onTap: () {
                        // CHANGED — opens the Tasks page on its "Completed" section
                        if (onGoToCompletedTasks != null) {
                          onGoToCompletedTasks!();
                        } else {
                          Get.to(() => const ManagerTasksTab(), transition: Transition.rightToLeft);
                        }
                      }),
                ],
              )),
              const SizedBox(height: 32),
              // FIXED (Bug 8) — Campaigns and General Fund exist on the mobile Home tab but had
              // no way in on web; Financial Summary had no entry point anywhere.
              const _SectionTitle('Quick Access'),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _ActionCard(width: actionW, icon: Icons.campaign_rounded, label: 'Campaigns',
                      hint: 'Browse and track campaigns', color: const Color(0xFF0F6E4F),
                      onTap: () => Get.to(() => const ManagerCampaignsScreen(), transition: Transition.rightToLeft)),
                  _ActionCard(width: actionW, icon: Icons.account_balance_wallet_rounded, label: 'General Fund',
                      hint: 'Fund balance and allocations', color: const Color(0xFF1565C0),
                      onTap: () => Get.to(() => const GeneralFundScreen(), transition: Transition.rightToLeft)),
                  _ActionCard(width: actionW, icon: Icons.bar_chart_rounded, label: 'Financial Summary',
                      hint: 'Income and spending overview', color: const Color(0xFFDB7C26),
                      onTap: () => Get.to(() => const FinancialSummaryScreen(), transition: Transition.rightToLeft)),
                ],
              ),
              const SizedBox(height: 32),
              _RecentActivityCard(controller: controller),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================================
// SHARED PIECES
// ==========================================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 2),
      child: Text(text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: 0.2)),
    );
  }
}

/// White rounded card with a soft shadow that lifts slightly on hover (web).
class _HoverCard extends StatefulWidget {
  final double width;
  final double height;
  final Color accent;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget child;

  const _HoverCard({
    required this.width,
    required this.height,
    required this.accent,
    required this.onTap,
    required this.padding,
    required this.child,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.accent.withOpacity(_hover ? 0.35 : 0.10)),
            boxShadow: [
              BoxShadow(
                color: _hover ? widget.accent.withOpacity(0.16) : Colors.black.withOpacity(0.05),
                blurRadius: _hover ? 26 : 14,
                offset: Offset(0, _hover ? 12 : 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  const _IconTile({required this.icon, required this.color, required this.size, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.28)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 7))],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width; // computed by the grid
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({required this.width, required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      width: width,
      height: 150,
      accent: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Row(children: [
        _IconTile(icon: icon, color: color, size: 78, iconSize: 40),
        const SizedBox(width: 22),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: color, height: 1.05)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 22),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.width, required this.icon, required this.label, required this.hint, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      width: width,
      height: 112,
      accent: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(children: [
        _IconTile(icon: icon, color: color, size: 62, iconSize: 32),
        const SizedBox(width: 18),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 26),
      ]),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final ManagerHomeController controller;
  const _RecentActivityCard({required this.controller});

  bool _isFund(Map<String, dynamic> data) =>
      data['type'] == 'fund' || data.containsKey('amount') || data.containsKey('verifiedAmount') ||
          data.containsKey('paymentProofUrl') || data.containsKey('proofUrl');

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'complete':
      case 'delivered':
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFC62828);
      case 'pending':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(28, 24, 28, 18),
              child: Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          const Divider(height: 1),
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final items = controller.recentActivity;
            if (items.isEmpty) {
              return Padding(padding: const EdgeInsets.all(48), child: Center(child: Text('No recent activity yet', style: TextStyle(color: Colors.grey[400], fontSize: 15))));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 96),
              itemBuilder: (context, index) {
                final item = Map<String, dynamic>.from(items[index]);
                final isFund = _isFund(item);
                final status = (item['status'] ?? 'pending').toString();
                final statusColor = _statusColor(status);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  hoverColor: const Color(0xFFF4F8F6),
                  onTap: () {
                    final docId = (item['id'] ?? '').toString();
                    if (docId.isEmpty) return;
                    if (isFund) {
                      Get.to(() => FundDonationDetailScreen(docId: docId, data: item), transition: Transition.rightToLeft);
                    } else {
                      Get.to(() => ResourceDonationDetailScreen(docId: docId, data: item), transition: Transition.rightToLeft);
                    }
                  },
                  leading: _IconTile(
                    icon: isFund ? Icons.payments_rounded : Icons.inventory_2_rounded,
                    color: isFund ? const Color(0xFF0F6E4F) : const Color(0xFFDB7C26),
                    size: 52,
                    iconSize: 26,
                  ),
                  title: Text(
                    isFund ? 'Fund donation — Rs. ${item['verifiedAmount'] ?? item['amount'] ?? 0}' : 'Resource — ${item['itemName'] ?? 'Item'}',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('${item['userEmail'] ?? item['donorEmail'] ?? item['donorName'] ?? 'Donor'} · ${controller.timeAgo(item['createdAt'])}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}