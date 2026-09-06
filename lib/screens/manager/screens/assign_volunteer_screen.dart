import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_tasks_controller.dart';

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
    final String category = data['category'] ?? 'pickup_delivery';

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
      body: Column(
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
                Text('Showing verified & online volunteers for "$category"',
                    style: const TextStyle(fontSize: 11.5, color: _emerald, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'volunteer')
                  .where('verificationStage', isEqualTo: 'Verified')
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _emerald));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                }

                final allVolunteers = snapshot.data?.docs ?? [];
                final matched = allVolunteers.where((v) {
                  final vData = v.data() as Map<String, dynamic>;
                  final categories = (vData['categories'] as List?) ?? [];
                  return categories.contains(category);
                }).toList();

                final list = matched.isNotEmpty ? matched : allVolunteers;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No online volunteers available right now', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final v = list[index];
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
                              Obx(() => ElevatedButton(
                                onPressed: controller.isSaving.value ? null : () async {
                                  bool ok;
                                  if (reassignTaskId != null) {
                                    ok = await controller.reassignVolunteer(
                                      taskId: reassignTaskId!,
                                      oldVolunteerId: oldVolunteerId ?? '',
                                      newVolunteerId: v.id,
                                      newVolunteerName: name,
                                    );
                                  } else {
                                    ok = await controller.assignVolunteer(
                                      donationId: donationId,
                                      donationData: data,
                                      volunteerId: v.id,
                                      volunteerName: name,
                                    );
                                  }
                                  if (ok) Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _emerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Assign', style: TextStyle(fontSize: 12)),
                              )),
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
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}