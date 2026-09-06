import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/manager_campaigns_controller.dart';

class ManagerCampaignDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ManagerCampaignDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerCampaignsController());

    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['image'] ?? '').toString();
    final endDate = (data['endDate'] ?? '').toString();

    final goal = _number(data['goalAmount']);
    final collected = _number(data['collectedAmount']);

    final isActive = data['isActive'] == true;

    final needs = data['needs'] is List
        ? List<String>.from(
      (data['needs'] as List).map((e) => e.toString()),
    )
        : <String>[];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Campaign Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: controller.getCampaignDonations(
          campaignId: docId,
          campaignName: title,
        ),
        builder: (context, snapshot) {
          final donations = snapshot.data ?? [];

          double approvedFundTotal = 0;

          for (final donation in donations) {
            final type = (donation['type'] ?? '').toString();
            final status = (donation['status'] ?? '').toString();

            if (type == 'fund' && status == 'approved') {
              approvedFundTotal += controller.getAmount(donation);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────────────
                // Campaign Image
                // ─────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl.isEmpty
                      ? Container(
                    height: 220,
                    width: double.infinity,
                    color: const Color(0xFFE6F5EE),
                    child: const Icon(
                      Icons.campaign_outlined,
                      size: 60,
                      color: _emerald,
                    ),
                  )
                      : Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 220,
                        color: const Color(0xFFE6F5EE),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 45,
                          color: _emerald,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────
                // Campaign Main Information
                // ─────────────────────────────────────────────
                _SectionCard(
                  title: 'Campaign Information',
                  icon: Icons.campaign_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Untitled Campaign' : title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14251E),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: Colors.grey[600],
                          ),
                        ),

                      const SizedBox(height: 14),

                      _DetailRow(
                        label: 'Status',
                        value: isActive ? 'Active' : 'Inactive',
                      ),

                      _DetailRow(
                        label: 'End Date',
                        value: endDate.isEmpty
                            ? 'Not specified'
                            : endDate,
                      ),

                      _DetailRow(
                        label: 'Goal Amount',
                        value: 'Rs. ${goal.toStringAsFixed(0)}',
                      ),

                      _DetailRow(
                        label: 'Campaign Collected',
                        value: 'Rs. ${collected.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─────────────────────────────────────────────
                // Needs
                // ─────────────────────────────────────────────
                if (needs.isNotEmpty)
                  _SectionCard(
                    title: 'Required Items / Needs',
                    icon: Icons.inventory_2_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: needs.map((need) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5EE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _emerald.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            need,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                if (needs.isNotEmpty)
                  const SizedBox(height: 14),

                // ─────────────────────────────────────────────
                // Donation Summary
                // ─────────────────────────────────────────────
                _SectionCard(
                  title: 'Donation Summary',
                  icon: Icons.analytics_outlined,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          label: 'Donations',
                          value: '${donations.length}',
                          icon: Icons.volunteer_activism_rounded,
                          color: _emerald,
                          background: const Color(0xFFE6F5EE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryBox(
                          label: 'Approved Funds',
                          value:
                          'Rs. ${approvedFundTotal.toStringAsFixed(0)}',
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF2563EB),
                          background: const Color(0xFFEFF6FF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ─────────────────────────────────────────────
                // Related Donations
                // ─────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 17,
                      color: _emerald,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Related Donations & Donors',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14251E),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${donations.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _emerald,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        color: _emerald,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (donations.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 38,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No donations for this campaign yet.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...donations.map(
                        (donation) => _DonationCard(
                      donation: donation,
                      controller: controller,
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final ManagerCampaignsController controller;

  const _DonationCard({
    required this.donation,
    required this.controller,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final type = (donation['type'] ?? '').toString();
    final status = (donation['status'] ?? 'pending').toString();

    final isFund = type == 'fund';

    final donorId =
    (donation['donorId'] ?? donation['userId'] ?? '').toString();

    final donorEmail =
    (donation['userEmail'] ?? donation['donorEmail'] ?? '').toString();

    final donorName =
    (donation['donorName'] ?? '').toString();

    final itemName =
    (donation['itemName'] ?? 'Resource Donation').toString();

    final category =
    (donation['category'] ?? '').toString();

    final amount = controller.getAmount(donation);

    final dateValue =
        donation['createdAt'] ?? donation['timestamp'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFund
                      ? const Color(0xFFE6F5EE)
                      : const Color(0xFFFFF3E4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isFund
                      ? Icons.payments_rounded
                      : Icons.inventory_2_rounded,
                  color: isFund
                      ? _emerald
                      : const Color(0xFFDB7C26),
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFund
                          ? 'Fund Donation'
                          : itemName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14251E),
                      ),
                    ),

                    const SizedBox(height: 3),

                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),

              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 10),

          // Donor information
          FutureBuilder<Map<String, dynamic>?>(
            future: controller.fetchDonorProfile(donorId),
            builder: (context, snapshot) {
              final profile = snapshot.data;

              final nameFromProfile =
              (profile?['name'] ?? '').toString();

              final emailFromProfile =
              (profile?['email'] ?? '').toString();

              final phoneFromProfile =
              (profile?['phone'] ?? profile?['contact'] ?? '')
                  .toString();

              final finalName = donorName.isNotEmpty
                  ? donorName
                  : nameFromProfile;

              final finalEmail = donorEmail.isNotEmpty
                  ? donorEmail
                  : emailFromProfile;

              return Column(
                children: [
                  _DonorInfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Donor',
                    value: finalName.isEmpty
                        ? 'Name not available'
                        : finalName,
                  ),

                  if (finalEmail.isNotEmpty)
                    _DonorInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: finalEmail,
                    ),

                  if (phoneFromProfile.isNotEmpty)
                    _DonorInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phoneFromProfile,
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),

          if (isFund)
            _DonorInfoRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: 'Rs. ${amount.toStringAsFixed(0)}',
            ),

          _DonorInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: controller.formatDate(dateValue),
          ),

          if (isFund &&
              (donation['paymentMethod'] ?? '').toString().isNotEmpty)
            _DonorInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment',
              value: donation['paymentMethod'].toString(),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late Color color;
    late Color background;
    late String label;

    switch (status) {
      case 'approved':
        color = const Color(0xFF1565C0);
        background = const Color(0xFFE3F2FD);
        label = 'Approved';
        break;

      case 'completed':
        color = const Color(0xFF0F6E4F);
        background = const Color(0xFFE6F5EE);
        label = 'Completed';
        break;

      case 'rejected':
        color = const Color(0xFFC0392B);
        background = const Color(0xFFFCEBEA);
        label = 'Rejected';
        break;

      default:
        color = const Color(0xFFDB7C26);
        background = const Color(0xFFFFF3E4);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DonorInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DonorInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14251E),
              ),
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

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: _emerald,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14251E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14251E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
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