import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_donations_controller.dart';

class DonationFullDetailScreen extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;
  const DonationFullDetailScreen({super.key, required this.donationId, required this.data});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDonationsController>();
    final String logistics = (data['logisticsType'] ?? data['donationType'] ?? 'desk').toString();
    final String status = data['status'] ?? 'pending';
    final String? donorId = data['donorId'] as String?;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Donation Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────
            _buildImageSection(context),
            const SizedBox(height: 14),

            // ── Status Timeline ────────────────────────────────────
            _TimelineCard(status: status, logistics: logistics),
            const SizedBox(height: 14),

            // ── Donor Information ──────────────────────────────────
            FutureBuilder<Map<String, dynamic>?>(
              future: controller.fetchDonorProfile(donorId),
              builder: (context, snap) {
                final donorProfile = snap.data;
                return _SectionCard(
                  title: 'Donor Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _row('Name', donorProfile?['name'] ?? data['donorName'] ?? '-'),
                    _row('Email', donorProfile?['email'] ?? data['userEmail'] ?? data['donorEmail'] ?? '-'),
                    if (donorId != null) _row('Donor ID', donorId),
                    if (donorProfile?['phone'] != null) _row('Phone', donorProfile!['phone']),
                    if (data['donorContact'] != null && data['donorContact'].toString().isNotEmpty)
                      _row('Contact', data['donorContact']),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // ── Donation Information ────────────────────────────────
            _SectionCard(
              title: 'Donation Information',
              icon: Icons.receipt_long_outlined,
              children: [
                _row('Donation ID', donationId),
                _row('Type', (data['type'] ?? 'resource') == 'fund' ? 'Fund' : 'Resource'),
                if (data['category'] != null) _row('Category', data['category']),
                if (data['itemName'] != null) _row('Item Name', data['itemName']),
                if (data['quantity'] != null) _row('Quantity', '${data['quantity']}'),
                if (data['condition'] != null) _row('Condition', data['condition']),
                if (data['description'] != null && data['description'].toString().isNotEmpty)
                  _row('Description', data['description']),
                if (data['campaignName'] != null) _row('Campaign', data['campaignName']),
                _row('Donation Type', _logisticsLabel(logistics)),
                if (data['amount'] != null) _row('Amount', 'Rs. ${data['amount']}'),
                if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                  _row('Notes', data['notes']),
                if (data['source'] == 'admin_manual') _row('Source', 'Added by Admin'),
              ],
            ),
            const SizedBox(height: 14),

            // ── Type-specific section ───────────────────────────────
            if (logistics == 'online') _OnlineSection(data: data),
            if (logistics == 'desk') _DeskSection(data: data),
            if (logistics == 'pickup')
              FutureBuilder<Map<String, dynamic>?>(
                future: controller.fetchLinkedTask(donationId),
                builder: (context, snap) => _PickupSection(task: snap.data),
              ),
            const SizedBox(height: 14),

            // ── Timestamps ───────────────────────────────────────────
            _TimestampsCard(data: data),
            const SizedBox(height: 20),

            // ── Actions ────────────────────────────────────────────
            _ActionButtons(donationId: donationId, status: status, logistics: logistics, data: data, controller: controller),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final String imageUrl = data['itemImageUrl'] ?? data['paymentProofUrl'] ?? '';
    return GestureDetector(
      onTap: imageUrl.isEmpty ? null : () => showDialog(
        context: context,
        builder: (_) => Dialog(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, fit: BoxFit.contain))),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl.isEmpty
            ? Container(height: 180, width: double.infinity, color: Colors.white,
            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40))
            : Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.white,
                child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]))),
      ),
    );
  }

  String _logisticsLabel(String l) {
    switch (l) {
      case 'online': return 'Online (Courier)';
      case 'pickup': return 'Volunteer Pickup';
      default: return 'Desk-based / Walk-in';
    }
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminDonationsController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Donation'),
        content: const Text('This will remove the donation from the list. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.softDelete(donationId);
              Get.back();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// TIMELINE CARD
// ==========================================================================
class _TimelineCard extends StatelessWidget {
  final String status;
  final String logistics;
  const _TimelineCard({required this.status, required this.logistics});

  static const Color _green = Color(0xFF1B6B3A);

  List<String> get _steps {
    if (logistics == 'online') return ['submitted', 'approved', 'in_transit', 'received', 'completed'];
    if (logistics == 'pickup') return ['submitted', 'approved', 'pending_pickup', 'picked_up', 'received', 'completed'];
    return ['submitted', 'approved', 'awaiting_physical', 'received', 'completed'];
  }

  int get _activeIndex {
    final steps = _steps;
    if (status == 'pending') return 0;
    if (status == 'rejected') return -1;
    final idx = steps.indexOf(status);
    return idx == -1 ? 0 : idx;
  }

  String _label(String s) => s.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final active = _activeIndex;
    final isRejected = status == 'rejected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: isRejected
          ? Row(children: [
        Icon(Icons.cancel_rounded, color: Colors.red[700]),
        const SizedBox(width: 10),
        const Text('Donation Rejected', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
      ])
          : Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final isDone = i <= active;
              final isLast = i == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: isDone ? _green : Colors.grey[200], shape: BoxShape.circle),
                            child: Icon(isDone ? Icons.check_rounded : Icons.circle, size: isDone ? 13 : 6, color: isDone ? Colors.white : Colors.grey[400]),
                          ),
                          const SizedBox(height: 4),
                          Text(_label(steps[i]), style: TextStyle(fontSize: 7.5, color: isDone ? _green : Colors.grey[400], fontWeight: isDone ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (!isLast) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 16), color: i < active ? _green : Colors.grey[200])),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// TYPE-SPECIFIC SECTIONS
// ==========================================================================
class _OnlineSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OnlineSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Online / Courier Details',
      icon: Icons.local_shipping_outlined,
      children: [
        if (data['courierName'] != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Courier: ${data['courierName']}', style: const TextStyle(fontSize: 13))),
        if (data['trackingId'] != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Tracking ID: ${data['trackingId']}', style: const TextStyle(fontSize: 13))),
        if (data['receiptUrl'] != null && data['receiptUrl'].toString().isNotEmpty)
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(data['receiptUrl']))),
            child: const Text('View Receipt →', style: TextStyle(fontSize: 13, color: Color(0xFF1B6B3A), fontWeight: FontWeight.w600)),
          ),
        if (data['courierName'] == null && data['trackingId'] == null)
          Text('No courier information provided.', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
}

class _DeskSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DeskSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Desk-based / Walk-in',
      icon: Icons.store_outlined,
      children: [
        Text(
          'Donor will personally bring this donation to Little Smiles Orphan Home.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _PickupSection extends StatelessWidget {
  final Map<String, dynamic>? task;
  const _PickupSection({required this.task});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Volunteer Pickup Details',
      icon: Icons.directions_bike_outlined,
      children: task == null
          ? [Text('No volunteer assigned yet.', style: TextStyle(fontSize: 12.5, color: Colors.grey[500]))]
          : [
        _kv('Volunteer', task!['volunteerName'] ?? '-'),
        _kv('Volunteer ID', task!['volunteerId'] ?? '-'),
        _kv('Task Status', task!['status'] ?? '-'),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 100, child: Text(k, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );
}

// ==========================================================================
// TIMESTAMPS CARD
// ==========================================================================
class _TimestampsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TimestampsCard({required this.data});

  String _fmt(dynamic ts) {
    if (ts == null) return '';
    try {
      final d = (ts as Timestamp).toDate();
      const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year} • $hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, dynamic>>[
      MapEntry('Submitted', data['createdAt']),
      MapEntry('Approved', data['approvedAt']),
      MapEntry('Picked Up', data['pickedUpAt']),
      MapEntry('Received', data['receivedAt']),
      MapEntry('Completed', data['completedAt']),
      MapEntry('Rejected', data['rejectedAt']),
    ].where((e) => e.value != null).toList();

    if (entries.isEmpty) return const SizedBox();

    return _SectionCard(
      title: 'Timeline History',
      icon: Icons.schedule_rounded,
      children: entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(_fmt(e.value), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      )).toList(),
    );
  }
}

// ==========================================================================
// ACTION BUTTONS
// ==========================================================================
class _ActionButtons extends StatelessWidget {
  final String donationId;
  final String status;
  final String logistics;
  final Map<String, dynamic> data;
  final AdminDonationsController controller;

  const _ActionButtons({
    required this.donationId, required this.status, required this.logistics,
    required this.data, required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  List<Map<String, dynamic>> get _nextOptions {
    if (status == 'pending') {
      return [
        {'label': 'Approve', 'value': 'approved', 'color': _green},
        {'label': 'Reject', 'value': 'rejected', 'color': const Color(0xFFC0392B)},
      ];
    }
    if (status == 'approved') {
      if (logistics == 'online') return [{'label': 'Mark In Transit', 'value': 'in_transit', 'color': const Color(0xFF2563EB)}];
      if (logistics == 'pickup') return [{'label': 'Mark Pending Pickup', 'value': 'pending_pickup', 'color': const Color(0xFF6A1B9A)}];
      return [{'label': 'Mark Awaiting Physical Submission', 'value': 'awaiting_physical', 'color': const Color(0xFFDB7C26)}];
    }
    if (status == 'in_transit' || status == 'awaiting_physical' || status == 'picked_up') {
      return [{'label': 'Mark Received', 'value': 'received', 'color': _green}];
    }
    if (status == 'pending_pickup') {
      return [{'label': 'Mark Picked Up', 'value': 'picked_up', 'color': const Color(0xFF6A1B9A)}];
    }
    if (status == 'received') {
      return [{'label': 'Mark Completed', 'value': 'completed', 'color': _green}];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final options = _nextOptions;
    if (options.isEmpty) return const SizedBox();

    return Column(
      children: options.map((opt) {
        final isReject = opt['value'] == 'rejected';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: isReject
                ? OutlinedButton(
              onPressed: () => _showRejectDialog(context),
              style: OutlinedButton.styleFrom(foregroundColor: opt['color'], side: BorderSide(color: opt['color']), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.w600)),
            )
                : ElevatedButton(
              onPressed: () => controller.updateStatus(donationId, opt['value']),
              style: ElevatedButton.styleFrom(backgroundColor: opt['color'], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(opt['label'], style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Donation'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Reason for rejection')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.updateStatus(donationId, 'rejected', reason: reasonCtrl.text.trim());
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SECTION CARD
// ==========================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: _green),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}