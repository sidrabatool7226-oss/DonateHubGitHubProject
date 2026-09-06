import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/financial_summary_controller.dart';

class FinancialSummaryScreen extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const FinancialSummaryScreen({
    super.key,
    this.primaryColor = const Color(0xFF0F6E4F),
    this.secondaryColor = const Color(0xFF2FBF87),
  });

  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinancialSummaryController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Available Funds Hero Card ─────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text('Available Funds',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Rs. ${controller.availableFunds.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'From ${controller.totalDonorsCount.value} donors · ${controller.totalTransactions.value} transactions',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Received / Utilized Split ──────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SplitCard(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Total Received',
                              value: controller.totalReceived.value,
                              color: primaryColor,
                              bg: const Color(0xFFE6F5EE),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SplitCard(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Total Utilized',
                              value: controller.totalUtilized.value,
                              color: const Color(0xFFDB7C26),
                              bg: const Color(0xFFFFF3E4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Progress bar visual ─────────────────────
                      _UtilizationBar(controller: controller, color: primaryColor),
                      const SizedBox(height: 20),

                      // ── Recent Donations ─────────────────────────
                      _SectionHeader(
                          title: 'Recent Fund Donations',
                          icon: Icons.payments_outlined,
                          color: primaryColor),
                      const SizedBox(height: 10),
                      _RecentDonationsList(controller: controller, color: primaryColor),
                      const SizedBox(height: 20),

                      // ── Recent Utilization ───────────────────────
                      _SectionHeader(
                          title: 'Recent Utilization',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFFDB7C26)),
                      const SizedBox(height: 10),
                      _RecentUtilizationList(controller: controller),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// SPLIT CARD (Received / Utilized)
// ==========================================================================
class _SplitCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final Color bg;

  const _SplitCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10.5, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ==========================================================================
// UTILIZATION PROGRESS BAR
// ==========================================================================
class _UtilizationBar extends StatelessWidget {
  final FinancialSummaryController controller;
  final Color color;
  const _UtilizationBar({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    final received = controller.totalReceived.value;
    final utilized = controller.totalUtilized.value;
    final ratio = received > 0 ? (utilized / received).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Funds Utilization Rate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$percent%',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: const Color(0xFFE6F5EE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SECTION HEADER
// ==========================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF14251E))),
      ],
    );
  }
}

// ==========================================================================
// RECENT DONATIONS LIST
// ==========================================================================
class _RecentDonationsList extends StatelessWidget {
  final FinancialSummaryController controller;
  final Color color;
  const _RecentDonationsList({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    final list = controller.recentDonations;

    if (list.isEmpty) {
      return _EmptyRow(text: 'No fund donations yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: list.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_downward_rounded, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['donorEmail'],
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${item['method']} · ${controller.timeAgo(item['createdAt'])}',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text('+ Rs. ${(item['amount'] as double).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================================================
// RECENT UTILIZATION LIST
// ==========================================================================
class _RecentUtilizationList extends StatelessWidget {
  final FinancialSummaryController controller;
  const _RecentUtilizationList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final list = controller.recentUtilizations;

    if (list.isEmpty) {
      return _EmptyRow(text: 'No utilization records yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: list.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded,
                      color: Color(0xFFDB7C26), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['campaignName'],
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(controller.timeAgo(item['createdAt']),
                          style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Text('- Rs. ${(item['amount'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFDB7C26))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.grey[400])),
      ),
    );
  }
}