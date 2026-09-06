// ============================================================
// FILE: lib/controllers/financial_summary_controller.dart
//
// FIX: Removed .orderBy() chained after .where('type',...).where(
// 'status', whereIn:...) — this combination requires a Firestore
// composite index; without one, the query silently returns zero
// results (no error, no crash — just an empty stream). Sorting
// is now done client-side instead. No other logic changed —
// this was ALREADY a live SUM over approved/completed fund
// donations, which is correctly idempotent by design (it's a
// query, not a stored += counter, so re-approving or re-opening
// a donation can never double-count it).
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FinancialSummaryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = true.obs;

  var totalReceived = 0.0.obs;
  var totalUtilized = 0.0.obs;
  var availableFunds = 0.0.obs;

  var totalDonorsCount = 0.obs;
  var totalTransactions = 0.obs;

  var recentDonations = <Map<String, dynamic>>[].obs;
  var recentUtilizations = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _bindReceivedFunds();
    _bindUtilizedFunds();
  }

  void _bindReceivedFunds() {
    // FIXED: single .where() chain, no .orderBy() — avoids requiring
    // a composite index. Sorted client-side below instead.
    _db
        .collection('donations')
        .where('type', isEqualTo: 'fund')
        .where('status', whereIn: ['approved', 'completed'])
        .snapshots()
        .listen((snap) {
      double sum = 0;
      final Set<String> donorIds = {};
      final List<Map<String, dynamic>> list = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        final amt = (data['verifiedAmount'] ?? data['amount'] ?? 0).toDouble();
        sum += amt;
        if (data['donorId'] != null) donorIds.add(data['donorId']);
        list.add({
          'id': doc.id,
          'amount': amt,
          'donorEmail': data['userEmail'] ?? data['donorEmail'] ?? 'Donor',
          'method': data['paymentMethod'] ?? '',
          'campaignName': data['campaignName'] ?? '',
          'createdAt': data['createdAt'],
        });
      }

      // Client-side sort — most recent first
      list.sort((a, b) {
        final aTs = a['createdAt'] as Timestamp?;
        final bTs = b['createdAt'] as Timestamp?;
        if (aTs == null || bTs == null) return 0;
        return bTs.compareTo(aTs);
      });

      totalReceived.value = sum;
      totalDonorsCount.value = donorIds.length;
      totalTransactions.value = snap.docs.length;
      recentDonations.value = list.take(6).toList();
      _recalculate();
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
    });
  }

  void _bindUtilizedFunds() {
    // Already a single .where() chain — no index issue here.
    _db
        .collection('utilization')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) {
      double sum = 0;
      final List<Map<String, dynamic>> list = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        final amt = (data['fundAmountUsed'] ?? 0).toDouble();
        sum += amt;
        if (amt > 0) {
          list.add({
            'id': doc.id,
            'amount': amt,
            'campaignName': data['campaignName'] ?? '',
            'description': data['description'] ?? '',
            'createdAt': data['createdAt'],
          });
        }
      }

      list.sort((a, b) {
        final aTs = a['createdAt'] as Timestamp?;
        final bTs = b['createdAt'] as Timestamp?;
        if (aTs == null || bTs == null) return 0;
        return bTs.compareTo(aTs);
      });

      totalUtilized.value = sum;
      recentUtilizations.value = list.take(6).toList();
      _recalculate();
    }, onError: (_) {});
  }

  void _recalculate() {
    availableFunds.value = totalReceived.value - totalUtilized.value;
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}