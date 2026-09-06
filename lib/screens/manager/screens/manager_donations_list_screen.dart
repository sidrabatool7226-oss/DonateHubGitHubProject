import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/manager_donations_controller.dart';
import '../screens/fund_donation_detail_screen.dart';
import '../screens/resource_donation_detail_screen.dart';

class ManagerDonationsListScreen extends StatelessWidget {
  const ManagerDonationsListScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  bool _isFund(Map<String, dynamic> data) {
    return data['type'] == 'fund' ||
        data.containsKey('amount') ||
        data.containsKey('verifiedAmount') ||
        data.containsKey('paymentProofUrl') ||
        data.containsKey('proofUrl');
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _display(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? 'Not provided' : text;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ManagerDonationsController>()) {
      Get.put(ManagerDonationsController());
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pending Donations',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _emerald,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load pending donations.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          final docs = List<QueryDocumentSnapshot>.from(
            snapshot.data?.docs ?? [],
          );

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];

            if (aTs is Timestamp && bTs is Timestamp) {
              return bTs.compareTo(aTs);
            }

            return 0;
          });

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = Map<String, dynamic>.from(
                doc.data() as Map<String, dynamic>,
              );

              return _PendingDonationCard(
                docId: doc.id,
                data: data,
                isFund: _isFund(data),
                display: _display,
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5EE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: _emerald,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Donations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14251E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'All submitted donations have been reviewed.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDonationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isFund;
  final String Function(dynamic) display;

  const _PendingDonationCard({
    required this.docId,
    required this.data,
    required this.isFund,
    required this.display,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);

  String _value(List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return 'Not provided';
  }

  String _amount() {
    final value = data['verifiedAmount'] ?? data['amount'];

    if (value is num) {
      return value.toStringAsFixed(0);
    }

    return value?.toString() ?? '0';
  }

  String _createdAt() {
    final value = data['createdAt'];

    if (value is Timestamp) {
      final d = value.toDate();

      return '${d.day}/${d.month}/${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final donor = _value([
      'userEmail',
      'donorEmail',
      'email',
      'donorName',
    ]);

    final title = isFund
        ? 'Fund Donation'
        : _value(['itemName']);

    final subtitle = isFund
        ? 'Rs. ${_amount()}'
        : 'Qty: ${_value(['quantity'])} · ${_value(['category'])}';

    return GestureDetector(
      onTap: () {
        final controller = Get.find<ManagerDonationsController>();

        controller.prefillForApproval(data);

        if (isFund) {
          Get.to(
                () => FundDonationDetailScreen(
              docId: docId,
              data: data,
            ),
            transition: Transition.rightToLeft,
          );
        } else {
          Get.to(
                () => ResourceDonationDetailScreen(
              docId: docId,
              data: data,
            ),
            transition: Transition.rightToLeft,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFund
                        ? const Color(0xFFE6F5EE)
                        : const Color(0xFFFFF3E4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isFund
                        ? Icons.payments_rounded
                        : Icons.inventory_2_rounded,
                    color: isFund
                        ? _emerald
                        : const Color(0xFFDB7C26),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title == 'Not provided' || title.isEmpty
                            ? 'Resource Donation'
                            : title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14251E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        donor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFFDB7C26),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MiniInfo(
                    icon: isFund
                        ? Icons.campaign_outlined
                        : Icons.category_outlined,
                    label: isFund ? 'Campaign' : 'Category',
                    value: isFund
                        ? _value(['campaignName', 'campaign'])
                        : _value(['category']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniInfo(
                    icon: isFund
                        ? Icons.receipt_long_outlined
                        : Icons.local_shipping_outlined,
                    label: isFund ? 'Method' : 'Logistics',
                    value: isFund
                        ? _value([
                      'paymentMethod',
                      'method',
                      'donationMethod',
                    ])
                        : _value([
                      'logisticsType',
                      'donationType',
                    ]),
                  ),
                ),
              ],
            ),

            if (_createdAt().isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _createdAt(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: _mint,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: _emerald,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14251E),
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