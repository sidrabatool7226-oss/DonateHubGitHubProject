import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_tasks_controller.dart';
import '../../../widgets/task_category_style.dart'; // NEW — role icon / wording
import '../../../widgets/admin_page_kit.dart'; // NEW — whole-page scroll (shared widget)
import '../screens/volunteer_task_detail_screen.dart';

class VolunteerTasksTab extends StatelessWidget {
  // NEW — when this screen is a dashboard tab the dashboard passes a callback
  // that returns to Home; when it is opened as its own page, back just pops it.
  final VoidCallback? onBack;
  const VolunteerTasksTab({super.key, this.onBack});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF2F7F4);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VolunteerTasksController>()
        ? Get.find<VolunteerTasksController>()
        : Get.put(VolunteerTasksController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        // CHANGED — the stream now wraps header + tabs + list so the header and
        // tab badges can show live counts. Filtering / sorting is unchanged.
        child: StreamBuilder<QuerySnapshot>(
          stream: controller.myTasksStream,
          builder: (context, snapshot) {
            final bool loading =
                snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
            final List<QueryDocumentSnapshot> allDocs =
                snapshot.data?.docs ?? <QueryDocumentSnapshot>[];

            int newCount = 0, activeCount = 0, doneCount = 0;
            for (final d in allDocs) {
              final s = (d.data() as Map)['status'];
              if (s == 'assigned') {
                newCount++;
              } else if (s == 'accepted' || s == 'delivered') {
                activeCount++;
              } else if (s == 'completed') {
                doneCount++;
              }
            }
            final counts = [newCount, activeCount, doneCount];

            // CHANGED — header, tabs and the list scroll together as one page
            return AdminPageScroll(
              child: Column(
                children: [
                  _Header(newCount: newCount, activeCount: activeCount, doneCount: doneCount, onBack: onBack),

                  // ── Segmented tabs ───────────────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: _green.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Obx(() {
                      final selected = controller.selectedTab.value;
                      return Row(
                        children: List.generate(controller.tabLabels.length, (i) {
                          final isSel = selected == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => controller.selectedTab.value = i,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSel
                                      ? const LinearGradient(colors: [_green, _lightGreen])
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      controller.tabLabels[i],
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isSel ? Colors.white : Colors.grey[600],
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Colors.white.withOpacity(0.25)
                                            : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${counts[i]}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSel ? Colors.white : _green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),

                  // ── List ─────────────────────────────────────────────
                  loading
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(color: _green)),
                  )
                      : snapshot.hasError
                      ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12))),
                  )
                      : Obx(() {
                    final tab = controller.selectedTab.value;
                    List<QueryDocumentSnapshot> docs;
                    String emptyText;
                    String emptyHint;

                    if (tab == 0) {
                      docs = allDocs.where((d) => (d.data() as Map)['status'] == 'assigned').toList();
                      emptyText = 'No new tasks';
                      emptyHint = 'New tasks from the manager will appear here.';
                    } else if (tab == 1) {
                      docs = allDocs.where((d) {
                        final s = (d.data() as Map)['status'];
                        return s == 'accepted' || s == 'delivered';
                      }).toList();
                      emptyText = 'No active tasks';
                      emptyHint = 'Tasks you accept will show up here.';
                    } else {
                      docs = allDocs.where((d) => (d.data() as Map)['status'] == 'completed').toList();
                      emptyText = 'No completed tasks yet';
                      emptyHint = 'Finished tasks and your impact will be listed here.';
                    }

                    docs.sort((a, b) {
                      final aTs = (a.data() as Map)['assignedAt'] as Timestamp?;
                      final bTs = (b.data() as Map)['assignedAt'] as Timestamp?;
                      if (aTs == null || bTs == null) return 0;
                      return bTs.compareTo(aTs);
                    });

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _green.withOpacity(0.12), width: 6),
                                ),
                                child: const Icon(Icons.assignment_outlined, size: 34, color: _green),
                              ),
                              const SizedBox(height: 16),
                              Text(emptyText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E22))),
                              const SizedBox(height: 4),
                              Text(emptyHint, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _TaskCard(taskId: doc.id, data: data);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================================================
// HEADER — title + live counts
// ==========================================================================
class _Header extends StatelessWidget {
  final int newCount;
  final int activeCount;
  final int doneCount;
  final VoidCallback? onBack; // NEW
  const _Header({required this.newCount, required this.activeCount, required this.doneCount, this.onBack});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // NEW — back arrow: returns to the dashboard's Home tab
              GestureDetector(
                onTap: onBack ?? () => Get.back(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Tasks', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const Text('Track and complete the work assigned to you', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('New', newCount, Icons.notifications_active_rounded),
              const SizedBox(width: 10),
              _stat('In progress', activeCount, Icons.timelapse_rounded),
              const SizedBox(width: 10),
              _stat('Completed', doneCount, Icons.verified_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// TASK CARD
// ==========================================================================
class _TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> data;
  const _TaskCard({required this.taskId, required this.data});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);

  // "Respond within 42m" for tasks still waiting for Accept / Reject
  String? _respondText(String status) {
    if (status != 'assigned') return null;
    final ts = data['assignedAt'];
    if (ts is! Timestamp) return null;
    final int remaining = 60 - DateTime.now().difference(ts.toDate()).inMinutes;
    if (remaining <= 0) return 'Response time over';
    return 'Respond within ${remaining}m';
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11.5, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? data['itemName'] ?? 'Task';
    final String category = data['taskCategory'] ?? '';
    final String status = data['status'] ?? 'assigned';
    final style = TaskCategoryStyle.of(category);

    final String date = (data['date'] ?? '').toString();
    final String time = (data['time'] ?? '').toString();
    final String location = (data['location'] ?? data['pickupAddress'] ?? '').toString();
    final String requiredBlood = (data['requiredBloodGroup'] ?? '').toString();
    final String? respond = _respondText(status);
    final bool respondOver = respond == 'Response time over';

    final String whenText = [date, time].where((e) => e.isNotEmpty).join(' · ');

    return GestureDetector(
      onTap: () => Get.to(() => VolunteerTaskDetailScreen(taskId: taskId, data: data), transition: Transition.rightToLeft),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _green.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF14251E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                              child: Text(category, style: const TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600)),
                            ),
                          if (requiredBlood.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.bloodtype_rounded, size: 11, color: Color(0xFFC0392B)),
                                const SizedBox(width: 3),
                                Text(requiredBlood, style: const TextStyle(fontSize: 10, color: Color(0xFFC0392B), fontWeight: FontWeight.w700)),
                              ]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
            if (whenText.isNotEmpty || location.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF6FAF8), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (whenText.isNotEmpty) _meta(Icons.event_rounded, whenText),
                    if (whenText.isNotEmpty && location.isNotEmpty) const SizedBox(height: 6),
                    if (location.isNotEmpty) _meta(Icons.location_on_outlined, location),
                  ],
                ),
              ),
            ],
            if (respond != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: respondOver ? const Color(0xFFFCEBEA) : const Color(0xFFFFF3E4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer_outlined, size: 13, color: respondOver ? const Color(0xFFC0392B) : const Color(0xFFDB7C26)),
                  const SizedBox(width: 5),
                  Text(respond, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: respondOver ? const Color(0xFFC0392B) : const Color(0xFFDB7C26))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c; Color bg; String label;
    switch (status) {
      case 'accepted': c = Colors.blue[700]!; bg = Colors.blue[50]!; label = 'Accepted'; break;
      case 'delivered': c = Colors.orange[700]!; bg = Colors.orange[50]!; label = 'Delivered'; break;
      case 'completed': c = const Color(0xFF1B6B3A); bg = const Color(0xFFE8F5E9); label = 'Completed'; break;
      case 'rejected': c = Colors.red[700]!; bg = Colors.red[50]!; label = 'Rejected'; break;
      default: c = const Color(0xFFDB7C26); bg = const Color(0xFFFFF3E4); label = 'New';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: c, fontWeight: FontWeight.w700)),
    );
  }
}