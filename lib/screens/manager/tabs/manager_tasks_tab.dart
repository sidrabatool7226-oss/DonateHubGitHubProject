import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_tasks_controller.dart';
import '../screens/assign_volunteer_screen.dart';
import '../screens/task_detail_screen.dart';
import '../screens/manager_profile_screen.dart';
import '../screens/create_task_screen.dart';

class ManagerTasksTab extends StatelessWidget {
  const ManagerTasksTab({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerTasksController());

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateTaskScreen(), transition: Transition.rightToLeft),
        backgroundColor: _emerald,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Task', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_emerald, _mint], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Task Assignment',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const ManagerProfileScreen(),
                        transition: Transition.rightToLeft),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
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
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isSel ? _emerald : Colors.grey[400],
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                                )),
                            const SizedBox(height: 6),
                            Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 16), color: isSel ? _emerald : Colors.transparent),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),

            Expanded(
              child: Obx(() {
                final tab = controller.selectedTab.value;
                return IndexedStack(
                  index: tab,
                  children: [
                    _PendingAssignmentList(controller: controller),
                    _ActiveTasksList(controller: controller),
                    _DeliveredTasksList(controller: controller),
                    _CompletedTasksList(controller: controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAssignmentList extends StatelessWidget {
  final ManagerTasksController controller;
  const _PendingAssignmentList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.approvedDonationsStream,
      builder: (context, donationSnap) {
        if (donationSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        if (donationSnap.hasError) {
          return Center(child: Text('Error: ${donationSnap.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }

        final allApproved = donationSnap.data?.docs ?? [];
        final resourceDonations = allApproved.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data.containsKey('itemName');
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
          builder: (context, taskSnap) {
            final existingDonationIds =
            (taskSnap.data?.docs ?? []).map((d) => (d.data() as Map)['donationId']).toSet();

            final unassigned = resourceDonations.where((d) => !existingDonationIds.contains(d.id)).toList();

            if (unassigned.isEmpty) {
              return _EmptyState(icon: Icons.assignment_turned_in_outlined, text: 'No donations waiting for assignment');
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: unassigned.length,
              itemBuilder: (context, index) {
                final doc = unassigned[index];
                final data = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Get.to(
                        () => AssignVolunteerScreen(donationId: doc.id, data: data),
                    transition: Transition.rightToLeft,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: const Color(0xFFFFF3E4), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFDB7C26)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['itemName'] ?? 'Item',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF14251E))),
                              Text('${data['userEmail'] ?? data['donorEmail'] ?? ''}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                              Text('Qty: ${data['quantity'] ?? 1} · ${data['category'] ?? ''}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _emerald, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Assign', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActiveTasksList extends StatelessWidget {
  final ManagerTasksController controller;
  const _ActiveTasksList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.allTasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final status = (d.data() as Map)['status'];
          return status == 'assigned' || status == 'accepted';
        }).toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map)['assignedAt'] as Timestamp?;
            final bTs = (b.data() as Map)['assignedAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) {
          return _EmptyState(icon: Icons.pending_actions_rounded, text: 'No active tasks');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final bool timedOut = controller.isTimedOut(data);
            final Duration? remaining = controller.timeRemaining(data);
            final String status = data['status'] ?? 'assigned';
            final String title = data['title'] ?? data['itemName'] ?? 'Task';
            final String category = data['taskCategory'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: timedOut ? Border.all(color: const Color(0xFFC0392B), width: 1.5) : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF14251E))),
                            if (category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE6F5EE), borderRadius: BorderRadius.circular(6)),
                                child: Text(category, style: const TextStyle(fontSize: 9.5, color: _emerald, fontWeight: FontWeight.w600)),
                              ),
                            Text('Volunteer: ${data['volunteerName'] ?? ''}',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'accepted' ? const Color(0xFFE6F5EE) : const Color(0xFFFFF3E4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status == 'accepted' ? 'Accepted' : 'Awaiting Response',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: status == 'accepted' ? _emerald : const Color(0xFFDB7C26),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (status == 'assigned') ...[
                    if (timedOut)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_off_rounded, color: Color(0xFFC0392B), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('No response for 1 hour. Reassign to another volunteer.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFFC0392B))),
                            ),
                          ],
                        ),
                      )
                    else if (remaining != null)
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text('${remaining.inMinutes} min left to respond',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                        ],
                      ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      if (timedOut && data['donationId'] != null && data['donationId'].toString().isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.to(
                                  () => AssignVolunteerScreen(
                                donationId: data['donationId'],
                                data: {
                                  'itemName': data['itemName'],
                                  'category': data['taskCategory'],
                                  'quantity': data['quantity'],
                                  'donorId': data['donorId'],
                                  'userEmail': data['donorName'],
                                  'address': data['pickupAddress'] ?? data['location'],
                                },
                                reassignTaskId: doc.id,
                                oldVolunteerId: data['volunteerId'],
                              ),
                              transition: Transition.rightToLeft,
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: const Text('Reassign'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[400],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              status == 'accepted' ? 'Waiting for delivery' : 'Waiting for volunteer',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DeliveredTasksList extends StatelessWidget {
  final ManagerTasksController controller;
  const _DeliveredTasksList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.allTasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) => (d.data() as Map)['status'] == 'delivered').toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map)['deliveredAt'] as Timestamp?;
            final bTs = (b.data() as Map)['deliveredAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) {
          return _EmptyState(icon: Icons.local_shipping_outlined, text: 'No deliveries to review');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Get.to(() => TaskDetailScreen(taskId: doc.id, data: data), transition: Transition.rightToLeft),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? data['itemName'] ?? 'Task', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('by ${data['volunteerName'] ?? ''}', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CompletedTasksList extends StatelessWidget {
  final ManagerTasksController controller;
  const _CompletedTasksList({required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.allTasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _emerald));
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) => (d.data() as Map)['status'] == 'completed').toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map)['completedAt'] as Timestamp?;
            final bTs = (b.data() as Map)['completedAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) {
          return _EmptyState(icon: Icons.check_circle_outline_rounded, text: 'No completed tasks yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFE6F5EE), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check_rounded, color: _emerald, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? data['itemName'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${data['volunteerName'] ?? ''} · ${controller.timeAgo(data['completedAt'])}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}