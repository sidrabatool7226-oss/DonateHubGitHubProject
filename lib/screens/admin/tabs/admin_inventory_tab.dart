import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/inventory_controller.dart';

class AdminInventoryTab extends StatelessWidget {
  const AdminInventoryTab({super.key});

  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context, controller),
              icon: const Icon(Icons.add_rounded, color: _purple, size: 18),
              label: const Text(
                'Add Item',
                style: TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Category Filter ────────────────────────────────────────
          _CategoryFilter(controller: controller),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: Obx(() => StreamBuilder<QuerySnapshot>(
              stream: controller.inventoryStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(color: _purple),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _EmptyState(
                    category: controller.selectedCategory.value,
                  );
                }

                int urgent = docs
                    .where((d) =>
                (d.data() as Map)['isUrgent'] == true)
                    .length;

                return Column(
                  children: [
                    _StatsBar(
                        total: docs.length, urgent: urgent),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data()
                          as Map<String, dynamic>;
                          return _InventoryCard(
                            docId: doc.id,
                            data: data,
                            controller: controller,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            )),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(
      BuildContext context, InventoryController controller) {
    controller.clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddItemSheet(controller: controller),
    );
  }
}

// ==========================================================================
// CATEGORY FILTER
// ==========================================================================
class _CategoryFilter extends StatelessWidget {
  final InventoryController controller;
  const _CategoryFilter({required this.controller});

  static const Color _purple = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final cat = controller.categories[index];
            return Obx(() {
              final isSelected =
                  controller.selectedCategory.value == cat;
              return GestureDetector(
                onTap: () =>
                controller.selectedCategory.value = cat,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? _purple : const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _purple
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

// ==========================================================================
// STATS BAR
// ==========================================================================
class _StatsBar extends StatelessWidget {
  final int total;
  final int urgent;
  const _StatsBar({required this.total, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Pill(
            label: 'Total Items',
            value: '$total',
            color: const Color(0xFF6A1B9A),
            bg: const Color(0xFFF3E5F5),
          ),
          const SizedBox(width: 10),
          _Pill(
            label: 'Urgent',
            value: '$urgent',
            color: Colors.red[700]!,
            bg: Colors.red[50]!,
          ),
          const Spacer(),
          Icon(Icons.inventory_2_outlined,
              size: 16, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            'Stock Overview',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _Pill({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// INVENTORY CARD
// ==========================================================================
class _InventoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final InventoryController controller;

  const _InventoryCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _purple = Color(0xFF6A1B9A);

  // Source badge info
  Map<String, dynamic> _sourceInfo(String source) {
    switch (source) {
      case 'tcs':
        return {
          'label': 'TCS',
          'icon': Icons.local_shipping_outlined,
          'color': Colors.orange[700]!,
          'bg': Colors.orange[50]!,
        };
      case 'volunteer':
        return {
          'label': 'Volunteer',
          'icon': Icons.directions_bike_outlined,
          'color': Colors.green[700]!,
          'bg': Colors.green[50]!,
        };
      default:
        return {
          'label': 'Walk-in',
          'icon': Icons.store_outlined,
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
        };
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood_outlined;
      case 'Clothes': return Icons.checkroom_outlined;
      case 'Books': return Icons.menu_book_outlined;
      case 'Furniture': return Icons.chair_outlined;
      case 'Medicine': return Icons.medical_services_outlined;
      case 'Stationery': return Icons.edit_outlined;
      case 'Shoes': return Icons.directions_walk_outlined;
      case 'Blankets': return Icons.bed_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['itemName'] ?? '';
    final String category = data['category'] ?? '';
    final int quantity = data['quantity'] ?? 0;
    final bool isUrgent = data['isUrgent'] ?? false;
    final String source = data['source'] ?? 'desktop';
    final String donorName = data['donorName'] ?? '';
    final Map<String, dynamic> srcInfo = _sourceInfo(source);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isUrgent
            ? Border.all(color: Colors.red[300]!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red[50]
                    : const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(category),
                color: isUrgent ? Colors.red[700] : _purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + urgent
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '⚡ Urgent',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category + Source badges
                  Row(
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                              fontSize: 10, color: _purple),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Source badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: srcInfo['bg'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              srcInfo['icon'],
                              size: 10,
                              color: srcInfo['color'],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              srcInfo['label'],
                              style: TextStyle(
                                fontSize: 10,
                                color: srcInfo['color'],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Donor name
                  if (donorName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'From: $donorName',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quantity control
            Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      controller.updateQuantity(docId, quantity + 1),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                    const Icon(Icons.add, size: 16, color: _purple),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: quantity <= 5
                        ? Colors.red[700]
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    if (quantity > 0) {
                      controller.updateQuantity(docId, quantity - 1);
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: quantity > 0
                          ? const Color(0xFFF3E5F5)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: quantity > 0
                          ? _purple
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Actions
            Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      controller.toggleUrgent(docId, isUrgent),
                  child: Icon(
                    isUrgent
                        ? Icons.warning_rounded
                        : Icons.warning_outlined,
                    size: 22,
                    color: isUrgent
                        ? Colors.red[700]
                        : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Icon(Icons.delete_outline,
                      size: 22, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item'),
        content: const Text(
            'Remove this item from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteItem(docId);
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
// ADD ITEM SHEET
// ==========================================================================
class _AddItemSheet extends StatefulWidget {
  final InventoryController controller;
  const _AddItemSheet({required this.controller});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _selectedCategory = 'Food';
  static const Color _purple = Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    final cats = widget.controller.categories
        .where((c) => c != 'All')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Add Inventory Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manual entry for walk-in or courier donations',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // ── Source Selection ─────────────────────────────────────
            const Text(
              'How item was received? *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Obx(() => Row(
              children: [
                _SourceBtn(
                  label: 'Walk-in',
                  sublabel: 'Donor came in person',
                  icon: Icons.store_outlined,
                  value: 'desktop',
                  selected: widget.controller.selectedEntrySource.value,
                  color: _purple,
                  onTap: () => widget
                      .controller.selectedEntrySource.value = 'desktop',
                ),
                const SizedBox(width: 8),
                _SourceBtn(
                  label: 'TCS / Courier',
                  sublabel: 'Received by post',
                  icon: Icons.local_shipping_outlined,
                  value: 'tcs',
                  selected: widget.controller.selectedEntrySource.value,
                  color: Colors.orange[700]!,
                  onTap: () => widget
                      .controller.selectedEntrySource.value = 'tcs',
                ),
              ],
            )),
            const SizedBox(height: 14),

            // ── Category ─────────────────────────────────────────────
            const Text(
              'Category *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  final sel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? _purple : const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? _purple : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.grey[700],
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Item Name ─────────────────────────────────────────────
            _FormField(
              controller: widget.controller.itemNameController,
              label: 'Item Name *',
              hint: 'e.g. Rice bags, Winter jackets',
            ),
            const SizedBox(height: 10),

            // ── Quantity ──────────────────────────────────────────────
            _FormField(
              controller: widget.controller.quantityController,
              label: 'Quantity *',
              hint: 'e.g. 20',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // ── Donor Name ────────────────────────────────────────────
            _FormField(
              controller: widget.controller.donorNameController,
              label: 'Donor Name (optional)',
              hint: 'e.g. Ahmed Khan',
            ),
            const SizedBox(height: 10),

            // TCS tracking — sirf TCS select kiya ho tab dikhao
            Obx(() => widget.controller.selectedEntrySource.value == 'tcs'
                ? Column(
              children: [
                _FormField(
                  controller:
                  widget.controller.trackingController,
                  label: 'Tracking Number (optional)',
                  hint: 'e.g. TCS-123456789',
                ),
                const SizedBox(height: 10),
              ],
            )
                : const SizedBox()),

            // ── Notes ─────────────────────────────────────────────────
            _FormField(
              controller: widget.controller.notesController,
              label: 'Notes (optional)',
              hint: 'Any additional info...',
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // ── Submit ────────────────────────────────────────────────
            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.controller.isLoading.value
                    ? null
                    : () async {
                  bool ok = await widget.controller
                      .addManualItem(_selectedCategory);
                  if (ok && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Add to Inventory',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// SOURCE BUTTON
// ==========================================================================
class _SourceBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final String value;
  final String selected;
  final Color color;
  final VoidCallback onTap;

  const _SourceBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.08)
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected ? color : Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? color.withOpacity(0.7)
                      : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// FORM FIELD
// ==========================================================================
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF4F6F8),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(0xFF6A1B9A)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// EMPTY STATE
// ==========================================================================
class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            category == 'All'
                ? 'No items in inventory'
                : 'No $category items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Add Item to add stock',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}