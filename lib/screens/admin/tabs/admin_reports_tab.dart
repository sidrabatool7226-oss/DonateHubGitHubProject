import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart' show AxisTitles, BarChart, BarChartAlignment, BarChartData, BarChartGroupData, BarChartRodData, BarTooltipItem, BarTouchData, BarTouchTooltipData, FlBorderData, FlGridData, FlLine, FlTitlesData, PieChart, PieChartData, PieChartSectionData, SideTitles;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/reports_controller.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);


  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportsController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            _Header(controller: controller),

            // ── Report Tabs ──────────────────────────────────────────
            _ReportTabBar(controller: controller),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                // Explicit reads — GetX ko pata chale kya track karna hai
                final loading = controller.isLoading.value;
                final activeTab = controller.selectedReportTab.value;

                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }

                return IndexedStack(
                  index: activeTab,
                  children: [
                    _DonationReport(controller: controller),
                    _FinancialReport(controller: controller),
                    _VolunteerReport(controller: controller),
                    _CampaignInventoryReport(controller: controller),
                  ],
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
// HEADER
// ==========================================================================
class _Header extends StatelessWidget {
  final ReportsController controller;
  const _Header({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Reports & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          Obx(() {
            final selected = controller.selectedFilter.value; // ✅ Explicit read yahan
            return SizedBox(
              height: 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.filters.map((filter) {
                    final isSelected = selected == filter;
                    return GestureDetector(
                      onTap: () => controller.changeFilter(filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? _green : Colors.white,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==========================================================================
// REPORT TAB BAR
// ==========================================================================
class _ReportTabBar extends StatelessWidget {
  final ReportsController controller;
  const _ReportTabBar({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Donations', 'icon': Icons.volunteer_activism_rounded},
    {'label': 'Financial', 'icon': Icons.payments_rounded},
    {'label': 'Volunteers', 'icon': Icons.groups_rounded},
    {'label': 'Campaigns', 'icon': Icons.campaign_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() => Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected =
              controller.selectedReportTab.value == index;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
              controller.selectedReportTab.value = index,
              child: Column(
                children: [
                  Icon(
                    _tabs[index]['icon'],
                    size: 20,
                    color: isSelected ? _green : Colors.grey[400],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _tabs[index]['label'],
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? _green : Colors.grey[400],
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _green
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      )),
    );
  }
}

// ==========================================================================
// DONATION REPORT
// ==========================================================================
class _DonationReport extends StatelessWidget {
  final ReportsController controller;
  const _DonationReport({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Summary cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SummaryCard(
                label: 'Total',
                value: '${controller.totalDonations.value}',
                icon: Icons.volunteer_activism_rounded,
                color: _green,
                bg: const Color(0xFFE8F5E9),
              ),
              _SummaryCard(
                label: 'Approved',
                value: '${controller.approvedDonations.value}',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green[700]!,
                bg: Colors.green[50]!,
              ),
              _SummaryCard(
                label: 'Pending',
                value: '${controller.pendingDonations.value}',
                icon: Icons.pending_outlined,
                color: Colors.orange[700]!,
                bg: Colors.orange[50]!,
              ),
              _SummaryCard(
                label: 'Rejected',
                value: '${controller.rejectedDonations.value}',
                icon: Icons.cancel_outlined,
                color: Colors.red[700]!,
                bg: Colors.red[50]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type breakdown
          _SectionCard(
            title: 'Donation Types',
            icon: Icons.pie_chart_outline_rounded,
            child: Column(
              children: [
                _ProgressRow(
                  label: 'Fund Donations',
                  value: controller.fundDonations.value,
                  total: controller.totalDonations.value,
                  color: _green,
                ),
                const SizedBox(height: 12),
                _ProgressRow(
                  label: 'Resource Donations',
                  value: controller.resourceDonations.value,
                  total: controller.totalDonations.value,
                  color: const Color(0xFF00838F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status pie chart
          if (controller.totalDonations.value > 0)
            _SectionCard(
              title: 'Status Overview',
              icon: Icons.donut_large_rounded,
              child: SizedBox(
                height: 180,
                child: _DonationPieChart(
                    data: controller.statusChartData),
              ),
            ),
          const SizedBox(height: 16),

          // Recent donations list
          _SectionCard(
            title: 'Recent Donations',
            icon: Icons.history_rounded,
            child: _RecentDonationsList(),
          ),
        ],
      )),
    );
  }
}

// ==========================================================================
// FINANCIAL REPORT
// ==========================================================================
class _FinancialReport extends StatelessWidget {
  final ReportsController controller;
  const _FinancialReport({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Total funds card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B6B3A), Color(0xFF2D8A52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Funds Collected',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${controller.totalFundsCollected.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From approved fund donations',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly bar chart
          _SectionCard(
            title: 'Monthly Funds Trend',
            icon: Icons.show_chart_rounded,
            child: SizedBox(
              height: 200,
              child: controller.monthlyFunds.isEmpty
                  ? Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              )
                  : _MonthlyBarChart(
                  data: controller.monthlyFunds),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Donors',
                  value: '${controller.totalDonors.value}',
                  icon: Icons.people_outline_rounded,
                  color: _green,
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Active Donors',
                  value: '${controller.activeDonors.value}',
                  icon: Icons.favorite_outline_rounded,
                  color: Colors.green[700]!,
                  bg: Colors.green[50]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fund donations list
          _SectionCard(
            title: 'Fund Donation Details',
            icon: Icons.receipt_long_outlined,
            child: _FundDonationsList(),
          ),
        ],
      )),
    );
  }
}

// ==========================================================================
// VOLUNTEER REPORT
// ==========================================================================
class _VolunteerReport extends StatelessWidget {
  final ReportsController controller;
  const _VolunteerReport({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SummaryCard(
                label: 'Total',
                value: '${controller.totalVolunteers.value}',
                icon: Icons.groups_rounded,
                color: _green,
                bg: const Color(0xFFE8F5E9),
              ),
              _SummaryCard(
                label: 'Verified',
                value: '${controller.verifiedVolunteers.value}',
                icon: Icons.verified_outlined,
                color: Colors.green[700]!,
                bg: Colors.green[50]!,
              ),
              _SummaryCard(
                label: 'Tasks Done',
                value: '${controller.completedTasks.value}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF00838F),
                bg: const Color(0xFFE0F7FA),
              ),
              _SummaryCard(
                label: 'Active Tasks',
                value: '${controller.pendingTasks.value}',
                icon: Icons.pending_actions_rounded,
                color: Colors.orange[700]!,
                bg: Colors.orange[50]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Verification progress
          _SectionCard(
            title: 'Verification Status',
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                _ProgressRow(
                  label: 'Verified Volunteers',
                  value: controller.verifiedVolunteers.value,
                  total: controller.totalVolunteers.value,
                  color: _green,
                ),
                const SizedBox(height: 12),
                _ProgressRow(
                  label: 'Task Completion Rate',
                  value: controller.completedTasks.value,
                  total: controller.completedTasks.value +
                      controller.pendingTasks.value,
                  color: const Color(0xFF00838F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Volunteer list
          _SectionCard(
            title: 'Volunteer Details',
            icon: Icons.list_alt_rounded,
            child: _VolunteerList(),
          ),
        ],
      )),
    );
  }
}

// ==========================================================================
// CAMPAIGN + INVENTORY REPORT
// ==========================================================================
class _CampaignInventoryReport extends StatelessWidget {
  final ReportsController controller;
  const _CampaignInventoryReport({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Campaign stats
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Campaigns',
                  value: '${controller.totalCampaigns.value}',
                  icon: Icons.campaign_rounded,
                  color: _green,
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Active',
                  value: '${controller.activeCampaigns.value}',
                  icon: Icons.play_circle_outline_rounded,
                  color: Colors.green[700]!,
                  bg: Colors.green[50]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inventory stats
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Inventory',
                  value: '${controller.totalInventoryItems.value}',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF00838F),
                  bg: const Color(0xFFE0F7FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Urgent Items',
                  value: '${controller.urgentItems.value}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red[700]!,
                  bg: Colors.red[50]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campaign list
          _SectionCard(
            title: 'Campaigns Overview',
            icon: Icons.campaign_outlined,
            child: _CampaignReportList(),
          ),
          const SizedBox(height: 16),

          // Inventory report
          _SectionCard(
            title: 'Inventory Overview',
            icon: Icons.inventory_outlined,
            child: _InventoryReportList(),
          ),
        ],
      )),
    );
  }
}

// ==========================================================================
// DONATION PIE CHART
// ==========================================================================
class _DonationPieChart extends StatelessWidget {
  final RxList<Map<String, dynamic>> data;
  const _DonationPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = data
        .where((d) => (d['value'] as double) > 0)
        .map((d) => PieChartSectionData(
      value: d['value'],
      color: d['color'],
      title:
      '${(d['value'] as double).toInt()}',
      radius: 55,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ))
        .toList();

    if (sections.isEmpty) {
      return Center(
        child: Text('No data', style: TextStyle(color: Colors.grey[400])),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 35,
              sectionsSpace: 2,
            ),
          ),
        ),
        // Legend
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data
              .where((d) => (d['value'] as double) > 0)
              .map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: d['color'],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  d['label'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ))
              .toList(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ==========================================================================
// MONTHLY BAR CHART
// ==========================================================================
class _MonthlyBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _MonthlyBarChart({required this.data});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxVal = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce(
            (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _green.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Rs. ${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= entries.length) {
                  return const SizedBox();
                }
                return Text(
                  entries[value.toInt()].key,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(entries.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entries[index].value,
                color: _green,
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ==========================================================================
// RECENT DONATIONS LIST
// ==========================================================================
class _RecentDonationsList extends StatelessWidget {
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No donations found',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'resource';
            final status = data['status'] ?? 'pending';
            final isFund = type == 'fund';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isFund
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isFund
                          ? Icons.payments_outlined
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: isFund ? _green : const Color(0xFF00838F),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFund
                              ? 'Fund — Rs. ${data['amount'] ?? 0}'
                              : 'Resource — ${data['itemName'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data['userEmail'] ?? data['donorEmail'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================================================
// FUND DONATIONS LIST
// ==========================================================================
class _FundDonationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('type', isEqualTo: 'fund')
          .where('status', whereIn: ['approved', 'completed'])
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No approved fund donations yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: Color(0xFF1B6B3A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data['userEmail'] ??
                          data['donorEmail'] ??
                          'Donor',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    'Rs. ${data['amount'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B6B3A),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================================================
// VOLUNTEER LIST
// ==========================================================================
class _VolunteerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No volunteers yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stage = data['verificationStage'] ?? 'Pending';
            final isVerified = stage == 'Verified';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      (data['name'] ?? 'V')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF1B6B3A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Volunteer',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data['email'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVerified ? 'Verified' : stage,
                      style: TextStyle(
                        fontSize: 10,
                        color: isVerified
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================================================
// CAMPAIGN REPORT LIST
// ==========================================================================
class _CampaignReportList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No campaigns yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final double goal =
            (data['goalAmount'] ?? 0).toDouble();
            final double collected =
            (data['collectedAmount'] ?? 0).toDouble();
            final double progress =
            goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (data['isActive'] ?? false)
                              ? Colors.green[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (data['isActive'] ?? false)
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            color: (data['isActive'] ?? false)
                                ? Colors.green[700]
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${collected.toStringAsFixed(0)} / Rs. ${goal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B6B3A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B6B3A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B6B3A)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================================================
// INVENTORY REPORT LIST
// ==========================================================================
class _InventoryReportList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No inventory items yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool isUrgent = data['isUrgent'] ?? false;
            final int qty = data['quantity'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
                border: isUrgent
                    ? Border.all(color: Colors.red[200]!, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: isUrgent
                        ? Colors.red[700]
                        : const Color(0xFF1B6B3A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['itemName'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data['category'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty: $qty',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: qty <= 5
                              ? Colors.red[700]
                              : const Color(0xFF1B6B3A),
                        ),
                      ),
                      if (isUrgent)
                        Text(
                          '⚡ Urgent',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ==========================================================================
// REUSABLE WIDGETS
// ==========================================================================
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color _green = Color(0xFF1B6B3A);

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
    total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value / $total ($percent%)',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;

    switch (status) {
      case 'approved':
      case 'completed':
        color = Colors.green[700]!;
        bg = Colors.green[50]!;
        break;
      case 'rejected':
        color = Colors.red[700]!;
        bg = Colors.red[50]!;
        break;
      default:
        color = Colors.orange[700]!;
        bg = Colors.orange[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}