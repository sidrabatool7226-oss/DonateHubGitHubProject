import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EventParticipantsScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  const EventParticipantsScreen({super.key, required this.eventId, required this.eventTitle});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(eventTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('participants')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          final docs = List.from(snapshot.data?.docs ?? [])
            ..sort((a, b) {
              final aTs = (a.data() as Map)['joinedAt'] as Timestamp?;
              final bTs = (b.data() as Map)['joinedAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No volunteers joined yet', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['volunteerName'] ?? 'Volunteer';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22, backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                          style: const TextStyle(color: _green, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(data['volunteerEmail'] ?? '', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                          if ((data['volunteerPhone'] ?? '').toString().isNotEmpty)
                            Text(data['volunteerPhone'], style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}