// ============================================================
// FILE: lib/screens/admin/tabs/admin_inventory_tab.dart
//
// CHANGE: 'Fund' is now a selectable type filter. Fund donation
// cards route to the SAME FundDonationDetailScreen already built
// for Manager (Phase 4) — reused directly, not duplicated, with
// Admin's own green theme colors passed in. Resource donations
// (Online/Desk-based/Volunteer Pickup) still route to the
// existing DonationFullDetailScreen — completely unchanged.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_donations_controller.dart';
import '../screens/donation_full_detail_screen.dart';
import '../../manager/screens/fund_donation_detail_screen.dart';
import '../../../controllers/admin_donations_controller.dart' show safeParseQty;
import '../../../controllers/financial_summary_controller.dart';

class AdminInventoryTab extends StatelessWidget {
  const AdminInventoryTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminDonationsController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventory Management',
                                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                            Text('Manage donations, resources and fund verification',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAddDonationSheet(context, controller),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Add Donation', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Total Funds Card — NAYA ─────────────────────────────────────────
            GetBuilder<FinancialSummaryController>(
              init: FinancialSummaryController(),
              builder: (fc) => Obx(() {
                final total = fc.totalReceived.value;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1B6B3A), Color(0xFF2D8A52)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Funds', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('Rs. ${total.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
            // ── Summary Row ────────────────────────────────────────
            Obx(() => Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  _SummaryChip(label: 'Total', value: controller.totalCount, color: _green, bg: const Color(0xFFE8F5E9)),
                  const SizedBox(width: 8),
                  _SummaryChip(label: 'Pending', value: controller.pendingCount, color: Colors.orange[700]!, bg: Colors.orange[50]!),
                  const SizedBox(width: 8),
                  _SummaryChip(label: 'Approved', value: controller.approvedCount, color: Colors.blue[700]!, bg: Colors.blue[50]!),
                  const SizedBox(width: 8),
                  _SummaryChip(label: 'Completed', value: controller.completedCount, color: _green, bg: const Color(0xFFE8F5E9)),
                ],
              ),
            )),

            // ── Type Filter Tabs (now includes 'Fund') ─────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Obx(() {
                final sel = controller.selectedTypeFilter.value; // explicit read for GetX
                return SizedBox(
                  height: 34,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: controller.typeFilters.map((f) {
                        final isSel = sel == f;
                        return GestureDetector(
                          onTap: () => controller.selectedTypeFilter.value = f,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? _green : const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _green : Colors.grey.shade300),
                            ),
                            child: Text(f,
                                style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.grey[700],
                                    fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            ),

            // ── Category Filter Chips ───────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Obx(() {
                final sel = controller.selectedCategoryFilter.value; // explicit read for GetX
                return SizedBox(
                  height: 32,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: controller.filterCategories.map((cat) {
                        final isSel = sel == cat;
                        return GestureDetector(
                          onTap: () => controller.selectedCategoryFilter.value = cat,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFE8F5E9) : const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _green : Colors.grey.shade300),
                            ),
                            child: Text(cat,
                                style: TextStyle(fontSize: 11, color: isSel ? _green : Colors.grey[600],
                                    fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            ),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                final loading = controller.isLoading.value;
                final search = controller.searchQuery.value;
                final typeF = controller.selectedTypeFilter.value;
                final categoryF = controller.selectedCategoryFilter.value;
                final statusF = controller.selectedStatusFilter.value;

                if (loading) {
                  return const Center(child: CircularProgressIndicator(color: _green));
                }

                final list = controller.filtered;

                if (list.isEmpty) {
                  return _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _DonationCard(data: list[index], controller: controller),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDonationSheet(BuildContext context, AdminDonationsController controller) {
    controller.clearAddForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddDonationSheet(controller: controller),
    );
  }
}

// ==========================================================================
// SUMMARY CHIP
// ==========================================================================
class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  const _SummaryChip({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// DONATION CARD — routes to fund vs resource detail screens
// ==========================================================================
class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AdminDonationsController controller;
  const _DonationCard({required this.data, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  Map<String, dynamic> _typeInfo(bool isFund, String logistics) {
    if (isFund) {
      return {'label': 'Fund Donation', 'icon': Icons.payments_outlined, 'color': const Color(0xFF6A1B9A)};
    }
    switch (logistics) {
      case 'online':
        return {'label': 'Online', 'icon': Icons.local_shipping_outlined, 'color': const Color(0xFF2563EB)};
      case 'pickup':
        return {'label': 'Volunteer Pickup', 'icon': Icons.directions_bike_outlined, 'color': const Color(0xFF6A1B9A)};
      default:
        return {'label': 'Desk-based', 'icon': Icons.store_outlined, 'color': const Color(0xFFDB7C26)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final String id = data['id'] ?? '';
    final bool isFund = data['type'] == 'fund' || data.containsKey('amount');
    final String itemName = isFund ? '' : (data['itemName'] ?? 'Item');
    final String category = data['category'] ?? '';
// NAYA — safe hai
    final int quantity = safeParseQty(data['quantity']);
    final double amount = (data['amount'] ?? 0).toDouble();
    final String campaignName = data['campaignName'] ?? '';
    final String donorName = data['donorName'] ?? data['userEmail'] ?? data['donorEmail'] ?? 'Donor';
    final String status = data['status'] ?? 'pending';
    final String logistics = (data['logisticsType'] ?? data['donationType'] ?? 'desk').toString();
    final String imageUrl = isFund ? (data['paymentProofUrl'] ?? '') : (data['itemImageUrl'] ?? '');
    final dynamic ts = data['createdAt'];
    final typeInfo = _typeInfo(isFund, logistics);

    String dateStr = '';
    try {
      final d = (ts as Timestamp).toDate();
      dateStr = '${d.day}/${d.month}/${d.year}';
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        if (isFund) {
          Get.to(
                () => FundDonationDetailScreen(
              docId: id,
              data: data,
              primaryColor: _green,
              secondaryColor: const Color(0xFF2D8A52),
            ),
            transition: Transition.rightToLeft,
          );
        } else {
          Get.to(() => DonationFullDetailScreen(donationId: id, data: data), transition: Transition.rightToLeft);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            isFund
                ? Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.payments_rounded, color: Color(0xFF6A1B9A), size: 24),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFund ? 'Rs. ${amount.toStringAsFixed(0)}${campaignName.isNotEmpty ? ' — $campaignName' : ''}' : itemName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFund ? donorName : '$donorName · ${category.isNotEmpty ? category : ''} ${quantity > 0 ? 'x$quantity' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // NAYA — Flexible ke sath, ellipsis pe truncate hoga, overflow nahi
                  Row(
                    children: [
                      Icon(typeInfo['icon'], size: 11, color: typeInfo['color']),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          typeInfo['label'],
                          style: TextStyle(fontSize: 10, color: typeInfo['color'], fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: TextStyle(fontSize: 9.5, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 54, height: 54,
    color: const Color(0xFFE8F5E9),
    child: const Icon(Icons.inventory_2_outlined, color: _green, size: 22),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c; Color bg;
    switch (status) {
      case 'completed': c = const Color(0xFF1B6B3A); bg = const Color(0xFFE8F5E9); break;
      case 'rejected': c = Colors.red[700]!; bg = Colors.red[50]!; break;
      case 'pending': c = Colors.orange[700]!; bg = Colors.orange[50]!; break;
      default: c = Colors.blue[700]!; bg = Colors.blue[50]!;
    }
    final label = status.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 9.5, color: c, fontWeight: FontWeight.w600)),
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
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text('No donations found', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ==========================================================================
// ADD DONATION SHEET (resource donations only — unchanged from before)
// ==========================================================================
class _AddDonationSheet extends StatelessWidget {
  final AdminDonationsController controller;
  const _AddDonationSheet({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminDonationsController>(
      builder: (c) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Add Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('For walk-in or manually recorded resource donations', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: c.pickAddFormImage,
                child: Container(
                  height: 110, width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14), border: Border.all(color: _green.withOpacity(0.3))),
                  child: c.addFormImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(c.addFormImage!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _green, size: 28),
                    SizedBox(height: 6),
                    Text('Add Item Photo', style: TextStyle(color: _green, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              _field('Donor Name *', c.donorNameCtrl, 'e.g. Ahmed Khan'),
              const SizedBox(height: 10),
              _field('Donor Contact (optional)', c.donorContactCtrl, 'Phone or email'),
              const SizedBox(height: 10),

              const Text('Donation Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _typeBtn(c, 'desk', 'Desk-based', Icons.store_outlined),
                const SizedBox(width: 8),
                _typeBtn(c, 'online', 'Online', Icons.local_shipping_outlined),
                const SizedBox(width: 8),
                _typeBtn(c, 'pickup', 'Pickup', Icons.directions_bike_outlined),
              ]),
              const SizedBox(height: 14),

              const Text('Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: c.categories.map((cat) {
                    final sel = c.selectedCategory == cat;
                    return GestureDetector(
                      onTap: () { c.selectedCategory = cat; c.update(); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: sel ? _green : const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? _green : Colors.grey.shade300)),
                        child: Text(cat, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              _field('Item Name *', c.itemNameCtrl, 'e.g. Rice bags'),
              const SizedBox(height: 10),
              _field('Quantity *', c.quantityCtrl, 'e.g. 10', keyboardType: TextInputType.number),
              const SizedBox(height: 10),

              const Text('Condition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: c.conditions.map((cond) {
                  final sel = c.selectedCondition == cond;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { c.selectedCondition = cond; c.update(); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: sel ? _green : const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? _green : Colors.grey.shade300)),
                        child: Text(cond, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey[700])),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              _field('Description (optional)', c.descriptionCtrl, 'Item details...', maxLines: 2),
              const SizedBox(height: 10),
              _field('Notes (optional)', c.notesCtrl, 'Any additional info...', maxLines: 2),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: c.isSaving.value ? null : () async {
                    bool ok = await c.addManualDonation();
                    if (ok && context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: c.isSaving.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Donation Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(AdminDonationsController c, String value, String label, IconData icon) {
    final sel = c.selectedDonationType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { c.selectedDonationType = value; c.update(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: sel ? _green.withOpacity(0.1) : const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _green : Colors.grey.shade300, width: sel ? 1.5 : 1)),
          child: Column(children: [
            Icon(icon, size: 18, color: sel ? _green : Colors.grey[400]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10.5, color: sel ? _green : Colors.grey[600], fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true, fillColor: const Color(0xFFF4F6F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green)),
          ),
        ),
      ],
    );
  }
}