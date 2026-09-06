import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/volunteer_details_screen.dart';

class ManagerVolunteersListScreen extends StatelessWidget {
  const ManagerVolunteersListScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  static const List<String> _pendingStages = [
    'Pending',
    'Form_Reviewed',
    'Video_Scheduled',
    'Video_Completed',
    'Physical_Scheduled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pending Volunteers',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _emerald,
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load volunteers.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final stage =
            (data['verificationStage'] ?? 'Pending').toString();

            final status =
            (data['status'] ?? 'pending').toString().toLowerCase();

            return _pendingStages.contains(stage) ||
                (status == 'pending' && stage != 'Rejected');
          }).toList();

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];

            if (aTs is Timestamp && bTs is Timestamp) {
              return bTs.compareTo(aTs);
            }

            return 0;
          });

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = Map<String, dynamic>.from(
                doc.data() as Map<String, dynamic>,
              );

              return _VolunteerCard(
                docId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5EE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: _emerald,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Volunteers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14251E),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'There are no volunteer applications waiting for review.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _VolunteerCard({
    required this.docId,
    required this.data,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _timeAgo(dynamic value) {
    if (value is! Timestamp) return '';

    final difference = DateTime.now().difference(value.toDate());

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }

    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }

    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final String name = _text(data['name']).isEmpty
        ? 'Volunteer'
        : _text(data['name']);

    final String email = _text(data['email']);

    final String phone = _text(data['phone']);

    final String stage = _text(data['verificationStage']).isEmpty
        ? 'Pending'
        : _text(data['verificationStage']);

    final List categories = data['categories'] is List
        ? data['categories'] as List
        : <dynamic>[];

    final String joined = _timeAgo(data['createdAt']);

    return GestureDetector(
      onTap: () {
        Get.to(
              () => VolunteerDetailsScreen(
            docId: docId,
            data: data,
          ),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F5EE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    color: _emerald,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14251E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFFDB7C26),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stage.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (joined.isNotEmpty)
                        Text(
                          joined,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: categories.take(3).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.toString(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}