// ============================================================
// FILE: lib/screens/manager/screens/general_fund_screen.dart (NEW)
//
// PURPOSE
// Manager-facing General Fund screen: shows total received /
// allocated / remaining, lets the Manager allocate money to an
// approved operational need (Food/Utilities/Medical/Maintenance/
// Emergency/Other), and shows the full allocation history for
// transparency — matching the requirement to "keep allocation
// history" and let Manager "allocate General Fund to approved
// operational needs".
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/general_fund_controller.dart';

class GeneralFundScreen extends StatelessWidget {
  const GeneralFundScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GeneralFundController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(totalReceived: totalReceived, totalAllocated: totalAllocated, remaining: remaining),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: remaining <= 0
                        ? null
                        : () => _showAllocateSheet(context, controller, totalReceived, totalAllocated),
                    icon: const Icon(Icons.pie_chart_rounded),
                    label: const Text('Allocate Funds', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emerald,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (remaining <= 0 && totalReceived > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'The entire fund has been allocated.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 17, color: _emerald),
                    const SizedBox(width: 6),
                    const Text('Allocation History', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: controller.allocationsStream,
                  builder: (context, allocSnap) {
                    if (allocSnap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator(color: _emerald, strokeWidth: 2)),
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

  void _showAllocateSheet(
      BuildContext context,
      GeneralFundController controller,
      double totalReceived,
      double totalAllocated,
      ) {
    controller.amountController.clear();
    controller.noteController.clear();
    controller.selectedCategory.value = controller.categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AllocateFundsSheet(
        controller: controller,
        totalReceived: totalReceived,
        totalAllocated: totalAllocated,
      ),
    );
  }
}

// ==========================================================================
// SUMMARY CARD
// ==========================================================================
class _SummaryCard extends StatelessWidget {
  final double totalReceived;
  final double totalAllocated;
  final double remaining;

  const _SummaryCard({
    required this.totalReceived,
    required this.totalAllocated,
    required this.remaining,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);

  @override
  Widget build(BuildContext context) {
    final double progress = totalReceived > 0 ? (totalAllocated / totalReceived).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_emerald, _mint], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _emerald.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
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
                child: Text(
                  'General Support Fund',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
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
          Text(
            '${(progress * 100).toInt()}% allocated',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
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

// ==========================================================================
// ALLOCATION TILE
// ==========================================================================
class _AllocationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final GeneralFundController controller;

  const _AllocationTile({required this.data, required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

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
            decoration: BoxDecoration(color: const Color(0xFFE6F5EE), borderRadius: BorderRadius.circular(11)),
            child: Icon(_iconFor(category), color: _emerald, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(category, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: _emerald),
                    ),
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

// ==========================================================================
// ALLOCATE FUNDS SHEET
// ==========================================================================
class _AllocateFundsSheet extends StatelessWidget {
  final GeneralFundController controller;
  final double totalReceived;
  final double totalAllocated;

  const _AllocateFundsSheet({
    required this.controller,
    required this.totalReceived,
    required this.totalAllocated,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final double remaining = totalReceived - totalAllocated;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Allocate Funds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Rs. ${remaining.toStringAsFixed(0)} currently unallocated',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 18),

            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.categories.map((cat) {
                final bool sel = controller.selectedCategory.value == cat;
                return GestureDetector(
                  onTap: () => controller.selectedCategory.value = cat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _emerald : const Color(0xFFF4FAF7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _emerald : Colors.grey.shade300),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 16),

            const Text('Amount (Rs.) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 40000',
                filled: true,
                fillColor: const Color(0xFFF4FAF7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Note (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Monthly grocery restock for October',
                filled: true,
                fillColor: const Color(0xFFF4FAF7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                  final bool ok = await controller.allocateFunds(
                    totalReceived: totalReceived,
                    totalAllocated: totalAllocated,
                  );
                  if (ok && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Confirm Allocation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}