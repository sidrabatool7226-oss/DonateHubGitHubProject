import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonationTargetStat {
  final String key;
  final String label;
  int approvedCount = 0;
  double approvedAmount = 0;
  int pendingCount = 0;
  double pendingAmount = 0;
  int rejectedCount = 0;

  DonationTargetStat(this.key, this.label);

  int get totalCount => approvedCount + pendingCount + rejectedCount;
}

/// One individual campaign / project / sponsored child / the general fund,
/// with how much was raised for it inside the selected period.
class TargetLeaderStat {
  final String id;
  final String title;
  final String type; // 'campaign' | 'project' | 'sponsorship' | 'general_fund'
  final double goal; // all-time goal (0 if none)
  final double collectedAllTime; // all-time collectedAmount from the campaign doc
  double raised = 0; // approved amount inside the selected period
  int donations = 0; // approved donations inside the selected period

  TargetLeaderStat({
    required this.id,
    required this.title,
    required this.type,
    required this.goal,
    required this.collectedAllTime,
  });
}

class ReportsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedFilter = 'Month'.obs;
  var selectedReportTab = 0.obs;

  // NEW — human readable description of the selected period
  var periodLabel = 'This month'.obs;
  var periodRangeText = ''.obs;

  // Donation stats  (all of these now follow the selected period)
  var totalDonations = 0.obs;
  var approvedDonations = 0.obs;
  var pendingDonations = 0.obs;
  var rejectedDonations = 0.obs;
  var fundDonations = 0.obs;
  var resourceDonations = 0.obs;

  // NEW — fund detail for the selected period
  var approvedFundCount = 0.obs;
  var pendingFundCount = 0.obs;
  var pendingFundAmount = 0.0.obs;
  var fundsByTarget = <DonationTargetStat>[].obs; // campaign / project / sponsorship / general fund
  var targetLeaders = <TargetLeaderStat>[].obs; // sorted by amount raised, highest first

  // NEW — resource detail for the selected period
  var resourceApproved = 0.obs;
  var resourcePending = 0.obs;
  var resourceRejected = 0.obs;
  var resourceItemsQty = 0.obs;
  var resourceByCategory = <String, int>{}.obs;
  var resourceTrend = <String, double>{}.obs; // resource donations per bucket

  // Financial stats  (now follow the selected period)
  var totalFundsCollected = 0.0.obs;
  var monthlyFunds = <String, double>{}.obs; // name kept for the existing chart; buckets follow the filter

  // Donor stats
  var totalDonors = 0.obs;
  var activeDonors = 0.obs;
  var newDonors = 0.obs; // NEW — joined inside the period
  var donatingDonors = 0.obs; // NEW — distinct donors who donated inside the period

  // Volunteer stats
  var totalVolunteers = 0.obs;
  var verifiedVolunteers = 0.obs;
  var completedTasks = 0.obs;
  var pendingTasks = 0.obs;
  var newVolunteers = 0.obs; // NEW — joined inside the period
  var tasksCompletedInPeriod = 0.obs; // NEW

  // Campaign stats
  var totalCampaigns = 0.obs;
  var activeCampaigns = 0.obs;
  var newCampaigns = 0.obs; // NEW — campaigns + projects created inside the period
  var newChildren = 0.obs; // NEW — Sponsor-a-Child profiles created inside the period

  // Inventory stats
  var totalInventoryItems = 0.obs;
  var urgentItems = 0.obs;
  var newInventoryItems = 0.obs; // NEW — added inside the period

  // Chart data
  var donationChartData = <Map<String, dynamic>>[].obs;
  var statusChartData = <Map<String, dynamic>>[].obs;

  // Filter options
  final List<String> filters = [
    'Today',
    'Week',
    'Month',
    'Year',
  ];

  // NEW — statuses that mean "approved or moved on after approval". The Manager flow
  // sets pickup_assigned, the Admin flow sets pending_pickup / picked_up / received.
  static const List<String> _approvedFamily = [
    'approved', 'completed', 'complete', 'pickup_assigned', 'in_transit',
    'awaiting_physical', 'pending_pickup', 'volunteer_assigned', 'picked_up',
    'received',
  ];

  // NEW — if the admin taps filters quickly, an older (slower) load must never
  // overwrite the numbers of a newer one.
  int _loadSeq = 0;
  bool _isStale(int seq) => seq != _loadSeq;

  @override
  void onInit() {
    super.onInit();
    loadAllReports();
  }

  // ── Date Range from Filter ───────────────────────────────────────────
  DateTime get _startDate {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Week':
      // CHANGED — "last 7 days including today", from midnight, so the chart
      // (one bar per calendar day) adds up exactly to the totals.
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      case 'Month':
        return DateTime(now.year, now.month, 1);
      case 'Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  // NEW — first moment of the selected period. The Reports screen's live lists use it
  // so they show exactly the same period as the numbers above them.
  DateTime get periodStart => _startDate;

  // ── Load All Reports ─────────────────────────────────────────────────
  Future<void> loadAllReports() async {
    final int seq = ++_loadSeq;
    isLoading.value = true;
    try {
      final DateTime start = _startDate; // read once so every query uses the same boundary
      _updatePeriodLabels(start);

      // One donations query + one campaigns query, shared by several reports.
      // (createdAt range on a single field — needs no composite index.)
      final shared = await Future.wait([
        _db
            .collection('donations')
            .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get(),
        _db.collection('campaigns').get(),
      ]);
      if (_isStale(seq)) return;

      final donationDocs = shared[0].docs;
      final campaignDocs = shared[1].docs;
      final Map<String, Map<String, dynamic>> campaignsById = {
        for (final c in campaignDocs) c.id: c.data(),
      };

      _loadDonationStats(donationDocs, campaignsById); // donations + funds + purpose breakdown
      _loadCampaignStats(campaignDocs, start);

      await Future.wait([
        _loadDonorStats(seq, start),
        _loadVolunteerStats(seq, start),
        _loadInventoryStats(seq, start),
      ]);
    } finally {
      if (!_isStale(seq)) isLoading.value = false;
    }
  }

  // ── Donation + Financial Stats ───────────────────────────────────────
  // CHANGED — both used to be separate queries and the financial one had NO date
  // filter, so "Total Funds Collected" never changed with Today/Week/Month/Year.
  // Everything is now worked out from the same period query, so the numbers
  // always agree with each other.
  void _loadDonationStats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      Map<String, Map<String, dynamic>> campaignsById,
      ) {
    int total = 0, approved = 0, pending = 0, rejected = 0;
    int fund = 0, resource = 0;
    int approvedFunds = 0, pendingFunds = 0;
    double fundsTotal = 0, pendingFundsAmt = 0;
    int resApproved = 0, resPending = 0, resRejected = 0, resQty = 0;
    final Map<String, int> resByCategory = {};
    final Set<String> donors = {};

    final List<String> labels = _trendLabels();
    final Map<String, double> fundsTrend = {for (final l in labels) l: 0.0};
    final Map<String, double> resourceTrendMap = {for (final l in labels) l: 0.0};

    final Map<String, DonationTargetStat> targets = {
      'campaign': DonationTargetStat('campaign', 'Campaigns'),
      'project': DonationTargetStat('project', 'Projects'),
      'sponsorship': DonationTargetStat('sponsorship', 'Sponsor a Child'),
      'general_fund': DonationTargetStat('general_fund', 'General Fund'),
    };
    final Map<String, TargetLeaderStat> leaders = {};

    for (final doc in docs) {
      final data = doc.data();

      // Soft-deleted donations are hidden everywhere else in the admin app.
      if (data['isDeleted'] == true) continue;

      total++;
      final String group = _statusGroup((data['status'] ?? '').toString());
      final String type = (data['type'] ?? '').toString();
      // An explicit 'type' always wins; only older documents saved WITHOUT a
      // type fall back to guessing from their fields.
      final bool isFund =
          type == 'fund' || (type.isEmpty && data.containsKey('amount'));
      final bool isResource =
          type == 'resource' || (type.isEmpty && data.containsKey('itemName'));

      if (group == 'approved') approved++;
      if (group == 'pending') pending++;
      if (group == 'rejected') rejected++;

      final DateTime? created = _dateOf(data['createdAt']);
      final String? bucket =
      created == null ? null : _trendLabelFor(created, labels);

      if (group != 'rejected') {
        final String donor = (data['donorId'] ?? data['userId'] ?? '').toString();
        if (donor.isNotEmpty) donors.add(donor);
      }

      if (isFund) {
        fund++;
        final double amt = _amountOf(data);
        final String key = _targetKeyOf(data, campaignsById);
        final DonationTargetStat stat = targets[key]!;

        if (group == 'approved') {
          approvedFunds++;
          fundsTotal += amt;
          stat.approvedCount++;
          stat.approvedAmount += amt;
          if (bucket != null) fundsTrend[bucket] = (fundsTrend[bucket] ?? 0) + amt;

          // per-campaign / per-project / per-child / general-fund leaderboard
          final bool isGeneral = key == 'general_fund';
          final String leaderId = isGeneral
              ? 'GENERAL'
              : (data['donationTargetId'] ?? data['campaignId'] ?? '').toString();
          if (leaderId.isNotEmpty) {
            final TargetLeaderStat leader =
            leaders.putIfAbsent('$key:$leaderId', () {
              final Map<String, dynamic>? meta = campaignsById[leaderId];
              String title = isGeneral
                  ? 'General Fund'
                  : (data['donationTargetName'] ??
                  data['campaignName'] ??
                  meta?['title'] ??
                  '')
                  .toString();
              if (title.trim().isEmpty) title = 'Untitled';
              return TargetLeaderStat(
                id: leaderId,
                title: title,
                type: key,
                goal: _numOf(meta?['goalAmount']),
                collectedAllTime: _numOf(meta?['collectedAmount']),
              );
            });
            leader.raised += amt;
            leader.donations++;
          }
        } else if (group == 'pending') {
          pendingFunds++;
          pendingFundsAmt += amt;
          stat.pendingCount++;
          stat.pendingAmount += amt;
        } else if (group == 'rejected') {
          stat.rejectedCount++;
        }
      }

      if (isResource) {
        resource++;
        if (group == 'approved') {
          resApproved++;
          resQty += _intOf(data['quantity'], fallback: 1);
          final String cat = (data['category'] ?? '').toString().trim();
          final String catKey = (cat.isEmpty || cat.toLowerCase() == 'others')
              ? 'Other'
              : cat;
          resByCategory[catKey] = (resByCategory[catKey] ?? 0) + 1;
        } else if (group == 'pending') {
          resPending++;
        } else if (group == 'rejected') {
          resRejected++;
        }
        if (group != 'rejected' && bucket != null) {
          resourceTrendMap[bucket] = (resourceTrendMap[bucket] ?? 0) + 1;
        }
      }
    }

    totalDonations.value = total;
    approvedDonations.value = approved;
    pendingDonations.value = pending;
    rejectedDonations.value = rejected;
    fundDonations.value = fund;
    resourceDonations.value = resource;

    approvedFundCount.value = approvedFunds;
    pendingFundCount.value = pendingFunds;
    pendingFundAmount.value = pendingFundsAmt;
    totalFundsCollected.value = fundsTotal;
    monthlyFunds.value = fundsTrend;
    resourceTrend.value = resourceTrendMap;

    resourceApproved.value = resApproved;
    resourcePending.value = resPending;
    resourceRejected.value = resRejected;
    resourceItemsQty.value = resQty;
    resourceByCategory.value = resByCategory;

    donatingDonors.value = donors.length;
    fundsByTarget.value = targets.values.toList();
    targetLeaders.value = leaders.values.toList()
      ..sort((a, b) => b.raised.compareTo(a.raised));

    // Status chart data
    statusChartData.value = [
      {'label': 'Approved', 'value': approved.toDouble(), 'color': const Color(0xFF1B6B3A)},
      {'label': 'Pending', 'value': pending.toDouble(), 'color': const Color(0xFFF9A825)},
      {'label': 'Rejected', 'value': rejected.toDouble(), 'color': const Color(0xFFD32F2F)},
    ];
  }

  // ── Donor Stats ──────────────────────────────────────────────────────
  Future<void> _loadDonorStats(int seq, DateTime start) async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .get();
    if (_isStale(seq)) return;

    totalDonors.value = snapshot.docs.length;
    activeDonors.value = snapshot.docs
        .where((d) => (d.data()['status'] ?? '') == 'active')
        .length;
    newDonors.value = snapshot.docs
        .where((d) => _isOnOrAfter(d.data()['createdAt'], start))
        .length;
  }

  // ── Volunteer Stats ──────────────────────────────────────────────────
  Future<void> _loadVolunteerStats(int seq, DateTime start) async {
    final volSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();

    final taskSnap = await _db.collection('tasks').get();
    if (_isStale(seq)) return;

    totalVolunteers.value = volSnap.docs.length;
    verifiedVolunteers.value = volSnap.docs
        .where((d) =>
    (d.data()['verificationStage'] ?? '') == 'Verified')
        .length;
    newVolunteers.value = volSnap.docs
        .where((d) => _isOnOrAfter(d.data()['createdAt'], start))
        .length;

    completedTasks.value = taskSnap.docs
        .where((d) => (d.data()['status'] ?? '') == 'completed')
        .length;
    pendingTasks.value = taskSnap.docs
        .where((d) =>
    (d.data()['status'] ?? '') == 'assigned' ||
        (d.data()['status'] ?? '') == 'accepted')
        .length;
    tasksCompletedInPeriod.value = taskSnap.docs
        .where((d) =>
    (d.data()['status'] ?? '') == 'completed' &&
        _isOnOrAfter(d.data()['completedAt'], start))
        .length;
  }

  // ── Campaign Stats ───────────────────────────────────────────────────
  // CHANGED — receives the campaigns already fetched above instead of asking again.
  void _loadCampaignStats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      DateTime start,
      ) {
    totalCampaigns.value = docs.length;
    activeCampaigns.value = docs
        .where((d) => (d.data()['isActive'] ?? false) == true)
        .length;

    int campaigns = 0, children = 0;
    for (final d in docs) {
      final data = d.data();
      if (!_isOnOrAfter(data['createdAt'], start)) continue;
      if ((data['category'] ?? 'campaign') == 'sponsorship') {
        children++;
      } else {
        campaigns++;
      }
    }
    newCampaigns.value = campaigns;
    newChildren.value = children;
  }

  // ── Inventory Stats ──────────────────────────────────────────────────
  Future<void> _loadInventoryStats(int seq, DateTime start) async {
    final snap = await _db.collection('inventory').get();
    if (_isStale(seq)) return;

    totalInventoryItems.value = snap.docs.length;
    urgentItems.value = snap.docs
        .where((d) => (d.data()['isUrgent'] ?? false) == true)
        .length;
    newInventoryItems.value = snap.docs
        .where((d) =>
        _isOnOrAfter(d.data()['createdAt'] ?? d.data()['addedAt'], start))
        .length;
  }

  // ══════════════════════════════════════════════════════════════════════
  // NEW — helpers
  // ══════════════════════════════════════════════════════════════════════

  /// 'approved' | 'pending' | 'rejected' | '' (unknown — only counted in the total)
  String _statusGroup(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'rejected') return 'rejected';
    if (s == 'pending') return 'pending';
    if (_approvedFamily.contains(s)) return 'approved';
    return '';
  }

  /// Which purpose a fund donation was made for.
  String _targetKeyOf(
      Map<String, dynamic> data,
      Map<String, Map<String, dynamic>> campaignsById,
      ) {
    final String t = (data['donationTargetType'] ?? '').toString();
    if (t == 'campaign' ||
        t == 'project' ||
        t == 'sponsorship' ||
        t == 'general_fund') {
      return t;
    }
    // Older donations (saved before the target fields existed): look the campaign up.
    final String cid = (data['campaignId'] ?? '').toString();
    if (cid.isNotEmpty) {
      final String cat = (campaignsById[cid]?['category'] ?? 'campaign').toString();
      if (cat == 'project') return 'project';
      if (cat == 'sponsorship') return 'sponsorship';
      return 'campaign';
    }
    return 'general_fund'; // an old fund donation with no campaign = general support
  }

  /// The approved amount if the Manager corrected it, otherwise what the donor entered —
  /// the same rule campaign totals already use.
  double _amountOf(Map<String, dynamic> data) =>
      _numOf(data['verifiedAmount'] ?? data['amount']);

  double _numOf(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _intOf(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  DateTime? _dateOf(dynamic v) => v is Timestamp ? v.toDate() : null;

  bool _isOnOrAfter(dynamic v, DateTime start) {
    final DateTime? d = _dateOf(v);
    return d != null && !d.isBefore(start);
  }

  // Bars of the trend charts, oldest -> newest, for the selected filter.
  List<String> _trendLabels() {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case 'Today':
        return const ['12am', '3am', '6am', '9am', '12pm', '3pm', '6pm', '9pm'];
      case 'Week':
        const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return [
          for (int i = 6; i >= 0; i--)
            wd[now.subtract(Duration(days: i)).weekday - 1],
        ];
      case 'Year':
        return [for (int m = 1; m <= now.month; m++) _monthName(m)];
      case 'Month':
      default:
        const all = ['1–7', '8–14', '15–21', '22–28', '29–31'];
        return all.sublist(0, ((now.day - 1) ~/ 7) + 1);
    }
  }

  // Which bar a date belongs to (null = outside the chart).
  String? _trendLabelFor(DateTime dt, List<String> labels) {
    final now = DateTime.now();
    int idx;
    switch (selectedFilter.value) {
      case 'Today':
        idx = dt.hour ~/ 3;
        break;
      case 'Week':
        final today = DateTime.utc(now.year, now.month, now.day);
        final day = DateTime.utc(dt.year, dt.month, dt.day);
        idx = 6 - today.difference(day).inDays;
        break;
      case 'Year':
        idx = dt.month - 1;
        break;
      case 'Month':
      default:
        idx = (dt.day - 1) ~/ 7;
    }
    if (idx < 0 || idx >= labels.length) return null;
    return labels[idx];
  }

  void _updatePeriodLabels(DateTime start) {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case 'Today':
        periodLabel.value = 'Today';
        break;
      case 'Week':
        periodLabel.value = 'Last 7 days';
        break;
      case 'Year':
        periodLabel.value = 'This year';
        break;
      case 'Month':
      default:
        periodLabel.value = 'This month';
    }

    final bool sameDay = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    periodRangeText.value = sameDay
        ? _fmtDay(now, withYear: true)
        : '${_fmtDay(start, withYear: start.year != now.year)} – ${_fmtDay(now, withYear: true)}';
  }

  String _fmtDay(DateTime d, {bool withYear = false}) =>
      '${d.day} ${_monthName(d.month)}${withYear ? ' ${d.year}' : ''}';

  // ── Month Name ───────────────────────────────────────────────────────
  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // ── Change Filter ────────────────────────────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    loadAllReports();
  }
}