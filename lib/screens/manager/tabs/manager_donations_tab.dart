import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_donations_controller.dart';
import '../screens/fund_donation_detail_screen.dart';
import '../screens/resource_donation_detail_screen.dart';
import '../screens/manager_profile_screen.dart';

class ManagerDonationsTab extends StatelessWidget {
  const ManagerDonationsTab({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerDonationsController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_emerald, _mint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Donations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.to(
                              () => const ManagerProfileScreen(),
                          transition: Transition.rightToLeft,
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                            Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Fund / Resource toggle
                  Obx(
                        () => Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _ToggleBtn(
                            label: 'Fund',
                            icon:
                            Icons.payments_outlined,
                            isSelected:
                            controller.selectedType.value ==
                                'fund',
                            onTap: () =>
                            controller.selectedType.value =
                            'fund',
                          ),
                          _ToggleBtn(
                            label: 'Resource',
                            icon:
                            Icons.inventory_2_outlined,
                            isSelected:
                            controller.selectedType.value ==
                                'resource',
                            onTap: () =>
                            controller.selectedType.value =
                            'resource',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Status Tabs ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(vertical: 10),
              child: Obx(
                    () => Row(
                  children: controller.statusTabs.map((s) {
                    final isSel =
                        controller.selectedStatus.value == s;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller
                            .selectedStatus.value = s,
                        child: Column(
                          children: [
                            Text(
                              s[0].toUpperCase() +
                                  s.substring(1),
                              style: TextStyle(
                                fontSize: 13,
                                color: isSel
                                    ? _emerald
                                    : Colors.grey[400],
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 2,
                              margin:
                              const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              color: isSel
                                  ? _emerald
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: controller.donationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _emerald,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ?? [];

                  // GetX MUST be here because the Rx values
                  // are being read inside this filtering section.
                  return Obx(() {
                    final selectedType =
                        controller.selectedType.value;

                    final selectedStatus =
                        controller.selectedStatus.value;

                    // Type filter + status filter
                    // done client-side.
                    final filteredDocs =
                    docs.where((doc) {
                      final data =
                      doc.data()
                      as Map<String, dynamic>;

                      final isResource =
                      data.containsKey('itemName');

                      final isFund =
                      data.containsKey('amount');

                      final typeMatches =
                      selectedType == 'resource'
                          ? isResource
                          : selectedType == 'fund'
                          ? isFund
                          : true;

                      final status =
                      (data['status'] ?? 'pending')
                          .toString();

                      final statusMatches =
                          status == selectedStatus;

                      return typeMatches &&
                          statusMatches;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return _EmptyState(
                        type: selectedType,
                        status: selectedStatus,
                      );
                    }

                    return ListView.builder(
                      padding:
                      const EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        16,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder:
                          (context, index) {
                        final doc =
                        filteredDocs[index];

                        final data =
                        doc.data()
                        as Map<String, dynamic>;

                        return _DonationCard(
                          docId: doc.id,
                          data: data,
                          controller: controller,
                        );
                      },
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _emerald =
  Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? _emerald
                    : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isSelected
                      ? _emerald
                      : Colors.white,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ManagerDonationsController controller;

  const _DonationCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _emerald =
  Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final bool isFund =
    data.containsKey('amount');

    final String donorEmail =
        data['userEmail'] ??
            data['donorEmail'] ??
            'Donor';

    final dynamic createdAt =
    data['createdAt'];

    return GestureDetector(
      onTap: () {
        controller.prefillForApproval(data);

        if (isFund) {
          Get.to(
                () => FundDonationDetailScreen(
              docId: docId,
              data: data,
            ),
            transition:
            Transition.rightToLeft,
          );
        } else {
          Get.to(
                () =>
                ResourceDonationDetailScreen(
                  docId: docId,
                  data: data,
                ),
            transition:
            Transition.rightToLeft,
          );
        }
      },
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isFund
                    ? const Color(0xFFE6F5EE)
                    : const Color(0xFFEFF6FF),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(
                isFund
                    ? Icons.payments_rounded
                    : Icons.inventory_2_rounded,
                color: isFund
                    ? _emerald
                    : const Color(0xFF2563EB),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    isFund
                        ? 'Rs. ${data['amount'] ?? 0}'
                        : (data['itemName'] ??
                        'Item'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF14251E),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    donorEmail,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    controller
                        .timeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[350],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  final String status;

  const _EmptyState({
    required this.type,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 14),
          Text(
            'No $status $type donations',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}