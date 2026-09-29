// lib/screens/admin/screens/admin_online_volunteers_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOnlineVolunteersScreen extends StatelessWidget {
  const AdminOnlineVolunteersScreen({super.key});

  static const Color _green = Color(0xFF2E7D32);
  static const Color _bg = Color(0xFFF4F6F8);

  bool _isApprovedVolunteer(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final stage = (data['verificationStage'] ?? '').toString().trim().toLowerCase();
    return stage == 'verified' || status == 'approved' || status == 'verified' || status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Online Volunteers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
            .where('isOnline', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          final docs = (snapshot.data?.docs ?? [])
              .where((d) => _isApprovedVolunteer(d.data() as Map<String, dynamic>))
              .toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[350]),
                  const SizedBox(height: 12),
                  Text('No volunteers online right now', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _VolunteerCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VolunteerCard({required this.data});

  static const Color _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Volunteer';
    final phone = data['phone'] ?? data['mobileNumber'] ?? '—';
    final schedule = (data['availabilitySchedule'] as List?) ?? [];
    final special = (data['specialAvailability'] as List?) ?? [];
    final available = schedule.where((s) => s['isAvailable'] == true).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 24, backgroundColor: const Color(0xFFE8F5E9),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.phone_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(phone, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFE6F9F1), borderRadius: BorderRadius.circular(20)),
              child: const Text('Online', style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            const Text('Weekly Availability', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          if (available.isEmpty)
            Text('No availability set', style: TextStyle(fontSize: 12, color: Colors.grey[400]))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: available.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF4FAF7), borderRadius: BorderRadius.circular(10)),
                child: Text('${s['day']}: ${s['startTime']} - ${s['endTime']}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _green)),
              )).toList(),
            ),
          if (special.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...special.map((sp) {
              final avail = sp['isAvailable'] == true;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(avail ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 13, color: avail ? _green : Colors.red[400]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(sp['note'] ?? '', style: TextStyle(fontSize: 11.5, color: Colors.grey[600]))),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }
}