import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_events_controller.dart';

class VolunteerEventsTab extends StatelessWidget {
  const VolunteerEventsTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerEventsController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Events', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Join events happening at Little Smiles', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: controller.eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _green));
                  }
                  final docs = List.from(snapshot.data?.docs ?? [])
                    ..sort((a, b) {
                      final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                      final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                      if (aTs == null || bTs == null) return 0;
                      return bTs.compareTo(aTs);
                    });

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 14),
                          Text('No events yet', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _EventCard(eventId: doc.id, data: data, controller: controller);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;
  final VolunteerEventsController controller;
  const _EventCard({required this.eventId, required this.data, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description = data['description'] ?? '';
    final String location = data['location'] ?? '';
    final String startDate = data['startDateStr'] ?? '';
    final String endDate = data['endDateStr'] ?? '';
    final String imageUrl = data['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 12.5, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(startDate == endDate ? startDate : '$startDate → $endDate', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
                const SizedBox(height: 14),

                StreamBuilder<int>(
                  stream: controller.participantCountStream(eventId),
                  builder: (context, countSnap) {
                    final count = countSnap.data ?? 0;
                    return StreamBuilder<bool>(
                      stream: controller.isJoinedStream(eventId),
                      builder: (context, joinedSnap) {
                        final isJoined = joinedSnap.data ?? false;
                        return Row(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('$count joined', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                            const Spacer(),
                            Obx(() => ElevatedButton.icon(
                              onPressed: controller.isSaving.value ? null : () {
                                if (isJoined) {
                                  controller.leaveEvent(eventId);
                                } else {
                                  controller.joinEvent(eventId, title);
                                }
                              },
                              icon: Icon(isJoined ? Icons.check_rounded : Icons.add_rounded, size: 16),
                              label: Text(isJoined ? 'Joined' : 'Join Event', style: const TextStyle(fontSize: 12.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isJoined ? Colors.grey[200] : _green,
                                foregroundColor: isJoined ? Colors.grey[700] : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}