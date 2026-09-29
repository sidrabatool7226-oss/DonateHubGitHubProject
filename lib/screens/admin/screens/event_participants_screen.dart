// ============================================================
// FILE: lib/screens/admin/screens/event_participants_screen.dart
// (REBUILT — premium UI + capacity summary)
//
// CHANGE FROM BEFORE
// - Added an optional volunteersNeeded param so this screen can show
//   the same "X of Y joined" progress the event card already shows,
//   instead of just a bare count.
// - Each participant tile is now a proper card with avatar, name,
//   a tappable phone number (opens the dialer), email, and when they
//   joined — matching the "premium" look used elsewhere in Admin.
// - The underlying data source is unchanged: this still reads live
//   from events/{eventId}/participants via StreamBuilder. If a name/
//   phone looks blank for an OLDER participant, that's not this
//   screen's bug — see the note at the bottom of this file.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class EventParticipantsScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final int volunteersNeeded; // NEW — 0 means "no target specified"

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.volunteersNeeded = 0,
  });

  static const Color _blue = Color(0xFF1565C0);
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
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
            return const Center(child: CircularProgressIndicator(color: _blue));
          }

          final docs = List.from(snapshot.data?.docs ?? [])
            ..sort((a, b) {
              final aTs = (a.data() as Map)['joinedAt'] as Timestamp?;
              final bTs = (b.data() as Map)['joinedAt'] as Timestamp?;
              if (aTs == null || bTs == null) return 0;
              return bTs.compareTo(aTs);
            });

          return Column(
            children: [
              _SummaryHeader(joined: docs.length, needed: volunteersNeeded),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No volunteers joined yet', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _ParticipantTile(data: data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================================================
// SUMMARY HEADER — capacity progress, matching the event card's own
// "X of Y" indicator so the numbers always agree with what Admin saw
// before tapping in.
// ==========================================================================
class _SummaryHeader extends StatelessWidget {
  final int joined;
  final int needed;

  const _SummaryHeader({required this.joined, required this.needed});

  static const Color _blue = Color(0xFF1565C0);
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final bool hasTarget = needed > 0;
    final bool isFull = hasTarget && joined >= needed;
    final double progress = hasTarget ? (joined / needed).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isFull ? Icons.check_circle_rounded : Icons.people_alt_rounded,
                  color: isFull ? _green : _blue, size: 20),
              const SizedBox(width: 8),
              Text(
                hasTarget ? '$joined of $needed Volunteers' : '$joined Volunteers Joined',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isFull ? _green : _blue),
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFF4F6F8),
                valueColor: AlwaysStoppedAnimation<Color>(isFull ? _green : _blue),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFull ? 'This event is fully staffed.' : '${needed - joined} more volunteer(s) needed.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// PARTICIPANT TILE
// ==========================================================================
class _ParticipantTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ParticipantTile({required this.data});

  static const Color _blue = Color(0xFF1565C0);

  String _formatJoinedAt(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String name = (data['volunteerName'] ?? 'Volunteer').toString();
    final String email = (data['volunteerEmail'] ?? '').toString();
    final String phone = (data['volunteerPhone'] ?? '').toString();
    final String joinedAt = _formatJoinedAt(data['joinedAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                style: const TextStyle(color: _blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(email,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('tel:$phone')),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 12, color: _blue),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(fontSize: 11.5, color: _blue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                if (phone.isEmpty) ...[
                  // NEW — makes an incomplete OLDER record visible instead
                  // of silently showing a blank line, and explains why:
                  // this volunteer joined before phone numbers were
                  // captured correctly (see file header). New joins from
                  // now on will always have it.
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.phone_disabled_outlined, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('No phone on file', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
                if (joinedAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Joined $joinedAt', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}