import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_tasks_controller.dart';
import '../screens/volunteer_task_detail_screen.dart';

class VolunteerTasksTab extends StatelessWidget {
  const VolunteerTasksTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VolunteerTasksController>()
        ? Get.find<VolunteerTasksController>()
        : Get.put(VolunteerTasksController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: const Text('My Tasks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Obx(() {
                final selected = controller.selectedTab.value;
                return Row(
                  children: List.generate(controller.tabLabels.length, (i) {
                    final isSel = selected == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectedTab.value = i,
                        child: Column(
                          children: [
                            Text(controller.tabLabels[i],
                                style: TextStyle(fontSize: 13, color: isSel ? _green : Colors.grey[400], fontWeight: isSel ? FontWeight.w700 : FontWeight.w400)),
                            const SizedBox(height: 6),
                            Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 20), color: isSel ? _green : Colors.transparent),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: controller.myTasksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _green));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  return Obx(() {
                    final tab = controller.selectedTab.value;
                    List<QueryDocumentSnapshot> docs;
                    String emptyText;

                    if (tab == 0) {
                      docs = allDocs.where((d) => (d.data() as Map)['status'] == 'assigned').toList();
                      emptyText = 'No new tasks';
                    } else if (tab == 1) {
                      docs = allDocs.where((d) {
                        final s = (d.data() as Map)['status'];
                        return s == 'accepted' || s == 'delivered';
                      }).toList();
                      emptyText = 'No active tasks';
                    } else {
                      docs = allDocs.where((d) => (d.data() as Map)['status'] == 'completed').toList();
                      emptyText = 'No completed tasks yet';
                    }

                    docs.sort((a, b) {
                      final aTs = (a.data() as Map)['assignedAt'] as Timestamp?;
                      final bTs = (b.data() as Map)['assignedAt'] as Timestamp?;
                      if (aTs == null || bTs == null) return 0;
                      return bTs.compareTo(aTs);
                    });

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(emptyText, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _TaskCard(taskId: doc.id, data: data);
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

class _TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> data;
  const _TaskCard({required this.taskId, required this.data});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? data['itemName'] ?? 'Task';
    final String category = data['taskCategory'] ?? '';
    final String status = data['status'] ?? 'assigned';

    return GestureDetector(
      onTap: () => Get.to(() => VolunteerTaskDetailScreen(taskId: taskId, data: data), transition: Transition.rightToLeft),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: Icon(
                category == 'Resource Pickup' ? Icons.inventory_2_rounded : Icons.volunteer_activism_rounded,
                color: _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                      child: Text(category, style: const TextStyle(fontSize: 9.5, color: _green, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600)),
    );
  }
}