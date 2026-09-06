import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'admin_donation_details_screen.dart';

enum AdminDonationsListMode {
  approvedAndCompleted,
  pending,
}

class AdminDonationsListScreen extends StatelessWidget {
  final AdminDonationsListMode mode;
  final String title;

  const AdminDonationsListScreen({
    super.key,
    required this.mode,
    required this.title,
  });

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  bool _shouldShow(Map<String, dynamic> data) {
    if (data['isDeleted'] == true) {
      return false;
    }

    final status =
    (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    switch (mode) {
      case AdminDonationsListMode.pending:
        return status == 'pending';

      case AdminDonationsListMode.approvedAndCompleted:
        return status == 'approved' ||
            status == 'completed' ||
            status == 'complete';
    }
  }

  bool _isFund(Map<String, dynamic> data) {
    return data['type'] == 'fund' ||
        data.containsKey('amount') ||
        data.containsKey('paymentProofUrl');
  }

  String _statusLabel(dynamic status) {
    final value =
        status?.toString().trim().toLowerCase() ??
            'pending';

    if (value == 'complete' ||
        value == 'completed') {
      return 'Completed';
    }

    return value
        .split('_')
        .map(
          (word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _green,
              ),
            );
          }

          final docs =
          (snapshot.data?.docs ?? []).where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return _shouldShow(data);
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                mode == AdminDonationsListMode.pending
                    ? 'No pending donations'
                    : 'No approved or completed donations',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
              doc.data() as Map<String, dynamic>;

              final bool isFund = _isFund(data);

              final status =
                  data['status']?.toString() ??
                      'pending';

              final campaign =
                  data['campaignName']
                      ?.toString()
                      .trim() ??
                      '';

              final donor =
                  data['donorName'] ??
                      data['userEmail'] ??
                      data['donorEmail'] ??
                      'Donor';

              final titleText = isFund
                  ? 'Rs. ${data['verifiedAmount'] ?? data['amount'] ?? 0}'
                  : data['itemName'] ??
                  data['category'] ??
                  'Resource Donation';

              return GestureDetector(
                onTap: () => Get.to(
                      () => AdminDonationDetailsScreen(
                    donationId: doc.id,
                    initialData: data,
                  ),
                  transition: Transition.rightToLeft,
                ),
                child: Container(
                  margin:
                  const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isFund
                              ? const Color(0xFFF3E5F5)
                              : const Color(0xFFE8F5E9),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFund
                              ? Icons.payments_rounded
                              : Icons.inventory_2_rounded,
                          color: isFund
                              ? const Color(0xFF6A1B9A)
                              : _green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFund
                                  ? 'Fund Donation'
                                  : 'Resource Donation',
                              style: TextStyle(
                                color: isFund
                                    ? const Color(
                                    0xFF6A1B9A)
                                    : _green,
                                fontSize: 10.5,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              titleText.toString(),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              donor.toString(),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (campaign.isNotEmpty)
                              Text(
                                campaign,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                  Colors.grey[400],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _DonationStatusBadge(
                        label:
                        _statusLabel(status),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DonationStatusBadge extends StatelessWidget {
  final String label;

  const _DonationStatusBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();

    Color color;
    Color bg;

    if (lower == 'completed') {
      color = const Color(0xFF1B6B3A);
      bg = const Color(0xFFE8F5E9);
    } else if (lower == 'approved') {
      color = Colors.blue[700]!;
      bg = Colors.blue[50]!;
    } else {
      color = Colors.orange[700]!;
      bg = Colors.orange[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}