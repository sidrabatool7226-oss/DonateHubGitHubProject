import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_volunteers_controller.dart';
import '../screens/volunteer_details_screen.dart';
import '../screens/manager_profile_screen.dart';

class ManagerVolunteersTab extends StatelessWidget {
  const ManagerVolunteersTab({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerVolunteersController());

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
                          'Volunteer Verification',
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
                            color: Colors.white.withOpacity(0.18),
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

                  // Search
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => controller.searchQuery.value = v,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search volunteers...',
                        hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Status Tabs ────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Obx(() {
                final selected = controller.selectedTab.value; // explicit read yahan
                return SizedBox(
                  height: 36,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(controller.tabLabels.length, (index) {
                        final isSel = selected == index;
                        return GestureDetector(
                          onTap: () => controller.selectedTab.value = index,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSel ? _emerald : const Color(0xFFF4FAF7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? _emerald : Colors.grey.shade300),
                            ),
                            child: Text(
                              controller.tabLabels[index],
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isSel ? Colors.white : Colors.grey[700],
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),
            // ── List ──────────────────────────────────────────────
            Expanded(
              child: Obx(() => StreamBuilder<QuerySnapshot>(
                stream: controller.volunteersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _emerald));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = controller.filterBySearch(allDocs);

                  if (docs.isEmpty) {
                    return _EmptyState(
                      label: controller.tabLabels[controller
                          .selectedTab.value],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _VolunteerCard(
                        docId: doc.id,
                        data: data,
                        controller: controller,
                      );
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// VOLUNTEER CARD
// ==========================================================================
class _VolunteerCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ManagerVolunteersController controller;

  const _VolunteerCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Volunteer';
    final String stage = data['verificationStage'] ?? 'Pending';
    final List categories =
        (data['categories'] as List?) ?? const [];
    final dynamic createdAt = data['createdAt'];

    return GestureDetector(
      onTap: () => Get.to(
            () => VolunteerDetailsScreen(docId: docId, data: data),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5EE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    color: _emerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14251E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${controller.timeAgo(createdAt)}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (categories.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categories.first.toString(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      _StageBadge(stage: stage),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[350]),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// STAGE BADGE
// ==========================================================================
class _StageBadge extends StatelessWidget {
  final String stage;
  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;

    switch (stage) {
      case 'Verified':
        color = const Color(0xFF0F6E4F);
        bg = const Color(0xFFE6F5EE);
        label = 'Approved';
        break;
      case 'Rejected':
        color = const Color(0xFFC0392B);
        bg = const Color(0xFFFCEBEA);
        label = 'Rejected';
        break;
      case 'Video_Scheduled':
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
        label = 'Video Scheduled';
        break;
      case 'Physical_Scheduled':
        color = const Color(0xFF7C3AED);
        bg = const Color(0xFFF3E8FF);
        label = 'Physical Scheduled';
        break;
      case 'Form_Reviewed':
        color = const Color(0xFFDB7C26);
        bg = const Color(0xFFFFF3E4);
        label = 'Form Reviewed';
        break;
      default:
        color = const Color(0xFFDB7C26);
        bg = const Color(0xFFFFF3E4);
        label = 'Pending Review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==========================================================================
// EMPTY STATE
// ==========================================================================
class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            'No $label volunteers',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}