import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/utilization_controller.dart';
import '../screens/utilization_detail_screen.dart';
import '../screens/create_utilization_screen.dart';

class AdminUtilizationTab extends StatelessWidget {
  const AdminUtilizationTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UtilizationController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, _lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Utilization',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Track how donations are used',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(
                              () => CreateUtilizationScreen(),
                          transition: Transition.rightToLeft,
                        ),
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.2),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Colors.white,
                                  size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Add Record',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search bar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (val) =>
                      controller.searchQuery.value =
                          val,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        hintStyle: TextStyle(
                            color: Colors.white
                                .withOpacity(0.6),
                            fontSize: 13),
                        prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                            size: 18),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter chips ───────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 34,
                child: Obx(() {
                  final selected = controller.selectedFilter.value; // ✅ Explicit read yahan
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: controller.filterOptions.map((f) {
                        final isSel = selected == f;
                        return GestureDetector(
                          onTap: () => controller.selectedFilter.value = f,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? _green : const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _green : Colors.grey.shade300),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSel ? Colors.white : Colors.grey[700],
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),
            ),

            // ── List ──────────────────────────────────────────────
            // ── List ──────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                // Yeh 2 lines zaroori hain — GetX ko pata chale kis cheez pe react karna hai
                final currentFilter = controller.selectedFilter.value;
                final currentSearch = controller.searchQuery.value;

                return StreamBuilder<QuerySnapshot>(
                  stream: controller.utilizationStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _green),
                      );
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    final allRecords = allDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return data;
                    }).toList();

                    final filtered = controller.filterRecords(allRecords);

                    if (filtered.isEmpty) {
                      return _EmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _UtilizationCard(
                          data: filtered[index],
                          controller: controller,
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// UTILIZATION CARD
// ==========================================================================
class _UtilizationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final UtilizationController controller;

  const _UtilizationCard({
    required this.data,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String id = data['id'] ?? '';
    final String campaign = data['campaignName'] ?? '';
    final String donationType =
        data['donationType'] ?? 'fund';
    final double fundUsed =
    (data['fundAmountUsed'] ?? 0).toDouble();
    final int beneficiaries = data['beneficiaries'] ?? 0;
    final String description = data['description'] ?? '';
    final String date = data['utilizationDate'] ?? '';
    final String status = data['status'] ?? 'draft';
    final List images =
        data['impactImages'] as List? ?? [];
    final List items =
        data['itemsUtilized'] as List? ?? [];
    final bool isCompleted = status == 'completed';

    return GestureDetector(
      onTap: () => Get.to(
            () => UtilizationDetailScreen(data: data),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top colored bar ─────────────────────────────────
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted
                      ? [_green, const Color(0xFF2D8A52)]
                      : [
                    Colors.orange[700]!,
                    Colors.orange[400]!
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Campaign + Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                          status: status,
                          isCompleted: isCompleted),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      if (donationType != 'resource')
                        _StatPill(
                          icon: Icons.payments_outlined,
                          value: 'Rs. ${fundUsed.toStringAsFixed(0)}',
                          label: 'Fund Used',
                          color: _green,
                        ),
                      if (donationType != 'fund')
                        _StatPill(
                          icon: Icons.inventory_2_outlined,
                          value: '${items.length} items',
                          label: 'Resources',
                          color: const Color(0xFF00838F),
                        ),
                      _StatPill(
                        icon: Icons.people_outline,
                        value: '$beneficiaries',
                        label: 'Beneficiaries',
                        color: const Color(0xFF6A1B9A),
                      ),
                    ],
                  ),

                  // Impact images preview
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                        images.length.clamp(0, 5),
                        itemBuilder: (context, i) {
                          return Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(
                                right: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(
                                    images[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: images.length > 5 &&
                                i == 4
                                ? Container(
                              decoration:
                              BoxDecoration(
                                color: Colors.black
                                    .withOpacity(0.5),
                                borderRadius:
                                BorderRadius
                                    .circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '+${images.length - 4}',
                                  style: const TextStyle(
                                    color:
                                    Colors.white,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                            )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Actions
                  Row(
                    children: [
                      // View details
                      Expanded(
                        child: _CardBtn(
                          label: 'View Details',
                          icon: Icons.visibility_outlined,
                          color: _green,
                          onTap: () => Get.to(
                                () => UtilizationDetailScreen(
                                data: data),
                            transition:
                            Transition.rightToLeft,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Mark complete (only draft)
                      if (!isCompleted) ...[
                        Expanded(
                          child: _CardBtn(
                            label: 'Complete',
                            icon: Icons.check_circle_outline,
                            color: Colors.orange[700]!,
                            onTap: () => controller
                                .markCompleted(
                              id,
                              List<Map<String, dynamic>>.from(
                                  items),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Delete
                      _CardBtnIcon(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: () => _confirmDelete(
                            context, id, controller),
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

  void _confirmDelete(BuildContext context, String id,
      UtilizationController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record'),
        content:
        const Text('Delete this utilization record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteRecord(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SMALL REUSABLE WIDGETS
// ==========================================================================
class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompleted;

  const _StatusBadge(
      {required this.status, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green[50]
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.green[300]!
              : Colors.orange[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green[700]
                  : Colors.orange[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'Completed' : 'Draft',
            style: TextStyle(
              fontSize: 11,
              color: isCompleted
                  ? Colors.green[700]
                  : Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBtnIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardBtnIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border:
          Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
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
            'No utilization records',
            style: TextStyle(
                fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Add Record to create one',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}