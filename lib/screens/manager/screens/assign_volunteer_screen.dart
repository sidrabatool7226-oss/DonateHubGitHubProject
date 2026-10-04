import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_tasks_controller.dart';
import '../../../widgets/admin_page_kit.dart';

class AssignVolunteerScreen extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;
  final String? reassignTaskId;
  final String? oldVolunteerId;

  const AssignVolunteerScreen({
    super.key,
    required this.donationId,
    required this.data,
    this.reassignTaskId,
    this.oldVolunteerId,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerTasksController>();

    final String category = 'Resource Pickup';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(reassignTaskId != null ? 'Reassign Task' : 'Assign Volunteer',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),

      body: AdminPageScroll(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFE6F5EE), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.inventory_2_rounded, color: _emerald),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['itemName'] ?? 'Item', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Qty: ${data['quantity'] ?? 1} · ${data['address'] ?? data['pickupAddress'] ?? 'No address'}',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 14, color: _emerald),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Showing verified & online volunteers for "$category"',
                          style: const TextStyle(fontSize: 11.5, color: _emerald, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'volunteer')
                      .where('verificationStage', isEqualTo: 'Verified')
                      .where('isOnline', isEqualTo: true)

                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator(color: _emerald)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12))),
                      );
                    }

                    final allVolunteers = (snapshot.data?.docs ?? []).where((v) {
                      final vData = v.data() as Map<String, dynamic>;
                      return vData['status'] != 'inactive';
                    }).toList();
                    final matched = allVolunteers.where((v) {
                      final vData = v.data() as Map<String, dynamic>;
                      final categories = (vData['categories'] as List?) ?? [];
                      return categories.contains(category);
                    }).toList();

                    final list = matched.isNotEmpty ? matched : allVolunteers;
                    final bool showFallbackNote = matched.isEmpty && allVolunteers.isNotEmpty;

                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No online volunteers available right now', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length + (showFallbackNote ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showFallbackNote && index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFDB7C26)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No online volunteer has the "$category" role — showing all online volunteers.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFDB7C26)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final v = list[index - (showFallbackNote ? 1 : 0)];
                        final vData = v.data() as Map<String, dynamic>;
                        final name = vData['name'] ?? 'Volunteer';
                        final categories = (vData['categories'] as List?) ?? [];
                        final scheduleList = (vData['availabilitySchedule'] as List?) ?? [];
                        final availableDays = scheduleList
                            .where((e) => e['isAvailable'] == true)
                            .map((e) => (e['day'] as String).substring(0, 3))
                            .toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFFE6F5EE),
                                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                            style: const TextStyle(color: _emerald, fontWeight: FontWeight.bold)),
                                      ),
                                      Positioned(
                                        right: 0, bottom: 0,
                                        child: Container(
                                          width: 12, height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2FBF87),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                        Wrap(
                                          spacing: 4,
                                          children: categories.take(2).map((c) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(top: 3),
                                            decoration: BoxDecoration(color: const Color(0xFFF4FAF7), borderRadius: BorderRadius.circular(6)),
                                            child: Text(c.toString(), style: TextStyle(fontSize: 9.5, color: Colors.grey[600])),
                                          )).toList(),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Obx(() {
                                    final bool busy = controller.isSaving.value;
                                    final bool mine = busy && controller.assigningVolunteerId.value == v.id;
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (controller.isSaving.value) return; // already saving — ignore
                                        final bool isReassign = reassignTaskId != null;
                                        bool ok;
                                        if (isReassign) {
                                          ok = await controller.reassignVolunteer(
                                            taskId: reassignTaskId!,
                                            oldVolunteerId: oldVolunteerId ?? '',
                                            newVolunteerId: v.id,
                                            newVolunteerName: name,
                                            showMessage: false,
                                          );
                                        } else {
                                          ok = await controller.assignVolunteer(
                                            donationId: donationId,
                                            donationData: data,
                                            volunteerId: v.id,
                                            volunteerName: name,
                                            showMessage: false,
                                          );
                                        }
                                        if (ok) {
                                          Get.back();
                                          Get.snackbar(
                                            isReassign ? 'Reassigned' : 'Assigned',
                                            isReassign
                                                ? 'Task reassigned to $name'
                                                : 'Task assigned to $name',
                                            backgroundColor: Colors.green[50],
                                            colorText: Colors.green[700],
                                            snackPosition: SnackPosition.BOTTOM,
                                            margin: const EdgeInsets.all(16),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _emerald,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: mine
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                          : const Text('Assign', style: TextStyle(fontSize: 12)),
                                    );
                                  }),
                                ],
                              ),

                              if (availableDays.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: _emerald),
                                    const SizedBox(width: 5),
                                    const Text('Available:', style: TextStyle(fontSize: 10.5, color: _emerald, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(availableDays.join(', '),
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],

                              // NEW — today's schedule + how many tasks this volunteer already has
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              _VolunteerLoadRow(volunteerId: v.id, schedule: scheduleList),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VolunteerLoadRow extends StatelessWidget {
  final String volunteerId;
  final List schedule;

  const _VolunteerLoadRow({required this.volunteerId, required this.schedule});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  // returns today's availability text; _todayAvailable() tells if it is a working slot
  String _todayText() {
    if (schedule.isEmpty) return 'No schedule set';
    final String today = _weekdays[DateTime.now().weekday - 1].toLowerCase();
    for (final e in schedule) {
      if (e is Map && (e['day'] ?? '').toString().toLowerCase() == today) {
        if (e['isAvailable'] == true) {
          final String start = (e['startTime'] ?? '').toString();
          final String end = (e['endTime'] ?? '').toString();
          return start.isNotEmpty && end.isNotEmpty ? 'Today: $start – $end' : 'Available today';
        }
        return 'Not scheduled today';
      }
    }
    return 'Not scheduled today';
  }

  bool _todayAvailable() {
    final t = _todayText();
    return t.startsWith('Today:') || t == 'Available today';
  }

  @override
  Widget build(BuildContext context) {
    final String todayText = _todayText();
    final bool todayAvailable = _todayAvailable();

    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 13, color: todayAvailable ? _emerald : Colors.grey[400]),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            todayText,
            style: TextStyle(
              fontSize: 10.5,
              color: todayAvailable ? _emerald : Colors.grey[500],
              fontWeight: todayAvailable ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('volunteerId', isEqualTo: volunteerId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final int active = snap.data!.docs.where((d) {
              final status = ((d.data() as Map<String, dynamic>)['status'] ?? '').toString();
              return status == 'assigned' || status == 'accepted';
            }).length;
            final bool free = active == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: free ? const Color(0xFFE6F5EE) : const Color(0xFFFFF3E4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                free ? 'No active tasks' : '$active active task${active == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: free ? _emerald : const Color(0xFFDB7C26),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}