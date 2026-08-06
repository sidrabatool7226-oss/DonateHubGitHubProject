import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/utilization_controller.dart';

class UtilizationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const UtilizationDetailScreen({super.key, required this.data});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final String campaign = data['campaignName'] ?? '';
    final String donationType = data['donationType'] ?? 'fund';
    final double fundUsed =
    (data['fundAmountUsed'] ?? 0).toDouble();
    final int beneficiaries = data['beneficiaries'] ?? 0;
    final String description = data['description'] ?? '';
    final String date = data['utilizationDate'] ?? '';
    final String status = data['status'] ?? 'draft';
    final List images = data['impactImages'] as List? ?? [];
    final List items =
        data['itemsUtilized'] as List? ?? [];
    final List docs =
        data['proofDocuments'] as List? ?? [];
    final bool isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _green,
            foregroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                  Icons.arrow_back_ios_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    images[0],
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _green.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    size: 60,
                    color: Colors.white54,
                  ),
                ),
              ),
              title: Text(
                campaign,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // ── Status + Date ─────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green[300]!
                                : Colors.orange[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.pending_outlined,
                              size: 14,
                              color: isCompleted
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted
                                  ? 'Completed'
                                  : 'Draft',
                              style: TextStyle(
                                fontSize: 12,
                                color: isCompleted
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined,
                          size: 14,
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
                  const SizedBox(height: 16),

                  // ── Summary Cards ─────────────────────────────
                  Row(
                    children: [
                      if (donationType != 'resource')
                        _SummaryTile(
                          icon: Icons.payments_rounded,
                          value:
                          'Rs. ${fundUsed.toStringAsFixed(0)}',
                          label: 'Fund Used',
                          color: _green,
                          bg: const Color(0xFFE8F5E9),
                        ),
                      if (donationType != 'resource')
                        const SizedBox(width: 10),
                      _SummaryTile(
                        icon: Icons.people_rounded,
                        value: '$beneficiaries',
                        label: 'Beneficiaries',
                        color: const Color(0xFF6A1B9A),
                        bg: const Color(0xFFF3E5F5),
                      ),
                      if (donationType != 'fund') ...[
                        const SizedBox(width: 10),
                        _SummaryTile(
                          icon: Icons.inventory_2_rounded,
                          value: '${items.length}',
                          label: 'Item Types',
                          color: const Color(0xFF00838F),
                          bg: const Color(0xFFE0F7FA),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ───────────────────────────────
                  _DetailSection(
                    title: 'Description',
                    icon: Icons.description_outlined,
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  // ── Items Utilized ────────────────────────────
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSection(
                      title: 'Items Utilized',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: items.map((item) {
                          final m =
                          item as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 8),
                            padding: const EdgeInsets.all(
                                10),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFE0F7FA),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons
                                        .inventory_2_outlined,
                                    size: 16,
                                    color: Color(0xFF00838F)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        m['itemName'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight
                                                .w600),
                                      ),
                                      Text(
                                        m['category'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFF00838F),
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                  ),
                                  child: Text(
                                    'Qty: ${m['quantity']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // ── Impact Photos Gallery ─────────────────────
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSection(
                      title:
                      'Impact Photos (${images.length})',
                      icon: Icons.photo_library_outlined,
                      child: Column(
                        children: [
                          // Main image
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(12),
                            child: Image.network(
                              images[0],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (images.length > 1) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 72,
                              child: ListView.builder(
                                scrollDirection:
                                Axis.horizontal,
                                itemCount: images.length - 1,
                                itemBuilder: (ctx, i) {
                                  return GestureDetector(
                                    onTap: () =>
                                        _showImageFullscreen(
                                          context,
                                          List<String>.from(
                                              images),
                                          i + 1,
                                        ),
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
                        ],
                      ),
                    ),
                  ],

                  // ── Proof Documents ───────────────────────────
                  if (docs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSection(
                      title:
                      'Proof Documents (${docs.length})',
                      icon: Icons.receipt_long_outlined,
                      child: Column(
                        children: docs.map((doc) {
                          final d =
                          doc as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFE8F5E9),
                                    borderRadius:
                                    BorderRadius.circular(
                                        10),
                                  ),
                                  child: const Icon(
                                      Icons
                                          .insert_drive_file_outlined,
                                      color:
                                      Color(0xFF1B6B3A),
                                      size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        d['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight
                                                .w600),
                                      ),
                                      Text(
                                        d['type'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _viewDocument(
                                          context,
                                          d['url'] ?? ''),
                                  child: Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFFE8F5E9),
                                      borderRadius:
                                      BorderRadius.circular(
                                          8),
                                    ),
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                        Color(0xFF1B6B3A),
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullscreen(BuildContext context,
      List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _viewDocument(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ==========================================================================
// FULLSCREEN GALLERY
// ==========================================================================
class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() =>
      _FullscreenGalleryState();
}

class _FullscreenGalleryState
    extends State<_FullscreenGallery> {
  late PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController =
        PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
            '${_current + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) =>
            setState(() => _current = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ==========================================================================
// DETAIL SECTION WIDGET
// ==========================================================================
class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _green),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _SummaryTile({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}