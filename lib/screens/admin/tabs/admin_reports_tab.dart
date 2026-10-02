import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart' show AxisTitles, BarChart, BarChartAlignment, BarChartData, BarChartGroupData, BarChartRodData, BarTooltipItem, BarTouchData, BarTouchTooltipData, FlBorderData, FlGridData, FlLine, FlTitlesData, PieChart, PieChartData, PieChartSectionData, SideTitles;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/reports_controller.dart';
import '../../../widgets/admin_page_kit.dart';
import '../../../widgets/web_dashboard_shell.dart' show WebFullBleedPage; // NEW — lets the web shell give this page the full width

class AdminReportsTab extends StatelessWidget implements WebFullBleedPage {
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
        // NEW — measure the page once and share it, so every card can pick the compact (phone)
        // or the large (web) size. The scroll view still spans the full width.
        child: LayoutBuilder(
            builder: (context, constraints) => _ReportsLayout(
                width: constraints.maxWidth,
                child: AdminPageScroll(
                  child: Column(
                    children: [
                      // ── Header ───────────────────────────────────────────────
                      _Header(controller: controller),

                      // ── Report Tabs ──────────────────────────────────────────
                      _ReportTabBar(controller: controller),

                      // ── Content ──────────────────────────────────────────────
                      // CHANGED — no Expanded/IndexedStack; only the selected report is
                      // built and the whole page scrolls (AdminPageScroll).
                      // NEW — on very wide screens keep the reports to a readable width, centred
                      Center(child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                          child: Obx(() {
                            // Explicit reads — GetX ko pata chale kya track karna hai
                            final loading = controller.isLoading.value;
                            final activeTab = controller.selectedReportTab.value;

                            if (loading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: CircularProgressIndicator(color: _green),
                                ),
                              );
                            }

                            switch (activeTab) {
                              case 1:
                                return _FinancialReport(controller: controller);
                              case 2:
                                return _VolunteerReport(controller: controller);
                              case 3:
                                return _CampaignInventoryReport(controller: controller);
                              default:
                                return _DonationReport(controller: controller);
                            }
                          }))),
                    ],
                  ),
                ))),
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
    final _ReportsLayout lay = _ReportsLayout.of(context); // NEW
    return Container(
      width: double.infinity,
      // CHANGED — gradient stays full-width, the content inside is centred to a readable width
      padding: EdgeInsets.fromLTRB(20 + lay.side, lay.wide ? 22 : 16, 20 + lay.side, lay.wide ? 22 : 16),
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
          Row(
            children: [
              AdminBackButton(size: lay.wide ? 44 : 36), // NEW — back to Home tab
              const SizedBox(width: 12),
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: lay.wide ? 28 : 22),
              SizedBox(width: 8),
              Text(
                'Reports & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: lay.wide ? 24 : 18,
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
              height: lay.wide ? 40 : 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.filters.map((filter) {
                    final isSelected = selected == filter;
                    return GestureDetector(
                      onTap: () => controller.changeFilter(filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: lay.wide ? 20 : 14, vertical: lay.wide ? 9 : 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: lay.wide ? 14 : 12,
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

          // NEW — which period the numbers below belong to
          const SizedBox(height: 10),
          Obx(() => Row(
            children: [
              Icon(Icons.event_rounded, size: lay.wide ? 16 : 13, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${controller.periodLabel.value}  ·  ${controller.periodRangeText.value}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: lay.wide ? 13.5 : 11.5, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          )),
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
    final _ReportsLayout lay = _ReportsLayout.of(context); // NEW
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: lay.side, vertical: lay.wide ? 12 : 8), // CHANGED
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
                    size: lay.wide ? 28 : 20,
                    color: isSelected ? _green : Colors.grey[400],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _tabs[index]['label'],
                    style: TextStyle(
                      fontSize: lay.wide ? 13 : 10,
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
    // CHANGED — was SingleChildScrollView; page-level scroll now handles it.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Summary cards
          _StatGrid(
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

          // NEW — donations by purpose (Campaign / Project / Sponsor a Child / General Fund)
          _PurposeBreakdownCard(controller: controller),
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

          // NEW — resource donations received in this period
          _ResourceReceivedCard(controller: controller),
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
            title: 'Recent Donations — ${controller.periodLabel.value}',
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
    // CHANGED — was SingleChildScrollView; page-level scroll now handles it.
    return Padding(
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
                  _money(controller.totalFundsCollected.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.periodLabel.value}  ·  ${controller.approvedFundCount.value} approved fund donations',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                if (controller.pendingFundCount.value > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_money(controller.pendingFundAmount.value)} pending approval  ·  ${controller.pendingFundCount.value} donation(s)',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NEW — funds by purpose + the causes that raised the most
          _PurposeTilesGrid(controller: controller),
          const SizedBox(height: 16),
          _TopCausesCard(controller: controller),
          const SizedBox(height: 16),

          // Monthly bar chart
          _SectionCard(
            title: 'Funds Trend — ${controller.periodLabel.value}',
            icon: Icons.show_chart_rounded,
            child: SizedBox(
              height: 200,
              child: controller.monthlyFunds.values.every((v) => v <= 0) // CHANGED — buckets are zero-filled now, so "empty" means "all zero"
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

          // NEW — donors inside the selected period
          _PeriodHeading(controller: controller),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'New Donors',
                  value: '${controller.newDonors.value}',
                  icon: Icons.person_add_alt_1_rounded,
                  color: _green,
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Donors Giving',
                  value: '${controller.donatingDonors.value}',
                  icon: Icons.volunteer_activism_rounded,
                  color: const Color(0xFF8E24AA),
                  bg: const Color(0xFFF3E5F5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fund donations list
          _SectionCard(
            title: 'Fund Donations — ${controller.periodLabel.value}',
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
    // CHANGED — was SingleChildScrollView; page-level scroll now handles it.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
        children: [
          // Stats grid
          _StatGrid(
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

          // NEW — volunteers and tasks inside the selected period
          _PeriodHeading(controller: controller),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'New Volunteers',
                  value: '${controller.newVolunteers.value}',
                  icon: Icons.person_add_alt_1_rounded,
                  color: _green,
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Tasks Completed',
                  value: '${controller.tasksCompletedInPeriod.value}',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF00838F),
                  bg: const Color(0xFFE0F7FA),
                ),
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
    // CHANGED — was SingleChildScrollView; page-level scroll now handles it.
    return Padding(
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

          // NEW — what was added inside the selected period
          _PeriodHeading(controller: controller),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'New Campaigns',
                  value: '${controller.newCampaigns.value}',
                  icon: Icons.campaign_rounded,
                  color: _green,
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'New Children',
                  value: '${controller.newChildren.value}',
                  icon: Icons.child_care_rounded,
                  color: const Color(0xFF8E24AA),
                  bg: const Color(0xFFF3E5F5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'New Stock Items',
                  value: '${controller.newInventoryItems.value}',
                  icon: Icons.add_box_rounded,
                  color: const Color(0xFF00838F),
                  bg: const Color(0xFFE0F7FA),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
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
  final Color color; // NEW — defaults to the old green
  final String tooltipPrefix; // NEW — defaults to the old 'Rs. '
  final String tooltipSuffix; // NEW
  const _MonthlyBarChart({
    required this.data,
    this.color = _green,
    this.tooltipPrefix = 'Rs. ',
    this.tooltipSuffix = '',
  });

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
        maxY: (maxVal <= 0 ? 1.0 : maxVal) * 1.2, // CHANGED — an all-zero chart must not get a 0 height axis
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => color.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '$tooltipPrefix${rod.toY.toStringAsFixed(0)}$tooltipSuffix',
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
                color: color,
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
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(Get.find<ReportsController>().periodStart)) // NEW — selected period only
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
              'No donations in this period',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'resource';
            final status = data['status'] ?? 'pending';
            final isFund = type == 'fund' || (data['type'] == null && data.containsKey('amount')); // CHANGED — older fund donations have no 'type'

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
                              ? 'Fund — Rs. ${data['verifiedAmount'] ?? data['amount'] ?? 0}'
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
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(Get.find<ReportsController>().periodStart)) // NEW — selected period only
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
              'No approved fund donations in this period',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userEmail'] ??
                              data['donorEmail'] ??
                              'Donor',
                          style: const TextStyle(fontSize: 12),
                        ),
                        // NEW — what the money was given for
                        if ((data['donationTargetName'] ?? data['campaignName'] ?? '').toString().isNotEmpty)
                          Text(
                            (data['donationTargetName'] ?? data['campaignName']).toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${data['verifiedAmount'] ?? data['amount'] ?? 0}',
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
// NEW — WEB LAYOUT SUPPORT (Reports Step 3)
// ==========================================================================

// On very wide screens the content is kept to a comfortable width, while the
// scrolling page itself (and the header colour) still spans the whole window.
const double _kMaxContentWidth = 1240;

// Tells every card how much room the page has, so the same widgets are compact on a
// phone and large on web without each one having to measure the screen itself.
class _ReportsLayout extends InheritedWidget {
  final double width;
  const _ReportsLayout({required this.width, required super.child});

  bool get wide => width >= 1000;
  double get side => width > _kMaxContentWidth ? (width - _kMaxContentWidth) / 2 : 0;

  static _ReportsLayout of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ReportsLayout>() ??
          const _ReportsLayout(width: 0, child: SizedBox.shrink());

  @override
  bool updateShouldNotify(_ReportsLayout oldWidget) => oldWidget.width != width;
}

// Phone / small window: exactly the 2-column grid that used to be here.
// Web: fixed-size cards, 4 across.
class _StatGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    if (!_ReportsLayout.of(context).wide) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 16;
        const int cols = 4;
        final double cardW = ((constraints.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children) SizedBox(width: cardW, child: c),
          ],
        );
      },
    );
  }
}

// ==========================================================================
// NEW — PERIOD-WISE SECTIONS (Reports Step 2)
// Everything below reads the numbers ReportsController already worked out
// for the selected Today / Week / Month / Year filter.
// ==========================================================================

// 12345 -> "Rs. 12,345"
String _money(num value) {
  final String digits = value.round().abs().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return 'Rs. ${value.round() < 0 ? '-' : ''}$out';
}

// Icon + colours for each thing money can be donated to.
class _PurposeMeta {
  final String label; // plural — lists and tiles
  final String single; // singular — small chips
  final IconData icon;
  final Color color;
  final Color bg;
  const _PurposeMeta(this.label, this.single, this.icon, this.color, this.bg);
}

_PurposeMeta _purposeMeta(String key) {
  switch (key) {
    case 'project':
      return const _PurposeMeta('Projects', 'Project', Icons.rocket_launch_rounded,
          Color(0xFF1565C0), Color(0xFFE3F2FD));
    case 'sponsorship':
      return const _PurposeMeta('Sponsor a Child', 'Sponsor a Child', Icons.child_care_rounded,
          Color(0xFF8E24AA), Color(0xFFF3E5F5));
    case 'general_fund':
      return const _PurposeMeta('General Fund', 'General Fund', Icons.savings_rounded,
          Color(0xFFE65100), Color(0xFFFFF3E0));
    case 'campaign':
    default:
      return const _PurposeMeta('Campaigns', 'Campaign', Icons.campaign_rounded,
          Color(0xFF1B6B3A), Color(0xFFE8F5E9));
  }
}

// Small heading that separates "all time" numbers from "this period" numbers.
class _PeriodHeading extends StatelessWidget {
  final ReportsController controller;
  const _PeriodHeading({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool wide = _ReportsLayout.of(context).wide;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: wide ? 20 : 16,
            decoration: BoxDecoration(
              color: const Color(0xFF1B6B3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Text(
            '${controller.periodLabel.value} activity',
            style: TextStyle(
              fontSize: wide ? 15 : 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          )),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final bool wide = _ReportsLayout.of(context).wide;
    return Container(
      padding: EdgeInsets.symmetric(vertical: wide ? 18 : 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: wide ? 26 : 20, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: wide ? 12.5 : 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// ── Donations tab: count + amount for every purpose ───────────────────────
class _PurposeBreakdownCard extends StatelessWidget {
  final ReportsController controller;
  const _PurposeBreakdownCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool wide = _ReportsLayout.of(context).wide;
    return _SectionCard(
      title: 'Donations by Purpose',
      icon: Icons.category_rounded,
      child: Obx(() {
        final List<DonationTargetStat> stats = controller.fundsByTarget.toList();
        final bool hasAny = stats.any((s) => s.totalCount > 0);
        if (!hasAny) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'No fund donations in this period',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          );
        }
        final double totalApproved =
        stats.fold<double>(0, (sum, s) => sum + s.approvedAmount);
        return Column(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
              _row(stats[i], totalApproved, wide),
            ],
          ],
        );
      }),
    );
  }

  Widget _row(DonationTargetStat s, double totalApproved, bool wide) {
    final _PurposeMeta meta = _purposeMeta(s.key);
    final double share =
    totalApproved > 0 ? (s.approvedAmount / totalApproved).clamp(0.0, 1.0) : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: wide ? 54 : 42,
          height: wide ? 54 : 42,
          decoration: BoxDecoration(
            color: meta.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(meta.icon, color: meta.color, size: wide ? 28 : 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: wide ? 15 : 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Text(
                    _money(s.approvedAmount),
                    style: TextStyle(
                      fontSize: wide ? 15 : 13,
                      fontWeight: FontWeight.w800,
                      color: meta.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${s.approvedCount} approved  ·  ${s.pendingCount} pending  ·  ${s.rejectedCount} rejected',
                style: TextStyle(fontSize: wide ? 12.5 : 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: wide ? 9 : 7,
                  backgroundColor: meta.bg,
                  valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                ),
              ),
              if (s.pendingAmount > 0) ...[
                const SizedBox(height: 5),
                Text(
                  '${_money(s.pendingAmount)} waiting for approval',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Financial tab: one big tile per purpose ───────────────────────────────
class _PurposeTilesGrid extends StatelessWidget {
  final ReportsController controller;
  const _PurposeTilesGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<DonationTargetStat> stats = controller.fundsByTarget.toList();
      return LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final bool wide = w >= 760;
          final int cols = wide ? 4 : 2;
          const double gap = 12;
          final double tileW = ((w - gap * (cols - 1)) / cols).floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final s in stats) _PurposeTile(width: tileW, stat: s, wide: wide),
            ],
          );
        },
      );
    });
  }
}

class _PurposeTile extends StatelessWidget {
  final double width;
  final DonationTargetStat stat;
  final bool wide;
  const _PurposeTile({required this.width, required this.stat, required this.wide});

  @override
  Widget build(BuildContext context) {
    final _PurposeMeta meta = _purposeMeta(stat.key);
    final double chip = wide ? 48 : 40;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // soft watermark icon
            Positioned(
              right: -10,
              bottom: -14,
              child: Icon(
                meta.icon,
                size: wide ? 96 : 76,
                color: meta.color.withOpacity(0.07),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 18 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: chip,
                    height: chip,
                    decoration: BoxDecoration(
                      color: meta.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(meta.icon, color: meta.color, size: wide ? 26 : 21),
                  ),
                  SizedBox(height: wide ? 16 : 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _money(stat.approvedAmount),
                      style: TextStyle(
                        fontSize: wide ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: wide ? 13 : 12,
                      fontWeight: FontWeight.w700,
                      color: meta.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stat.approvedCount} approved donation${stat.approvedCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (stat.pendingCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_money(stat.pendingAmount)} pending (${stat.pendingCount})',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Financial tab: which campaign / project / child raised the most ──────
class _TopCausesCard extends StatelessWidget {
  final ReportsController controller;
  const _TopCausesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool wide = _ReportsLayout.of(context).wide;
    return _SectionCard(
      title: 'Top Causes',
      icon: Icons.emoji_events_rounded,
      child: Obx(() {
        final List<TargetLeaderStat> leaders = controller.targetLeaders.toList();
        if (leaders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'No approved fund donations in this period',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          );
        }
        final List<TargetLeaderStat> shown = leaders.take(8).toList();
        final double top = shown.first.raised > 0 ? shown.first.raised : 1;
        return Column(
          children: [
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _row(i + 1, shown[i], top, wide),
            ],
          ],
        );
      }),
    );
  }

  Widget _row(int rank, TargetLeaderStat l, double top, bool wide) {
    final _PurposeMeta meta = _purposeMeta(l.type);
    final double rel = (l.raised / top).clamp(0.0, 1.0);
    final String goalText = l.goal > 0
        ? '  ·  ${((l.collectedAllTime / l.goal) * 100).clamp(0, 999).round()}% of goal'
        : '';
    final bool first = rank == 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: wide ? 36 : 28,
          height: wide ? 36 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: first ? const Color(0xFFFFF3C4) : const Color(0xFFF1F3F5),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: wide ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: first ? const Color(0xFFB7791F) : Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 15 : 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(l.raised),
                    style: TextStyle(
                      fontSize: wide ? 15 : 13,
                      fontWeight: FontWeight.w800,
                      color: meta.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: meta.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 10, color: meta.color),
                        const SizedBox(width: 3),
                        Text(
                          meta.single,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: meta.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${l.donations} donation${l.donations == 1 ? '' : 's'}$goalText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: wide ? 12.5 : 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: rel,
                  minHeight: wide ? 8 : 6,
                  backgroundColor: meta.bg,
                  valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Donations tab: resources received in the period ──────────────────────
class _ResourceReceivedCard extends StatelessWidget {
  final ReportsController controller;
  const _ResourceReceivedCard({required this.controller});

  static const Color _teal = Color(0xFF00838F);
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final bool wide = _ReportsLayout.of(context).wide;
    return _SectionCard(
      title: 'Resources Received',
      icon: Icons.inventory_2_rounded,
      child: Obx(() {
        final int approved = controller.resourceApproved.value;
        final int pending = controller.resourcePending.value;
        final int rejected = controller.resourceRejected.value;
        final int qty = controller.resourceItemsQty.value;
        final cats = controller.resourceByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final Map<String, double> trend =
        Map<String, double>.from(controller.resourceTrend);
        final bool hasTrend = trend.values.any((v) => v > 0);

        if (approved + pending + rejected == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'No resource donations in this period',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Approved',
                    value: '$approved',
                    color: _green,
                    bg: const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Pending',
                    value: '$pending',
                    color: Colors.orange[700]!,
                    bg: Colors.orange[50]!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Items',
                    value: '$qty',
                    color: _teal,
                    bg: const Color(0xFFE0F7FA),
                  ),
                ),
              ],
            ),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'By category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              for (final e in cats.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProgressRow(
                    label: e.key,
                    value: e.value,
                    total: approved,
                    color: _teal,
                  ),
                ),
            ],
            if (hasTrend) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Received over time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: wide ? 210 : 150,
                child: _MonthlyBarChart(
                  data: trend,
                  color: _teal,
                  tooltipPrefix: '',
                  tooltipSuffix: ' received',
                ),
              ),
            ],
          ],
        );
      }),
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
    final bool wide = _ReportsLayout.of(context).wide; // NEW — large cards on web
    return Container(
      padding: EdgeInsets.all(wide ? 20 : 12),
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
            width: wide ? 58 : 40,
            height: wide ? 58 : 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(wide ? 16 : 10),
            ),
            child: Icon(icon, color: color, size: wide ? 30 : 20),
          ),
          SizedBox(width: wide ? 16 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: wide ? 30 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: wide ? 14 : 11,
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
    final bool wide = _ReportsLayout.of(context).wide; // NEW
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
            padding: wide ? const EdgeInsets.fromLTRB(24, 20, 24, 14) : const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: wide ? 24 : 18, color: _green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: wide ? 17 : 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(wide ? 20 : 12),
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
    final bool wide = _ReportsLayout.of(context).wide; // NEW

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: wide ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value / $total ($percent%)',
              style: TextStyle(
                fontSize: wide ? 13 : 11,
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
            minHeight: wide ? 10 : 8,
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