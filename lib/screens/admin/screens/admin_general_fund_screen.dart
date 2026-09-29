// ============================================================
// FILE: lib/screens/admin/screens/admin_general_fund_screen.dart (NEW)
//
// PURPOSE
// Admin-facing General Fund monitor — total received, allocated,
// remaining, and the full allocation history, per "Admin should
// be able to monitor: total received, allocated amount, remaining
// balance, allocation records." Read-only, matching Admin's
// "primarily monitoring" role — allocating is a Manager action
// (see GeneralFundScreen).
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/general_fund_controller.dart';

class AdminGeneralFundScreen extends StatelessWidget {
  const AdminGeneralFundScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GeneralFundController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('General Fund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: controller.summaryStream,
        builder: (context, summarySnap) {
          final Map<String, dynamic> summary =
              (summarySnap.data?.data() as Map<String, dynamic>?) ?? {};
          final double totalReceived = controller.numberFrom(summary['totalReceived']);
          final double totalAllocated = controller.numberFrom(summary['totalAllocated']);
          final double remaining = (totalReceived - totalAllocated).clamp(0, totalReceived);
          final double progress = totalReceived > 0 ? (totalAllocated / totalReceived).clamp(0.0, 1.0) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('General Support Fund', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _StatColumn(label: 'Received', value: totalReceived)),
                          Container(width: 1, height: 34, color: Colors.white.withOpacity(0.25)),
                          Expanded(child: _StatColumn(label: 'Allocated', value: totalAllocated)),
                          Container(width: 1, height: 34, color: Colors.white.withOpacity(0.25)),
                          Expanded(child: _StatColumn(label: 'Remaining', value: remaining)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${(progress * 100).toInt()}% allocated', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 17, color: _green),
                    SizedBox(width: 6),
                    Text('Allocation History', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: controller.allocationsStream,
                  builder: (context, allocSnap) {
                    if (allocSnap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2)),
                      );
                    }

                    final docs = allocSnap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 38, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('No allocations yet.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _AllocationTile(data: data, controller: controller);
                      }).toList(),
                    );
                  },
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

class _StatColumn extends StatelessWidget {
  final String label;
  final double value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rs. ${value.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
      ],
    );
  }
}

class _AllocationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final GeneralFundController controller;

  const _AllocationTile({required this.data, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  IconData _iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Maintenance':
        return Icons.build_rounded;
      case 'Emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String category = (data['category'] ?? 'Other').toString();
    final double amount = controller.numberFrom(data['amount']);
    final String note = (data['note'] ?? '').toString();
    final String allocatedByName = (data['allocatedByName'] ?? 'Manager').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(11)),
            child: Icon(_iconFor(category), color: _green, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold))),
                    Text('Rs. ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: _green)),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(note, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                ],
                const SizedBox(height: 6),
                Text(
                  'By $allocatedByName · ${controller.formatDate(data['allocatedAt'])}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}