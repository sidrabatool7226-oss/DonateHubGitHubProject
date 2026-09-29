import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'donor_campaigns_tab.dart';
import 'package:get/get.dart';
import '../admin/screens/shared/notifications_screen.dart';
import '../../widgets/notification_bell_icon.dart'; // NEW
import 'sponsor_a_child_screen.dart'; // NEW
import 'child_sponsorship_detail_screen.dart'; // NEW
import 'widgets/campaign_donation_sheet.dart'; // NEW
class DonorHomeTab extends StatefulWidget {
  final VoidCallback? onGoToProfile;
  const DonorHomeTab({super.key, this.onGoToProfile});

  @override
  State<DonorHomeTab> createState() => _DonorHomeTabState();
}

class _DonorHomeTabState extends State<DonorHomeTab> {
  // ── Brand green colors ────────────────────────────────────────────────
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bgGray = Color(0xFFF4F6F8);

  // ── Firebase ──────────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Get logged-in donor name ──────────────────────────────────────────
  Future<String> _getDonorName() async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) {
        return 'donor';
      }

      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists) {
        return doc.data()?['name'] ?? 'donor';
      }

      return _auth.currentUser?.displayName ?? 'donor';
    } catch (_) {
      return 'donor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,

      // ─────────────────────────────────────────────────────────────────
      // APP BAR
      // ─────────────────────────────────────────────────────────────────
      appBar: _buildAppBar(),

      // ─────────────────────────────────────────────────────────────────
      // HOME BODY
      // ─────────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card
            _WelcomeCard(
              getDonorName: _getDonorName,
              green: _green,
            ),

            const SizedBox(height: 18),

            // 2. DONATE NOW — NEW, same banner already used at the top of
            // the Campaigns & Projects browse screen, now also here so
            // it's the first real action a donor sees on Home.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/donate_funds'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), _green],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Donate Now', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Campaign, Project, or Fund', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 3. Three ways to give — NEW, one representative poster each
            // for Campaign / Sponsor a Child / Project, side by side.
            const _SectionTitle(title: 'Ways to Give'),
            const SizedBox(height: 10),
            _ThreeWayPosterRow(db: _db),

            const SizedBox(height: 24),

            // 4. How would you like to help?
            const _SectionTitle(
              title: 'How would you like to help?',
            ),

            const SizedBox(height: 12),

            // ───────────────────────────────────────────────────────────
            // DONATE ITEMS
            // Existing route — NOT changing your donation flow
            // ───────────────────────────────────────────────────────────
            _DonationActionCard(
              title: 'Donate Items',
              subtitle: 'Clothes, food, toys & supplies',
              imageAsset: 'assets/images/donate_items.png',
              buttonColor: _green,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/donate_items',
                );
              },
            ),

            const SizedBox(height: 14),

            // ───────────────────────────────────────────────────────────
            // DONATE FUNDS — CHANGED back from "Donate Now" (the top
            // banner above now owns that name). Same existing route —
            // that screen lets the donor pick Campaign / Project / Fund
            // / Sponsor as the target.
            // ───────────────────────────────────────────────────────────
            _DonationActionCard(
              title: 'Donate Funds',
              subtitle: 'Campaign, Project, or Fund',
              imageAsset: 'assets/images/donate_funds.png',
              buttonColor: _lightGreen,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/donate_funds',
                );
              },
            ),

            // Bottom space
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // APP BAR
  // =========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,

      title: Row(
        children: [
          // DonateHub D logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'DonateHub',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      // NEW — notification bell (live unread badge) + profile shortcut.
      actions: [
        NotificationBellIcon(
          accentColor: _green,
          iconBackgroundColor: const Color(0xFFE8F5E9),
          iconColor: _green,
          borderColor: Colors.transparent,
          size: 40,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => widget.onGoToProfile?.call(),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: _green, size: 20),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WELCOME CARD
// ============================================================================

class _WelcomeCard extends StatelessWidget {
  final Future<String> Function() getDonorName;
  final Color green;

  const _WelcomeCard({
    required this.getDonorName,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDonorName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            0,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                green,
                const Color(0xFF2D8A52),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty
                          ? 'Welcome back! 👋'
                          : 'Welcome back, $name! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Thank you for making a difference',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Heart decoration
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER ROW (NEW) — title + "See All" for the 3 new preview rows
// ============================================================================

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeaderRow({required this.title, required this.onSeeAll});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See All', style: TextStyle(fontSize: 12.5, color: _green, fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// THREE WAY POSTER ROW (NEW) — one representative Campaign, Sponsor a
// Child, and Project poster, side by side. Each tile links straight to
// donating/sponsoring that SPECIFIC item, reusing the exact same sheets
// already used elsewhere (CampaignDonationSheet, ChildSponsorshipDetailScreen)
// instead of duplicating that logic here.
// ============================================================================

class _ThreeWayPosterRow extends StatelessWidget {
  final FirebaseFirestore db;
  const _ThreeWayPosterRow({required this.db});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('campaigns')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs); // newest first
          });

        QueryDocumentSnapshot? campaignDoc;
        QueryDocumentSnapshot? sponsorDoc;
        QueryDocumentSnapshot? projectDoc;

        for (final doc in docs) {
          final cat = ((doc.data() as Map)['category'] ?? 'campaign').toString();
          if (cat == 'campaign' && campaignDoc == null) campaignDoc = doc;
          if (cat == 'sponsorship' && sponsorDoc == null) sponsorDoc = doc;
          if (cat == 'project' && projectDoc == null) projectDoc = doc;
        }

        return SizedBox(
          height: 172,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _campaignTile(context, campaignDoc)),
                const SizedBox(width: 10),
                Expanded(child: _sponsorTile(context, sponsorDoc)),
                const SizedBox(width: 10),
                Expanded(child: _projectTile(context, projectDoc)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _campaignTile(BuildContext context, QueryDocumentSnapshot? doc) {
    if (doc == null) {
      return const _PosterTile(
        title: 'No campaigns yet',
        buttonLabel: 'Donate to Campaign',
        placeholderIcon: Icons.campaign_outlined,
        isEmpty: true,
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    return _PosterTile(
      title: (data['title'] ?? 'Campaign').toString(),
      imageUrl: (data['image'] ?? '').toString(),
      buttonLabel: 'Donate to Campaign',
      placeholderIcon: Icons.campaign_outlined,
      onTap: () => _openDonateSheet(context, doc.id, (data['title'] ?? 'Campaign').toString()),
    );
  }

  Widget _projectTile(BuildContext context, QueryDocumentSnapshot? doc) {
    if (doc == null) {
      return const _PosterTile(
        title: 'No projects yet',
        buttonLabel: 'Donate to a Project',
        placeholderIcon: Icons.rocket_launch_outlined,
        isEmpty: true,
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    return _PosterTile(
      title: (data['title'] ?? 'Project').toString(),
      imageUrl: (data['image'] ?? '').toString(),
      buttonLabel: 'Donate to a Project',
      placeholderIcon: Icons.rocket_launch_outlined,
      onTap: () => _openDonateSheet(context, doc.id, (data['title'] ?? 'Project').toString()),
    );
  }

  Widget _sponsorTile(BuildContext context, QueryDocumentSnapshot? doc) {
    if (doc == null) {
      return const _PosterTile(
        title: 'No children yet',
        buttonLabel: 'Sponsor Now',
        placeholderIcon: Icons.child_care_outlined,
        isEmpty: true,
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    return _PosterTile(
      title: (data['title'] ?? 'Child').toString(),
      imageUrl: (data['image'] ?? '').toString(),
      buttonLabel: 'Sponsor Now',
      placeholderIcon: Icons.child_care_outlined,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChildSponsorshipDetailScreen(childId: doc.id, childData: data)),
      ),
    );
  }

  void _openDonateSheet(BuildContext context, String id, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CampaignDonationSheet(campaignId: id, campaignName: name),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final IconData placeholderIcon;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isEmpty;

  const _PosterTile({
    required this.title,
    required this.buttonLabel,
    required this.placeholderIcon,
    this.imageUrl,
    this.onTap,
    this.isEmpty = false,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEmpty ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 82,
                width: double.infinity,
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isEmpty ? Colors.grey[200] : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isEmpty ? Colors.grey[500] : _green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Icon(placeholderIcon, color: _green, size: 26),
    );
  }
}

// ============================================================================
// CAMPAIGNS ROW
// ============================================================================

class _CampaignsRow extends StatelessWidget {
  final FirebaseFirestore db;
  final String categoryFilter; // NEW — 'campaign' or 'project'

  const _CampaignsRow({
    required this.db,
    required this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('campaigns')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B6B3A),
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Could not load campaigns.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String cat = (data['category'] ?? 'campaign').toString();
          return data['isActive'] == true && cat == categoryFilter;
        }).toList();

        // Empty
        if (docs.isEmpty) {
          return SizedBox(
            height: 80,
            child: Center(
              child: Text(
                categoryFilter == 'project' ? 'No active projects yet.' : 'No active campaigns yet.',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        // Campaign cards
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data()
              as Map<String, dynamic>;

              return _CampaignCard(
                data: data,
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// CHILDREN ROW (NEW) — Sponsor-a-Child preview on Home
// ============================================================================

class _ChildrenRow extends StatelessWidget {
  final FirebaseFirestore db;

  const _ChildrenRow({required this.db});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('campaigns')
          .where('category', isEqualTo: 'sponsorship')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator(color: _green)),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('Could not load children.', style: TextStyle(color: Colors.grey))),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('No children available yet.', style: TextStyle(color: Colors.grey))),
          );
        }

        return SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String name = (data['title'] ?? 'Child').toString();
              final String age = (data['age'] ?? '').toString();
              final String imageUrl = (data['image'] ?? '').toString();

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildSponsorshipDetailScreen(childId: doc.id, childData: data),
                  ),
                ),
                child: Container(
                  width: 128,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _childPlaceholder(),
                        )
                            : _childPlaceholder(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (age.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(age, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _childPlaceholder() {
    return Container(
      height: 110,
      color: const Color(0xFFE8F5E9),
      child: const Center(child: Icon(Icons.child_care_rounded, size: 32, color: _green)),
    );
  }
}

// ============================================================================
// SINGLE CAMPAIGN CARD
// ============================================================================

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CampaignCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String title =
        data['title'] ?? 'Campaign';

    final String description =
        data['description'] ?? '';

    final double goal =
    (data['goalAmount'] ?? 0).toDouble();

    final double collected =
    (data['collectedAmount'] ?? 0).toDouble();

    final String imageUrl =
        data['image'] ?? '';

    final String endDate =
        data['endDate'] ?? '';

    final double progress = goal > 0
        ? (collected / goal).clamp(0.0, 1.0)
        : 0.0;

    // NEW — same category convention already used on the full Campaigns
    // tab / Admin / Manager screens. Older docs without this field are
    // treated as a plain Campaign.
    final String category =
    (data['category'] ?? 'campaign').toString();
    final bool isSponsorship = category == 'sponsorship';
    final String categoryLabel = category == 'project'
        ? 'Project'
        : isSponsorship
        ? 'Sponsor a Child'
        : 'Campaign';

    return Container(
      width: 260,
      margin: const EdgeInsets.only(
        right: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // Campaign image (+ category badge)
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: isSponsorship ? 150 : 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                      _imagePlaceholder(isSponsorship),
                  loadingBuilder:
                      (_, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return _imagePlaceholder(isSponsorship);
                  },
                )
                    : _imagePlaceholder(isSponsorship),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B6B3A),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Campaign details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: isSponsorship
                      ? TextAlign.center
                      : TextAlign.start,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                ),

                // NEW — "Sponsor a Child" entries skip the goal/progress
                // section entirely (a recurring sponsorship, not a
                // fundraising target with a collected amount) and just
                // show the name under the picture, matching the full
                // Campaigns tab's simplified sponsorship card.
                if (!isSponsorship) ...[
                  const SizedBox(height: 3),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Progress row
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),

                      Text(
                        'Rs. ${_fmt(collected)} / Rs. ${_fmt(goal)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          Color(0xFF1B6B3A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Progress bar
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(4),
                    child:
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor:
                      const Color(0xFFE0E0E0),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B6B3A),
                      ),
                    ),
                  ),

                  if (endDate.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      'Ends on $endDate',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }

    return value.toStringAsFixed(0);
  }

  Widget _imagePlaceholder([bool isSponsorship = false]) {
    return Container(
      height: isSponsorship ? 150 : 120,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: Icon(
        isSponsorship ? Icons.child_care_rounded : Icons.image_outlined,
        size: 40,
        color: const Color(0xFF1B6B3A),
      ),
    );
  }
}

// ============================================================================
// DONATION ACTION CARD
// ============================================================================

class _DonationActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color buttonColor;
  final VoidCallback onTap;

  const _DonationActionCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image.asset(
              imageAsset,
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 175,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        buttonColor
                            .withOpacity(0.15),
                        buttonColor
                            .withOpacity(0.05),
                      ],
                      begin:
                      Alignment.topLeft,
                      end:
                      Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          title ==
                              'Donate Items'
                              ? Icons
                              .inventory_2_outlined
                              : Icons
                              .attach_money_rounded,
                          size: 54,
                          color: buttonColor
                              .withOpacity(0.6),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          subtitle,
                          style: TextStyle(
                            color: buttonColor
                                .withOpacity(
                                0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Button
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onTap,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  buttonColor,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}