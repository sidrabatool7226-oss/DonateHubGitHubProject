import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/utilization_controller.dart';

class CreateUtilizationScreen extends StatelessWidget {
  CreateUtilizationScreen({super.key});

  final UtilizationController controller =
  Get.find<UtilizationController>();

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    controller.clearForm();

    return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'New Utilization Record',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_rounded),
          ),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Campaign Selection ──────────────────────────────
                _SectionCard(
                  title: 'Campaign',
                  icon: Icons.campaign_rounded,
                  child: Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedCampaignId
                        .value.isEmpty
                        ? null
                        : controller.selectedCampaignId.value,
                    hint: Text('Select Campaign',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13)),
                    items: controller.campaigns
                        .map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(
                        c['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 13),
                      ),
                    ))
                        .toList(),
                    onChanged: (val) {
                      controller.selectedCampaignId.value =
                          val ?? '';
                      final camp = controller.campaigns
                          .firstWhere(
                              (c) => c['id'] == val,
                          orElse: () => {});
                      controller.selectedCampaignName.value =
                          camp['title'] ?? '';
                    },
                    decoration: _dropdownDecoration(),
                  )),
                ),
                const SizedBox(height: 12),

                // ── Donation Type ───────────────────────────────────
                _SectionCard(
                  title: 'Donation Type',
                  icon: Icons.category_outlined,
                  child: Obx(() => Row(
                    children: [
                      _TypeBtn(
                        label: 'Fund',
                        icon: Icons.payments_outlined,
                        isSelected: controller
                            .selectedDonationType.value ==
                            'fund',
                        onTap: () => controller
                            .selectedDonationType.value = 'fund',
                        color: _green,
                      ),
                      const SizedBox(width: 8),
                      _TypeBtn(
                        label: 'Resource',
                        icon: Icons.inventory_2_outlined,
                        isSelected: controller
                            .selectedDonationType.value ==
                            'resource',
                        onTap: () => controller
                            .selectedDonationType.value =
                        'resource',
                        color: const Color(0xFF00838F),
                      ),
                      const SizedBox(width: 8),
                      _TypeBtn(
                        label: 'Both',
                        icon: Icons.merge_outlined,
                        isSelected: controller
                            .selectedDonationType.value ==
                            'both',
                        onTap: () => controller
                            .selectedDonationType.value = 'both',
                        color: const Color(0xFF6A1B9A),
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 12),

                // ── Fund Amount (if fund or both) ───────────────────
                Obx(() => controller.selectedDonationType.value !=
                    'resource'
                    ? Column(
                  children: [
                    _SectionCard(
                      title: 'Fund Amount Used',
                      icon: Icons.payments_outlined,
                      child: _InputField(
                        controller:
                        controller.fundAmountController,
                        hint: 'e.g. 15000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
                    : const SizedBox()),

                // ── Inventory Items (if resource or both) ───────────
                Obx(() => controller.selectedDonationType.value !=
                    'fund'
                    ? Column(
                  children: [
                    _SectionCard(
                      title: 'Items Utilized',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: [
                          // Selected items
                          Obx(() {
                            if (controller
                                .selectedInventoryItems
                                .isEmpty) {
                              return Padding(
                                padding:
                                const EdgeInsets.only(
                                    bottom: 10),
                                child: Text(
                                  'No items selected yet',
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12),
                                ),
                              );
                            }
                            return Column(
                              children: controller
                                  .selectedInventoryItems
                                  .map((item) {
                                return Container(
                                  margin:
                                  const EdgeInsets.only(
                                      bottom: 8),
                                  padding:
                                  const EdgeInsets.all(
                                      10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFE0F7FA),
                                    borderRadius:
                                    BorderRadius.circular(
                                        10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              item['itemName'],
                                              style: const TextStyle(
                                                  fontSize:
                                                  13,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600),
                                            ),
                                            Text(
                                              item['category'],
                                              style: TextStyle(
                                                  fontSize:
                                                  11,
                                                  color: Colors
                                                      .grey[
                                                  500]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Qty control
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => controller
                                                .updateItemQty(
                                              item['docId'],
                                              item['quantity'] - 1,
                                            ),
                                            child: const Icon(
                                                Icons.remove,
                                                size: 18),
                                          ),
                                          Padding(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal:
                                                8),
                                            child: Text(
                                              '${item['quantity']}',
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight
                                                      .bold),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => controller
                                                .updateItemQty(
                                              item['docId'],
                                              item['quantity'] + 1,
                                            ),
                                            child: const Icon(
                                                Icons.add,
                                                size: 18),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              final idx = controller
                                                  .selectedInventoryItems
                                                  .indexOf(
                                                  item);
                                              controller
                                                  .selectedInventoryItems
                                                  .removeAt(
                                                  idx);
                                            },
                                            child: Icon(
                                                Icons
                                                    .close_rounded,
                                                size: 18,
                                                color: Colors
                                                    .red[400]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }),

                          // Inventory picker
                          GestureDetector(
                            onTap: () =>
                                _showInventoryPicker(
                                    context, controller),
                            child: Container(
                              width: double.infinity,
                              padding:
                              const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFE8F5E9),
                                borderRadius:
                                BorderRadius.circular(
                                    10),
                                border: Border.all(
                                    color: _green
                                        .withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                                children: [
                                  Icon(Icons.add_rounded,
                                      color: _green,
                                      size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Select Items from Inventory',
                                    style: TextStyle(
                                      color: _green,
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
                    ),
                    const SizedBox(height: 12),
                  ],
                )
                    : const SizedBox()),

                // ── Beneficiaries ───────────────────────────────────
                _SectionCard(
                  title: 'Beneficiaries',
                  icon: Icons.people_outline,
                  child: _InputField(
                    controller:
                    controller.beneficiariesController,
                    hint: 'Number of people benefited',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Description ─────────────────────────────────────
                _SectionCard(
                  title: 'Description *',
                  icon: Icons.description_outlined,
                  child: _InputField(
                    controller:
                    controller.descriptionController,
                    hint:
                    'Describe how donations were utilized...',
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Date ────────────────────────────────────────────
                _SectionCard(
                  title: 'Utilization Date *',
                  icon: Icons.calendar_today_outlined,
                  child: GestureDetector(
                    onTap: () =>
                        controller.pickDate(context),
                    child: Obx(() => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Text(
                            controller.utilizationDate.value
                                .isEmpty
                                ? 'Select date'
                                : controller
                                .utilizationDate.value,
                            style: TextStyle(
                              fontSize: 13,
                              color: controller.utilizationDate
                                  .value.isEmpty
                                  ? Colors.grey[400]
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Colors.grey[400]),
                        ],
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Status ──────────────────────────────────────────
                _SectionCard(
                  title: 'Status',
                  icon: Icons.flag_outlined,
                  child: Obx(() => Row(
                    children: [
                      _TypeBtn(
                        label: 'Save as Draft',
                        icon: Icons.save_outlined,
                        isSelected: controller
                            .selectedStatus.value ==
                            'draft',
                        onTap: () => controller
                            .selectedStatus.value = 'draft',
                        color: Colors.orange[700]!,
                      ),
                      const SizedBox(width: 8),
                      _TypeBtn(
                        label: 'Mark Complete',
                        icon: Icons.check_circle_outline,
                        isSelected: controller
                            .selectedStatus.value ==
                            'completed',
                        onTap: () => controller
                            .selectedStatus.value =
                        'completed',
                        color: _green,
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 12),

                // ── Impact Images ───────────────────────────────────
                _SectionCard(
                  title: 'Impact Images',
                  icon: Icons.photo_library_outlined,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload photos showing how donations were used',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 10),
                      Obx(() => controller
                          .impactImages.isEmpty
                          ? const SizedBox()
                          : SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection:
                          Axis.horizontal,
                          itemCount: controller
                              .impactImages.length,
                          itemBuilder: (ctx, i) {
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin:
                                  const EdgeInsets
                                      .only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius
                                        .circular(10),
                                    image:
                                    DecorationImage(
                                      image: FileImage(
                                          controller
                                              .impactImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () => controller
                                        .removeImpactImage(i),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration:
                                      BoxDecoration(
                                        color: Colors.red,
                                        shape:
                                        BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color:
                                          Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: controller.pickImpactImages,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius:
                            BorderRadius.circular(10),
                            border: Border.all(
                                color: _green.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons
                                      .add_photo_alternate_outlined,
                                  color: _green,
                                  size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Add Impact Photos',
                                style: TextStyle(
                                  color: _green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Proof Documents ─────────────────────────────────
                _SectionCard(
                  title: 'Proof Documents',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload bills, receipts, invoices, or other proof',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 10),

                      // Added docs
                      Obx(() => controller.proofDocuments.isEmpty
                          ? const SizedBox()
                          : Column(
                        children: controller
                            .proofDocuments
                            .asMap()
                            .entries
                            .map((entry) {
                          final i = entry.key;
                          final doc = entry.value;
                          return Container(
                            margin:
                            const EdgeInsets.only(
                                bottom: 8),
                            padding: const EdgeInsets.all(
                                10),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFF4F6F8),
                              borderRadius:
                              BorderRadius.circular(
                                  10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons
                                        .insert_drive_file_outlined,
                                    size: 18,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc['name'],
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => controller
                                      .removeProofDoc(i),
                                  child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color:
                                      Colors.red[400]),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )),

                      // Doc type buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.documentTypes
                            .map((type) {
                          return GestureDetector(
                            onTap: () =>
                                controller.pickProofDocument(type),
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                const Color(0xFFF4F6F8),
                                borderRadius:
                                BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                    Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 14,
                                      color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    type,
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Upload Progress ─────────────────────────────────
                Obx(() => controller.isSaving.value
                    ? Column(
                    children: [
                LinearProgressIndicator(
                value:
                controller.uploadProgress.value,
                    backgroundColor: Colors.grey[200],
// SAHI
                  valueColor: AlwaysStoppedAnimation<Color>(_green),                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(controller.uploadProgress.value * 100).toInt()}%',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            )
                : const SizedBox()),

    // ── Save Button ─────────────────────────────────────
    Obx(() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
    onPressed: controller.isSaving.value
    ? null
        : () async {
    bool ok =
    await controller.saveRecord();
    if (ok) Get.back();
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: _green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius:
    BorderRadius.circular(14),
    ),
    ),
    child: controller.isSaving.value
    ? const SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(
    color: Colors.white,
    strokeWidth: 2.5),
    )
        : const Text(
    'Save Utilization Record',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    ),
    ),
    ),
    )),
    const SizedBox(height: 24),
    ],
    ),
    ),
    );
  }

  void _showInventoryPicker(
      BuildContext context,
      UtilizationController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _InventoryPickerSheet(controller: controller),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
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
        const BorderSide(color: Color(0xFF1B6B3A)),
      ),
    );
  }
}

// ==========================================================================
// INVENTORY PICKER SHEET
// ==========================================================================
class _InventoryPickerSheet extends StatelessWidget {
  final UtilizationController controller;
  const _InventoryPickerSheet({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            'Select Items to Utilize',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount:
              controller.inventoryItems.length,
              itemBuilder: (context, index) {
                final item =
                controller.inventoryItems[index];
                final isSelected = controller
                    .selectedInventoryItems
                    .any((i) =>
                i['docId'] == item['docId']);
                final qty = item['quantity'] ?? 0;

                return GestureDetector(
                  onTap: qty > 0
                      ? () => controller
                      .toggleInventoryItem(item)
                      : null,
                  child: Container(
                    margin:
                    const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF4F6F8),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _green
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(
                              Icons
                                  .check_circle_rounded,
                              color: _green,
                              size: 20)
                        else
                          Icon(
                              Icons
                                  .radio_button_unchecked,
                              color: Colors.grey[400],
                              size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600),
                              ),
                              Text(
                                item['category'] ?? '',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors
                                        .grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Qty: $qty',
                          style: TextStyle(
                            fontSize: 12,
                            color: qty <= 5
                                ? Colors.red[700]
                                : _green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SMALL WIDGETS
// ==========================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
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
            color: Colors.black.withOpacity(0.04),
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
                  fontSize: 13,
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

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? color
                      : Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? color
                      : Colors.grey[500],
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF1B6B3A)),
        ),
      ),
    );
  }
}