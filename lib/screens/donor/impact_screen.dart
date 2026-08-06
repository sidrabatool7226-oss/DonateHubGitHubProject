import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorImpactScreen extends StatelessWidget {
  const DonorImpactScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                  20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, Color(0xFF2D8A52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Your Impact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'See how your donations made a difference',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('utilization')
                    .where('status',
                    isEqualTo: 'completed')
                    .orderBy('createdAt',
                    descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: _green),
                    );
                  }

                  final docs =
                      snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _EmptyImpact();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data()
                      as Map<String, dynamic>;
                      return _ImpactCard(data: data);
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

// ==========================================================================
// IMPACT CARD — Donor side
// ==========================================================================
class _ImpactCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ImpactCard({required this.data});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String campaign = data['campaignName'] ?? '';
    final double fundUsed =
    (data['fundAmountUsed'] ?? 0).toDouble();
    final int beneficiaries =
        data['beneficiaries'] ?? 0;
    final String description =
        data['description'] ?? '';
    final String date = data['utilizationDate'] ?? '';
    final List images =
        data['impactImages'] as List? ?? [];
    final List items =
        data['itemsUtilized'] as List? ?? [];
    final List docs =
        data['proofDocuments'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Impact image
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: Image.network(
                images[0],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _placeholder(),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: _placeholder(),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Campaign name + completed badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 12,
                              color: Colors.green[700]),
                          const SizedBox(width: 3),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    if (fundUsed > 0)
                      _ImpactStat(
                        icon: Icons.payments_rounded,
                        value:
                        'Rs. ${fundUsed.toStringAsFixed(0)}',
                        label: 'Utilized',
                        color: _green,
                      ),
                    _ImpactStat(
                      icon: Icons.people_rounded,
                      value: '$beneficiaries',
                      label: 'Helped',
                      color: const Color(0xFF6A1B9A),
                    ),
                    if (items.isNotEmpty)
                      _ImpactStat(
                        icon:
                        Icons.inventory_2_rounded,
                        value: '${items.length} types',
                        label: 'Resources',
                        color: const Color(0xFF00838F),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Photo strip
                if (images.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                      (images.length - 1).clamp(0, 4),
                      itemBuilder: (ctx, i) {
                        return Container(
                          width: 56,
                          height: 56,
                          margin:
                          const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(8),
                            image: DecorationImage(
                              image:
                              NetworkImage(images[i + 1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Documents
                if (docs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 14,
                          color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${docs.length} proof document(s) available',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(
          Icons.volunteer_activism_outlined,
          size: 48,
          color: Color(0xFF1B6B3A),
        ),
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyImpact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No impact records yet',
            style: TextStyle(
                fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Utilization records will appear here\nonce donations are utilized',
            style: TextStyle(
                fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}