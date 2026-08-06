import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonorDonationsTab extends StatelessWidget {
  const DonorDonationsTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, Color(0xFF2D8A52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Donations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track all your donations in real time',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('donations')
                        .where('donorId',
                        isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs =
                          snapshot.data?.docs ?? [];
                      final total = docs.length;
                      final completed = docs
                          .where((d) =>
                      (d.data() as Map)[
                      'status'] ==
                          'completed')
                          .length;
                      final pending = docs
                          .where((d) =>
                      (d.data() as Map)[
                      'status'] ==
                          'pending')
                          .length;

                      return Row(
                        children: [
                          _HeaderStat(
                            value: '$total',
                            label: 'Total',
                            icon: Icons
                                .volunteer_activism_rounded,
                          ),
                          const SizedBox(width: 10),
                          _HeaderStat(
                            value: '$completed',
                            label: 'Completed',
                            icon: Icons
                                .check_circle_rounded,
                          ),
                          const SizedBox(width: 10),
                          _HeaderStat(
                            value: '$pending',
                            label: 'Pending',
                            icon: Icons
                                .pending_actions_rounded,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Donations List ──────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donations')
                    .where('donorId', isEqualTo: uid)
                    .orderBy('createdAt',
                    descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: _green),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _EmptyDonations();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data()
                      as Map<String, dynamic>;
                      return _DonationCard(
                        docId: doc.id,
                        data: data,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// HEADER STAT
// ==========================================================================
class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// DONATION CARD
// ==========================================================================
class _DonationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _DonationCard({
    required this.docId,
    required this.data,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String type = data['type'] ?? 'resource';
    final String status = data['status'] ?? 'pending';
    final String campaign =
        data['campaignName'] ?? '';
    final bool isFund = type == 'fund';

    return GestureDetector(
      onTap: () => Get.to(
            () => DonationDetailScreen(
            docId: docId, data: data),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isFund
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFE0F7FA),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFund
                              ? Icons.payments_rounded
                              : Icons
                              .inventory_2_rounded,
                          color: isFund
                              ? _green
                              : const Color(0xFF00838F),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFund
                                  ? 'Fund Donation — Rs. ${data['amount'] ?? 0}'
                                  : 'Resource — ${data['itemName'] ?? 'Items'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (campaign.isNotEmpty)
                              Text(
                                campaign,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Status
                      _StatusBadge(status: status),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status timeline
                  _StatusTimeline(
                      status: status, isFund: isFund),

                  const SizedBox(height: 10),

                  // Bottom row
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View Details →',
                        style: TextStyle(
                          fontSize: 12,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.blue[400]!;
      case 'completed':
        return Colors.green[500]!;
      case 'rejected':
        return Colors.red[400]!;
      case 'pickup_assigned':
        return Colors.orange[400]!;
      default:
        return Colors.grey[300]!;
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ==========================================================================
// STATUS TIMELINE
// ==========================================================================
class _StatusTimeline extends StatelessWidget {
  final String status;
  final bool isFund;

  const _StatusTimeline({
    required this.status,
    required this.isFund,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final steps = isFund
        ? [
      'Submitted',
      'Verified',
      'Completed',
    ]
        : [
      'Submitted',
      'Approved',
      'Pickup Assigned',
      'Delivered',
      'Completed',
    ];

    int activeStep = _getStep(status, isFund);

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= activeStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone
                            ? _green
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone
                            ? Icons.check_rounded
                            : Icons.circle,
                        color: isDone
                            ? Colors.white
                            : Colors.grey[400],
                        size: isDone ? 14 : 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 9,
                        color: isDone
                            ? _green
                            : Colors.grey[400],
                        fontWeight: isDone
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                        bottom: 18),
                    color: index < activeStep
                        ? _green
                        : Colors.grey[200],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  int _getStep(String status, bool isFund) {
    if (isFund) {
      switch (status) {
        case 'pending': return 0;
        case 'approved': return 1;
        case 'completed': return 2;
        default: return 0;
      }
    } else {
      switch (status) {
        case 'pending': return 0;
        case 'approved': return 1;
        case 'pickup_assigned': return 2;
        case 'delivered': return 3;
        case 'completed': return 4;
        default: return 0;
      }
    }
  }
}

// ==========================================================================
// STATUS BADGE
// ==========================================================================
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.blue[700]!;
        bg = Colors.blue[50]!;
        label = 'Approved';
        icon = Icons.thumb_up_outlined;
        break;
      case 'completed':
        color = Colors.green[700]!;
        bg = Colors.green[50]!;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = Colors.red[700]!;
        bg = Colors.red[50]!;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'pickup_assigned':
        color = Colors.orange[700]!;
        bg = Colors.orange[50]!;
        label = 'Pickup Soon';
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        color = Colors.teal[700]!;
        bg = Colors.teal[50]!;
        label = 'Delivered';
        icon = Icons.done_all_rounded;
        break;
      default:
        color = Colors.grey[700]!;
        bg = Colors.grey[100]!;
        label = 'Pending';
        icon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// DONATION DETAIL SCREEN
// ==========================================================================
class DonationDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DonationDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final String type = data['type'] ?? 'resource';
    final String status = data['status'] ?? 'pending';
    final bool isFund = type == 'fund';
    final String campaign =
        data['campaignName'] ?? '';
    final String paymentMethod =
        data['paymentMethod'] ?? '';
    final String proofUrl =
        data['paymentProofUrl'] ?? '';
    final String itemImageUrl =
        data['itemImageUrl'] ?? '';
    final String pickupAddress =
        data['pickupAddress'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donation Details',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(
              Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status Card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, const Color(0xFF2D8A52)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFund
                          ? Icons.payments_rounded
                          : Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFund
                        ? 'Fund Donation'
                        : 'Resource Donation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isFund)
                    Text(
                      'Rs. ${data['amount'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase()
                          .replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Status Timeline ───────────────────────
            _DetailCard(
              title: 'Donation Progress',
              icon: Icons.timeline_rounded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8),
                child: _StatusTimeline(
                    status: status, isFund: isFund),
              ),
            ),
            const SizedBox(height: 12),

            // ── Donation Info ─────────────────────────
            _DetailCard(
              title: 'Donation Information',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  if (campaign.isNotEmpty)
                    _InfoRow(
                        label: 'Campaign',
                        value: campaign),
                  if (isFund && paymentMethod.isNotEmpty)
                    _InfoRow(
                        label: 'Payment Method',
                        value: paymentMethod),
                  if (!isFund) ...[
                    _InfoRow(
                        label: 'Item',
                        value: data['itemName'] ?? ''),
                    _InfoRow(
                        label: 'Category',
                        value: data['category'] ?? ''),
                    _InfoRow(
                        label: 'Quantity',
                        value:
                        '${data['quantity'] ?? ''}'),
                    _InfoRow(
                        label: 'Condition',
                        value: data['condition'] ?? ''),
                    if (pickupAddress.isNotEmpty)
                      _InfoRow(
                          label: 'Pickup Address',
                          value: pickupAddress),
                  ],
                  _InfoRow(
                      label: 'Submitted',
                      value: _formatDate(
                          data['createdAt'])),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Proof Image ───────────────────────────
            if (proofUrl.isNotEmpty ||
                itemImageUrl.isNotEmpty) ...[
              _DetailCard(
                title: isFund
                    ? 'Payment Proof'
                    : 'Item Image',
                icon: Icons.image_outlined,
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(12),
                  child: Image.network(
                    isFund ? proofUrl : itemImageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                          height: 100,
                          color: Colors.grey[100],
                          child: Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey[400]),
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Volunteer info if pickup assigned ─────
            if (status == 'pickup_assigned' ||
                status == 'delivered') ...[
              _DetailCard(
                title: 'Pickup Information',
                icon: Icons.local_shipping_outlined,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bike_rounded,
                          color: Colors.orange[700],
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status == 'delivered'
                              ? 'Your donation has been collected and delivered to LSOH!'
                              : 'A volunteer has been assigned to collect your donation. Please keep the items ready.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Rejection reason if rejected ──────────
            if (status == 'rejected') ...[
              _DetailCard(
                title: 'Rejection Reason',
                icon: Icons.cancel_outlined,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.red[700],
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['rejectionReason'] ??
                              'Your donation was not approved. Please contact us for more information.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final dt = (ts as dynamic).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(icon, size: 16, color: _green),
              const SizedBox(width: 6),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDonations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No donations yet',
            style: TextStyle(
                fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Start donating to make a difference!',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}