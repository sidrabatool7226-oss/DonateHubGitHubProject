import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Observables ──────────────────────────────────────────────────────
  var isLoading = false.obs;
  var selectedFilter = 'Month'.obs;
  var selectedReportTab = 0.obs;

  // Donation stats
  var totalDonations = 0.obs;
  var approvedDonations = 0.obs;
  var pendingDonations = 0.obs;
  var rejectedDonations = 0.obs;
  var fundDonations = 0.obs;
  var resourceDonations = 0.obs;

  // Financial stats
  var totalFundsCollected = 0.0.obs;
  var monthlyFunds = <String, double>{}.obs;

  // Donor stats
  var totalDonors = 0.obs;
  var activeDonors = 0.obs;

  // Volunteer stats
  var totalVolunteers = 0.obs;
  var verifiedVolunteers = 0.obs;
  var completedTasks = 0.obs;
  var pendingTasks = 0.obs;

  // Campaign stats
  var totalCampaigns = 0.obs;
  var activeCampaigns = 0.obs;

  // Inventory stats
  var totalInventoryItems = 0.obs;
  var urgentItems = 0.obs;

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
        return now.subtract(const Duration(days: 7));
      case 'Month':
        return DateTime(now.year, now.month, 1);
      case 'Year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  // ── Load All Reports ─────────────────────────────────────────────────
  Future<void> loadAllReports() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadDonationStats(),
        _loadFinancialStats(),
        _loadDonorStats(),
        _loadVolunteerStats(),
        _loadCampaignStats(),
        _loadInventoryStats(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Donation Stats ───────────────────────────────────────────────────
  Future<void> _loadDonationStats() async {
    final snapshot = await _db
        .collection('donations')
        .where('createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .get();

    final docs = snapshot.docs;
    totalDonations.value = docs.length;

    int approved = 0, pending = 0, rejected = 0, fund = 0, resource = 0;

    for (var doc in docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final type = data['type'] ?? '';

      if (status == 'approved' || status == 'completed') approved++;
      if (status == 'pending') pending++;
      if (status == 'rejected') rejected++;
      if (type == 'fund') fund++;
      if (type == 'resource') resource++;
    }

    approvedDonations.value = approved;
    pendingDonations.value = pending;
    rejectedDonations.value = rejected;
    fundDonations.value = fund;
    resourceDonations.value = resource;

    // Status chart data
    statusChartData.value = [
      {'label': 'Approved', 'value': approved.toDouble(), 'color': const Color(0xFF1B6B3A)},
      {'label': 'Pending', 'value': pending.toDouble(), 'color': const Color(0xFFF9A825)},
      {'label': 'Rejected', 'value': rejected.toDouble(), 'color': const Color(0xFFD32F2F)},
    ];
  }

  // ── Financial Stats ──────────────────────────────────────────────────
  Future<void> _loadFinancialStats() async {
    final snapshot = await _db
        .collection('donations')
        .where('type', isEqualTo: 'fund')
        .where('status', whereIn: ['approved', 'completed'])
        .get();

    double total = 0;
    Map<String, double> monthly = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      total += amount;

      // Monthly breakdown
      final ts = data['createdAt'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        final key = _monthName(date.month);
        monthly[key] = (monthly[key] ?? 0) + amount;
      }
    }

    totalFundsCollected.value = total;
    monthlyFunds.value = monthly;
  }

  // ── Donor Stats ──────────────────────────────────────────────────────
  Future<void> _loadDonorStats() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .get();

    totalDonors.value = snapshot.docs.length;
    activeDonors.value = snapshot.docs
        .where((d) => (d.data()['status'] ?? '') == 'active')
        .length;
  }

  // ── Volunteer Stats ──────────────────────────────────────────────────
  Future<void> _loadVolunteerStats() async {
    final volSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();

    totalVolunteers.value = volSnap.docs.length;
    verifiedVolunteers.value = volSnap.docs
        .where((d) =>
    (d.data()['verificationStage'] ?? '') == 'Verified')
        .length;

    final taskSnap = await _db.collection('tasks').get();
    completedTasks.value = taskSnap.docs
        .where((d) => (d.data()['status'] ?? '') == 'completed')
        .length;
    pendingTasks.value = taskSnap.docs
        .where((d) =>
    (d.data()['status'] ?? '') == 'assigned' ||
        (d.data()['status'] ?? '') == 'accepted')
        .length;
  }

  // ── Campaign Stats ───────────────────────────────────────────────────
  Future<void> _loadCampaignStats() async {
    final snap = await _db.collection('campaigns').get();
    totalCampaigns.value = snap.docs.length;
    activeCampaigns.value = snap.docs
        .where((d) => (d.data()['isActive'] ?? false) == true)
        .length;
  }

  // ── Inventory Stats ──────────────────────────────────────────────────
  Future<void> _loadInventoryStats() async {
    final snap = await _db.collection('inventory').get();
    totalInventoryItems.value = snap.docs.length;
    urgentItems.value = snap.docs
        .where((d) => (d.data()['isUrgent'] ?? false) == true)
        .length;
  }

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