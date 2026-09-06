import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonorImpactTab extends StatelessWidget {
  const DonorImpactTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
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
                children: [
                  const Text(
                    '❤️ Your Impact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See how your donations changed lives',
                    style: TextStyle(
                      color:
                      Colors.white.withOpacity(0.8),
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
    final String date =
        data['utilizationDate'] ?? '';
    final List images =
        data['impactImages'] as List? ?? [];
    final List items =
        data['itemsUtilized'] as List? ?? [];
    final List docs =
        data['proofDocuments'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // Main image
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: images.isNotEmpty
                    ? Image.network(
                  images[0],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(),
                )
                    : _imagePlaceholder(),
              ),
              // Gradient
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Completed badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.white,
                          size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Campaign name overlay
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Text(
                  campaign,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 4)
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    Icon(
                        Icons.calendar_today_outlined,
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

                // Stats row
                Row(
                  children: [
                    if (fundUsed > 0)
                      _ImpactStat(
                        icon: Icons.payments_rounded,
                        value:
                        'Rs. ${fundUsed.toStringAsFixed(0)}',
                        label: 'Utilized',
                        color: _green,
                        bg: const Color(0xFFE8F5E9),
                      ),
                    if (fundUsed > 0)
                      const SizedBox(width: 10),
                    _ImpactStat(
                      icon: Icons.people_rounded,
                      value: '$beneficiaries',
                      label: 'Beneficiaries',
                      color:
                      const Color(0xFF6A1B9A),
                      bg: const Color(0xFFF3E5F5),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _ImpactStat(
                        icon:
                        Icons.inventory_2_rounded,
                        value:
                        '${items.length} types',
                        label: 'Resources',
                        color:
                        const Color(0xFF00838F),
                        bg: const Color(0xFFE0F7FA),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

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
                  const Text(
                    'More Photos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (images.length - 1)
                          .clamp(0, 5),
                      itemBuilder: (ctx, i) {
                        return GestureDetector(
                          onTap: () =>
                              _viewImage(
                                  context,
                                  images[i + 1]),
                          child: Container(
                            width: 72,
                            height: 72,
                            margin:
                            const EdgeInsets.only(
                                right: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(
                                  10),
                              image: DecorationImage(
                                image: NetworkImage(
                                    images[i + 1]),
                                fit: BoxFit.cover,
                              ),
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
                      Icon(
                          Icons
                              .receipt_long_outlined,
                          size: 14,
                          color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '${docs.length} proof document(s) available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            _showDocuments(
                                context, docs),
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            const Color(0xFF1B6B3A),
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
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

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(
          Icons.volunteer_activism_outlined,
          size: 56,
          color: Color(0xFF1B6B3A),
        ),
      ),
    );
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url,
              fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _showDocuments(
      BuildContext context, List docs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Proof Documents',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...docs.map((doc) {
              final d =
              doc as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(
                    Icons
                        .insert_drive_file_outlined,
                    color: Color(0xFF1B6B3A)),
                title: Text(d['name'] ?? ''),
                subtitle: Text(d['type'] ?? ''),
                trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14),
                onTap: () {
                  Navigator.pop(context);
                  _viewImage(
                      context, d['url'] ?? '');
                },
              );
            }),
          ],
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
  final Color bg;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500]),
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
          Icon(Icons.favorite_outline,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No impact records yet',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Your donations are making a difference!\nImpact will be shown here.',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}