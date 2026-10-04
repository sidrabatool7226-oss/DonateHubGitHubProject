
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonationStatusStyle {
  final String label;
  final Color color;
  final Color bg;
  const DonationStatusStyle(this.label, this.color, this.bg);
}

class DonationPurposeStyle {
  final String label;
  final String single;
  final IconData icon;
  final Color color;
  final Color bg;
  const DonationPurposeStyle(this.label, this.single, this.icon, this.color, this.bg);
}

class DonationKit {
  DonationKit._();

  static const Color green = Color(0xFF1B6B3A);
  static const Color teal = Color(0xFF00838F);
  static const Color bg = Color(0xFFF4F6F8);
  static const Color ink = Color(0xFF14251E);

  static const List<String> inProgress = [
    'pickup_assigned', 'in_transit', 'awaiting_physical', 'pending_pickup',
    'volunteer_assigned', 'picked_up', 'received',
  ];
  static const List<String> approvedFamily = [
    'approved', 'pickup_assigned', 'in_transit', 'awaiting_physical',
    'pending_pickup', 'volunteer_assigned', 'picked_up', 'received',
    'completed', 'complete',
  ];
  static bool isFund(Map<String, dynamic> d) {
    final String t = (d['type'] ?? '').toString();
    if (t == 'fund') return true;
    if (t == 'resource') return false;
    return d.containsKey('amount') || d.containsKey('paymentProofUrl');
  }

  static double numOf(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double amountOf(Map<String, dynamic> d) =>
      numOf(d['verifiedAmount'] ?? d['amount']);

  static String money(num value) {
    final String digits = value.round().abs().toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return 'Rs. ${value.round() < 0 ? '-' : ''}$out';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String fmtDate(dynamic v, {bool time = true}) {
    if (v is! Timestamp) return '';
    final DateTime d = v.toDate();
    final String date = '${d.day} ${_months[d.month - 1]} ${d.year}';
    if (!time) return date;
    final int h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String mm = d.minute.toString().padLeft(2, '0');
    return '$date, $h12:$mm ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String shortDate(dynamic v) {
    if (v is! Timestamp) return '';
    final DateTime d = v.toDate();
    final String s = '${d.day} ${_months[d.month - 1]}';
    return d.year == DateTime.now().year ? s : '$s ${d.year}';
  }

  static String valueText(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return fmtDate(value);
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) return value.isEmpty ? '' : value.join(', ');
    if (value is Map) {
      if (value.isEmpty) return '';
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    final String t = value.toString().trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return '';
    return t;
  }

  static bool hasValue(dynamic value) => valueText(value).isNotEmpty;

  static String pretty(String key) {
    final String spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
    );
    return spaced
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String statusLabel(dynamic status) {
    final String v = status?.toString().trim().toLowerCase() ?? 'pending';
    if (v.isEmpty) return 'Pending';
    if (v == 'complete' || v == 'completed') return 'Completed';
    return v
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static DonationStatusStyle statusStyle(dynamic raw) {
    final String s = (raw ?? 'pending').toString().trim().toLowerCase();
    final String label = statusLabel(raw);
    if (s == 'completed' || s == 'complete') {
      return DonationStatusStyle(label, green, const Color(0xFFE8F5E9));
    }
    if (s == 'approved') {
      return DonationStatusStyle(label, const Color(0xFF1565C0), const Color(0xFFE3F2FD));
    }
    if (s == 'rejected') {
      return DonationStatusStyle(label, const Color(0xFFC62828), const Color(0xFFFDECEA));
    }
    if (inProgress.contains(s)) {
      return DonationStatusStyle(label, teal, const Color(0xFFE0F7FA));
    }
    if (s == 'pending' || s.isEmpty) {
      return DonationStatusStyle(label, const Color(0xFFE65100), const Color(0xFFFFF3E0));
    }
    return DonationStatusStyle(label, const Color(0xFF455A64), const Color(0xFFECEFF1));
  }

  static int stage(dynamic raw) {
    final String s = (raw ?? 'pending').toString().trim().toLowerCase();
    if (s == 'rejected') return -1;
    if (s == 'completed' || s == 'complete') return 3;
    if (inProgress.contains(s)) return 2;
    if (s == 'approved') return 1;
    return 0;
  }

  static String purposeKey(Map<String, dynamic> d) {
    final String t = (d['donationTargetType'] ?? '').toString();
    if (t == 'campaign' || t == 'project' || t == 'sponsorship' || t == 'general_fund') {
      return t;
    }
    if ((d['campaignId'] ?? '').toString().isNotEmpty) return 'campaign';
    return 'general_fund';
  }

  static String targetName(Map<String, dynamic> d) =>
      (d['donationTargetName'] ?? d['campaignName'] ?? '').toString().trim();

  static DonationPurposeStyle purposeStyle(String key) {
    switch (key) {
      case 'project':
        return const DonationPurposeStyle('Projects', 'Project',
            Icons.rocket_launch_rounded, Color(0xFF1565C0), Color(0xFFE3F2FD));
      case 'sponsorship':
        return const DonationPurposeStyle('Sponsor a Child', 'Sponsor a Child',
            Icons.child_care_rounded, Color(0xFF8E24AA), Color(0xFFF3E5F5));
      case 'general_fund':
        return const DonationPurposeStyle('General Fund', 'General Fund',
            Icons.savings_rounded, Color(0xFFE65100), Color(0xFFFFF3E0));
      case 'campaign':
      default:
        return const DonationPurposeStyle('Campaigns', 'Campaign',
            Icons.campaign_rounded, Color(0xFF1B6B3A), Color(0xFFE8F5E9));
    }
  }
}