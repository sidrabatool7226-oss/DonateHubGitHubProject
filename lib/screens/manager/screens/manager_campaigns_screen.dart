import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/manager_campaigns_controller.dart';
import 'manager_campaign_detail_screen.dart';

class ManagerCampaignsScreen extends StatelessWidget {
  const ManagerCampaignsScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerCampaignsController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Campaigns',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: _emerald,
              strokeWidth: 2,
            ),
          );
        }

        final campaigns = controller.campaigns;

        if (campaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 52,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No campaigns found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final doc = campaigns[index];
            final data = doc.data();

            return _CampaignCard(
              docId: doc.id,
              data: data,
            );
          },
        );
      }),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _CampaignCard({
    required this.docId,
    required this.data,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['image'] ?? '').toString();
    final endDate = (data['endDate'] ?? '').toString();

    final goal = _number(data['goalAmount']);
    final collected = _number(data['collectedAmount']);

    final isActive = data['isActive'] == true;

    final progress = goal > 0
        ? (collected / goal).clamp(0.0, 1.0)
        : 0.0;

    final needs = data['needs'] is List
        ? List<String>.from(
      (data['needs'] as List).map((e) => e.toString()),
    )
        : <String>[];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _imagePlaceholder();
                },
              ),
            )
          else
            _imagePlaceholder(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Untitled Campaign' : title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14251E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE6F5EE)
                            : const Color(0xFFFCEBEA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? _emerald
                              : const Color(0xFFC0392B),
                        ),
                      ),
                    ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _AmountInfo(
                        label: 'Goal',
                        value: 'Rs. ${goal.toStringAsFixed(0)}',
                      ),
                    ),
                    Expanded(
                      child: _AmountInfo(
                        label: 'Collected',
                        value: 'Rs. ${collected.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE6F5EE),
                    color: _emerald,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}% collected',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _emerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (endDate.isNotEmpty)
                      Text(
                        'Ends: $endDate',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),

                if (needs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: needs.map((need) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          need,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFDB7C26),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(
                            () => ManagerCampaignDetailScreen(
                          docId: docId,
                          data: data,
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 17,
                    ),
                    label: const Text(
                      'View Campaign',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _imagePlaceholder() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE6F5EE),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.campaign_outlined,
          size: 50,
          color: Color(0xFF0F6E4F),
        ),
      ),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  final String label;
  final String value;

  const _AmountInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F6E4F),
          ),
        ),
      ],
    );
  }
}