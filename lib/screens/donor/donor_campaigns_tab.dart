import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/donor_campaign_controller.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class DonorCampaignsTab extends StatefulWidget {
  const DonorCampaignsTab({super.key});

  @override
  State<DonorCampaignsTab> createState() =>
      _DonorCampaignsTabState();
}

class _DonorCampaignsTabState
    extends State<DonorCampaignsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
    Get.put(DonorCampaignController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, Color(0xFF2D8A52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                        20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                'Campaigns & Events',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Support causes that matter',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .volunteer_activism_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                    Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.campaign_rounded,
                                size: 16),
                            SizedBox(width: 6),
                            Text('Campaigns'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_rounded,
                                size: 16),
                            SizedBox(width: 6),
                            Text('Events'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab Views ──────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CampaignsList(
                      controller: controller),
                  _EventsList(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// CAMPAIGNS LIST
// ==========================================================================
class _CampaignsList extends StatelessWidget {
  final DonorCampaignController controller;
  const _CampaignsList({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.campaignsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: _green),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.campaign_outlined,
            message: 'No active campaigns',
            subtitle:
            'Check back soon for new campaigns',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data =
            doc.data() as Map<String, dynamic>;
            return _CampaignCard(
              docId: doc.id,
              data: data,
              controller: controller,
            );
          },
        );
      },
    );
  }
}

// ==========================================================================
// CAMPAIGN CARD — Donor view with Donate button
// ==========================================================================
class _CampaignCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final DonorCampaignController controller;

  const _CampaignCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description =
        data['description'] ?? '';
    final double goal =
    (data['goalAmount'] ?? 0).toDouble();
    final double collected =
    (data['collectedAmount'] ?? 0).toDouble();
    final String imageUrl = data['image'] ?? '';
    final String endDate = data['endDate'] ?? '';
    final List needs = data['needs'] ?? [];
    final double progress = goal > 0
        ? (collected / goal).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progress * 100).toInt();
    final int remaining =
    goal > collected ? (goal - collected).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholder(),
                )
                    : _placeholder(),
              ),
              // Gradient
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom text on image
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
              // Description
              Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius:
              BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 10),

          // Amount info
          Row(
            children: [
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raised',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    'Rs. ${collected.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    'Rs. $remaining',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    'Goal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    'Rs. ${goal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // End date
          if (endDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Campaign ends: $endDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],

          // Needs chips
          if (needs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: needs.map((need) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors
                            .orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 12,
                          color:
                          Colors.orange[700]),
                      const SizedBox(width: 3),
                      Text(
                        need,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Donate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showDonateSheet(
                      context, docId, title),
              icon: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 18),
              label: const Text(
                'Donate to this Campaign',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(
                    vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    ],
    ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 180,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.campaign_outlined,
            size: 56, color: Color(0xFF1B6B3A)),
      ),
    );
  }

  void _showDonateSheet(BuildContext context,
      String campaignId, String campaignName) {
    controller.amountController.clear();
    controller.selectedPaymentMethod.value =
    'Easypaisa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => _DonateToCampaignSheet(
        campaignId: campaignId,
        campaignName: campaignName,
        controller: controller,
      ),
    );
  }
}

// ==========================================================================
// DONATE TO CAMPAIGN SHEET
// ==========================================================================
class _DonateToCampaignSheet extends StatelessWidget {
  final String campaignId;
  final String campaignName;
  final DonorCampaignController controller;

  const _DonateToCampaignSheet({
    required this.campaignId,
    required this.campaignName,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    File? proofImage;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
            MediaQuery.of(context).viewInsets.bottom +
                24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                      BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons
                              .volunteer_activism_rounded,
                          color: _green,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Donate to Campaign',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            campaignName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick amount buttons
                const Text(
                  'Select Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    '500',
                    '1000',
                    '2000',
                    '5000'
                  ].map((amt) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.amountController
                              .text = amt;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              right: 8),
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFFE8F5E9),
                            borderRadius:
                            BorderRadius.circular(8),
                            border: Border.all(
                                color: _green
                                    .withOpacity(0.3)),
                          ),
                          child: Text(
                            'Rs.$amt',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _green,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Custom amount
                TextField(
                  controller:
                  controller.amountController,
                  keyboardType: TextInputType.number,
                  style:
                  const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Or enter custom amount',
                    hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13),
                    prefixText: 'Rs. ',
                    prefixStyle: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor:
                    const Color(0xFFF4F6F8),
                    contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _green),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment method
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller
                      .paymentMethods
                      .map((method) {
                    final isSel = controller
                        .selectedPaymentMethod
                        .value ==
                        method;
                    return GestureDetector(
                      onTap: () => controller
                          .selectedPaymentMethod
                          .value = method,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _green
                              : const Color(
                              0xFFF4F6F8),
                          borderRadius:
                          BorderRadius.circular(
                              20),
                          border: Border.all(
                            color: isSel
                                ? _green
                                : Colors
                                .grey.shade300,
                          ),
                        ),
                        child: Text(
                          method,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSel
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
                const SizedBox(height: 14),

                // Payment proof
                const Text(
                  'Upload Payment Proof *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final XFile? image =
                    await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setState(() {
                        proofImage =
                            File(image.path);
                      });
                    }
                  },
                  child: Container(
                    height: proofImage != null
                        ? 140
                        : 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFF4F6F8),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey[300]!,
                          style: proofImage == null
                              ? BorderStyle.solid
                              : BorderStyle.solid),
                    ),
                    child: proofImage != null
                        ? ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                          12),
                      child: Image.file(
                        proofImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                            Icons
                                .upload_file_outlined,
                            size: 28,
                            color:
                            Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload screenshot',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    controller.isLoading.value
                        ? null
                        : () async {
                      // Upload proof
                      String proofUrl = '';
                      if (proofImage !=
                          null) {
                        final url =
                        await CloudinaryService()
                            .uploadImage(
                            proofImage!);
                        proofUrl =
                            url ?? '';
                      }

                      bool ok =
                      await controller
                          .donateToCampaign(
                        campaignId:
                        campaignId,
                        campaignName:
                        campaignName,
                        paymentProofUrl:
                        proofUrl,
                      );
                      if (ok &&
                          context.mounted) {
                        Navigator.pop(
                            context);
                      }
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor:
                      Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            14),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Submit Donation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================================================
// EVENTS LIST
// ==========================================================================
class _EventsList extends StatelessWidget {
  final DonorCampaignController controller;
  const _EventsList({required this.controller});

  static const Color _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: _blue),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.event_outlined,
            message: 'No upcoming events',
            subtitle:
            'Events will appear here when scheduled',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data =
            doc.data() as Map<String, dynamic>;
            return _EventCard(data: data);
          },
        );
      },
    );
  }
}

// ==========================================================================
// EVENT CARD — Donor view
// ==========================================================================
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EventCard({required this.data});

  static const Color _blue = Color(0xFF1565C0);

  String _monthName(String month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    int m = int.tryParse(month) ?? 0;
    return m > 0 && m < 13 ? months[m] : '--';
  }

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description =
        data['description'] ?? '';
    final String location = data['location'] ?? '';
    final String startDate =
        data['startDateStr'] ?? '';
    final String endDate = data['endDateStr'] ?? '';
    final String imageUrl = data['image'] ?? '';

    final List<String> dateParts =
    startDate.isNotEmpty
        ? startDate.split('/')
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Blue header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue, _blue.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text(
                        dateParts.isNotEmpty
                            ? dateParts[0]
                            : '--',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _blue,
                        ),
                      ),
                      Text(
                        dateParts.length > 1
                            ? _monthName(dateParts[1])
                            : '--',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.white70),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Banner
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Date chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: _blue),
                      const SizedBox(width: 6),
                      Text(
                        startDate == endDate
                            ? startDate
                            : '$startDate → $endDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Join button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Event Noted!',
                        'We look forward to seeing you at $title',
                        backgroundColor:
                        Colors.blue[50],
                        colorText:
                        Colors.blue[700],
                        snackPosition:
                        SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(
                            16),
                      );
                    },
                    icon: const Icon(
                        Icons.event_available_rounded,
                        size: 16),
                    label: const Text(
                      'Interested in this Event',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _blue,
                      side: const BorderSide(
                          color: _blue),
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
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

// ==========================================================================
// EMPTY STATE
// ==========================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}