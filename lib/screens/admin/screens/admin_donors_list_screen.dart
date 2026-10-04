import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../widgets/admin_account_status_card.dart';
import '../../../widgets/admin_donation_kit.dart';

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Copied'),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
        backgroundColor: DonationKit.green,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

bool _isInactive(Map<String, dynamic> data) =>
    (data['status'] ?? 'active').toString() == 'inactive';


// DONORS LIST
class AdminDonorsListScreen extends StatelessWidget {
  const AdminDonorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationKit.bg,
      appBar: AppBar(
        backgroundColor: DonationKit.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Donors',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: const _DonorsListBody(),
    );
  }
}

class _DonorsListBody extends StatefulWidget {
  const _DonorsListBody();

  @override
  State<_DonorsListBody> createState() => _DonorsListBodyState();
}

class _DonorsListBodyState extends State<_DonorsListBody> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _created(QueryDocumentSnapshot doc) {
    final c = (doc.data() as Map<String, dynamic>)['createdAt'];
    return c is Timestamp ? c.millisecondsSinceEpoch : 0;
  }

  bool _matches(Map<String, dynamic> data) {
    final String haystack = [
      data['name'],
      data['email'],
      data['username'],
      data['country'],
      data['mobileNumber'],
    ].map((v) => DonationKit.valueText(v).toLowerCase()).join(' ');
    return haystack.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DonationKit.green),
          );
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load donors',
            subtitle: 'Please check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot> all = snapshot.data?.docs ?? [];

        int inactive = 0;
        for (final doc in all) {
          if (_isInactive(doc.data() as Map<String, dynamic>)) inactive++;
        }
        final int active = all.length - inactive;

        final List<QueryDocumentSnapshot> shown = all.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool off = _isInactive(data);
          if (_filter == 'active' && off) return false;
          if (_filter == 'inactive' && !off) return false;
          if (_query.isEmpty) return true;
          return _matches(data);
        }).toList()
          ..sort((a, b) => _created(b).compareTo(_created(a)));

        return LayoutBuilder(
          builder: (context, c) {
            final bool wide = c.maxWidth >= 900;
            // The scroll view spans the whole window; the content is centred to 1100px.
            final double side = c.maxWidth > 1100 ? (c.maxWidth - 1100) / 2 : 0;
            final double hp = (wide ? 24.0 : 16.0) + side;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hp, wide ? 24 : 16, hp, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SummaryHeader(
                      total: all.length,
                      active: active,
                      inactive: inactive,
                      wide: wide,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 14),
                  sliver: SliverToBoxAdapter(
                    child: _buildFilters(
                      wide: wide,
                      all: all.length,
                      active: active,
                      inactive: inactive,
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: all.isEmpty
                        ? const _EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No donors yet',
                      subtitle: 'Registered donors will appear here.',
                    )
                        : const _EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No donors match',
                      subtitle: 'Try a different search or filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
                    sliver: wide
                        ? SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => _cardFor(shown[i]),
                        childCount: shown.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 112,
                      ),
                    )
                        : SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _cardFor(shown[i]),
                        ),
                        childCount: shown.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _cardFor(QueryDocumentSnapshot userDoc) {
    final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    final String uid = userDoc.id;
    return _DonorCard(
      key: ValueKey(uid), // keeps each card's cached lookup alive while searching
      uid: uid,
      data: data,
      onOpen: (points, totalDonations) => Get.to(
            () => AdminDonorDetailsScreen(
          docId: uid,
          donorData: data,
          rewardPoints: points,
          totalDonations: totalDonations,
        ),
        transition: Transition.rightToLeft,
      ),
    );
  }

  // ── filter chips + search ───────────────────────────────────────────
  Widget _buildFilters({
    required bool wide,
    required int all,
    required int active,
    required int inactive,
  }) {
    final Widget chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('all', 'All', all),
          const SizedBox(width: 8),
          _chip('active', 'Active', active),
          const SizedBox(width: 8),
          _chip('inactive', 'Deactivated', inactive),
        ],
      ),
    );

    final Widget search = TextField(
      controller: _search,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search name, email or country',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: 20),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
          icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey[500]),
          onPressed: () {
            _search.clear();
            setState(() => _query = '');
          },
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DonationKit.green, width: 1.4),
        ),
      ),
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: chips),
          const SizedBox(width: 16),
          SizedBox(width: 340, child: search),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [chips, const SizedBox(height: 10), search],
    );
  }

  Widget _chip(String key, String label, int count) {
    final bool selected = _filter == key;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? DonationKit.green : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? DonationKit.green : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : DonationKit.ink,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.22)
                      : const Color(0xFFEFF2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── summary header ─────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final int total;
  final int active;
  final int inactive;
  final bool wide;

  const _SummaryHeader({
    required this.total,
    required this.active,
    required this.inactive,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(wide ? 24 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6B3A), Color(0xFF2D8A52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6B3A).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Icon(
              Icons.favorite_rounded,
              size: wide ? 150 : 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: wide ? 48 : 42,
                    height: wide ? 48 : 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.white,
                      size: wide ? 26 : 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our donors',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: wide ? 19 : 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'The people who make it happen',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: wide ? 20 : 16),
              Row(
                children: [
                  Expanded(child: _HeaderStat(label: 'Total', value: '$total', wide: wide)),
                  const SizedBox(width: 10),
                  Expanded(child: _HeaderStat(label: 'Active', value: '$active', wide: wide)),
                  const SizedBox(width: 10),
                  Expanded(child: _HeaderStat(label: 'Deactivated', value: '$inactive', wide: wide)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final bool wide;
  const _HeaderStat({required this.label, required this.value, required this.wide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: wide ? 14 : 11, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: wide ? 24 : 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ── one donor ──────────────────────────────────────────────────────────
// Stateful ONLY so the 'donors/{uid}' lookup (points + donation count) is made once per
// card instead of again on every keystroke in the search box.
class _DonorCard extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final void Function(dynamic points, dynamic totalDonations) onOpen;

  const _DonorCard({
    super.key,
    required this.uid,
    required this.data,
    required this.onOpen,
  });

  @override
  State<_DonorCard> createState() => _DonorCardState();
}

class _DonorCardState extends State<_DonorCard> {
  late Future<DocumentSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseFirestore.instance.collection('donors').doc(widget.uid).get();
  }

  Future<void> _open() async {
    dynamic points = 0;
    dynamic total = 0;
    try {
      final snap = await _future;
      final d = snap.data() as Map<String, dynamic>?;
      points = d?['rewardPoints'] ?? 0;
      total = d?['totalDonations'] ?? 0;
    } catch (_) {}
    if (!mounted) return;
    widget.onOpen(points, total);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.data;
    final String rawName = DonationKit.valueText(data['name']);
    final String name = rawName.isEmpty ? 'Donor' : rawName;
    final String email = DonationKit.valueText(data['email']);
    final String country = DonationKit.valueText(data['country']);
    final bool inactive = _isInactive(data);

    return FutureBuilder<DocumentSnapshot>(
      future: _future,
      builder: (context, donorSnap) {
        final bool loaded = donorSnap.connectionState == ConnectionState.done;
        final donorData = donorSnap.data?.data() as Map<String, dynamic>?;
        final dynamic points = donorData?['rewardPoints'] ?? 0;
        final dynamic totalDonations = donorData?['totalDonations'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _open,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: DonationKit.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        // quick active / deactivated glance
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: inactive ? Colors.red : const Color(0xFF2FBF87),
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: DonationKit.ink,
                                  ),
                                ),
                              ),
                              if (inactive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDECEA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Deactivated',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                            ),
                          ],
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (country.isNotEmpty)
                                _MiniChip(
                                  icon: Icons.public_rounded,
                                  text: country,
                                  color: const Color(0xFF455A64),
                                  bg: const Color(0xFFECEFF1),
                                ),
                              _MiniChip(
                                icon: Icons.volunteer_activism_rounded,
                                text: loaded
                                    ? '$totalDonations donation${totalDonations == 1 ? '' : 's'}'
                                    : '… donations',
                                color: DonationKit.green,
                                bg: const Color(0xFFE8F5E9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF9A825)),
                            const SizedBox(width: 3),
                            Text(
                              loaded ? '$points' : '–',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: DonationKit.green,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'points',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  const _MiniChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: DonationKit.green.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: DonationKit.green.withOpacity(0.7)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DonationKit.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// DONOR DETAILS
// ==========================================================================
// Same class name and constructor fields as before (docId, donorData, rewardPoints,
// totalDonations) — opened from the Donors list AND from User Management.
class AdminDonorDetailsScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> donorData;
  final dynamic rewardPoints;
  final dynamic totalDonations;

  const AdminDonorDetailsScreen({
    super.key,
    required this.docId,
    required this.donorData,
    required this.rewardPoints,
    required this.totalDonations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationKit.bg,
      appBar: AppBar(
        backgroundColor: DonationKit.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Donor Details',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final bool wide = c.maxWidth >= 860;
          // The scroll view spans the whole window; the content is centred to 1040px.
          final double side = c.maxWidth > 1040 ? (c.maxWidth - 1040) / 2 : 0;
          final double hp = (wide ? 24.0 : 16.0) + side;

          final Widget statusCard = _Elevated(
            child: AdminAccountStatusCard(docId: docId, roleLabel: 'Donor'),
          );
          final Widget contactCard = _contactCard();

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hp, wide ? 24 : 16, hp, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DonorHero(docId: docId, donorData: donorData, wide: wide),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.volunteer_activism_rounded,
                        color: DonationKit.green,
                        bg: const Color(0xFFE8F5E9),
                        value: DonationKit.hasValue(totalDonations)
                            ? DonationKit.valueText(totalDonations)
                            : '0',
                        label: 'Total donations',
                        wide: wide,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF9A825),
                        bg: const Color(0xFFFFF8E1),
                        value: DonationKit.hasValue(rewardPoints)
                            ? DonationKit.valueText(rewardPoints)
                            : '0',
                        label: 'Reward points',
                        wide: wide,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: contactCard),
                      const SizedBox(width: 16),
                      Expanded(child: statusCard),
                    ],
                  )
                else ...[
                  statusCard,
                  const SizedBox(height: 16),
                  contactCard,
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _contactCard() {
    final String country = DonationKit.valueText(donorData['country']);
    final bool pakistan = country.toLowerCase() == 'pakistan';
    final String idLabel = pakistan ? 'CNIC' : 'Passport number';
    final String idValue = DonationKit.valueText(
      pakistan ? donorData['cnic'] : donorData['passportNumber'],
    );

    final List<Widget> rows = [];
    void add(String label, dynamic value, {bool copy = false}) {
      final String text = DonationKit.valueText(value);
      if (text.isEmpty) return;
      rows.add(_Row(label: label, value: text, copy: copy));
    }

    add('Username', donorData['username']);
    add('Email', donorData['email'], copy: true);
    add('Mobile', donorData['mobileNumber'], copy: true);
    add('Country', donorData['country']);
    // An identity document that is missing is worth flagging, so it is always shown.
    rows.add(_Row(
      label: idLabel,
      value: idValue.isEmpty ? 'Not provided' : idValue,
      copy: idValue.isNotEmpty,
      muted: idValue.isEmpty,
    ));
    add('Registered', DonationKit.fmtDate(donorData['createdAt'], time: false));

    return _Elevated(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_rounded, size: 19, color: Color(0xFF6A1B9A)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Contact & identity',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DonationKit.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}

// White rounded card with the same soft shadow used on every premium screen.
class _Elevated extends StatelessWidget {
  final Widget child;
  const _Elevated({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool copy;
  final bool muted;
  const _Row({
    required this.label,
    required this.value,
    this.copy = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                color: muted ? Colors.grey[500] : DonationKit.ink,
                height: 1.3,
              ),
            ),
          ),
          if (copy)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _copy(context, value),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String value;
  final String label;
  final bool wide;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.value,
    required this.label,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return _Elevated(
      child: Padding(
        padding: EdgeInsets.all(wide ? 20 : 16),
        child: Row(
          children: [
            Container(
              width: wide ? 54 : 44,
              height: wide ? 54 : 44,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: wide ? 28 : 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: wide ? 30 : 24,
                        fontWeight: FontWeight.w800,
                        color: DonationKit.ink,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(fontSize: wide ? 13 : 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorHero extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> donorData;
  final bool wide;

  const _DonorHero({
    required this.docId,
    required this.donorData,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final String rawName = DonationKit.valueText(donorData['name']);
    final String name = rawName.isEmpty ? 'Donor' : rawName;
    final String email = DonationKit.valueText(donorData['email']);
    final String country = DonationKit.valueText(donorData['country']);
    final String since = DonationKit.fmtDate(donorData['createdAt'], time: false);

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6B3A), Color(0xFF2D8A52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B6B3A).withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.favorite_rounded,
              size: wide ? 170 : 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
                ),
                child: CircleAvatar(
                  radius: wide ? 42 : 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: DonationKit.green,
                      fontSize: wide ? 32 : 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: wide ? 22 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: wide ? 28 : 21,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: wide ? 14.5 : 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // live — follows the activate / deactivate button below
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(docId)
                              .snapshots(),
                          builder: (context, snap) {
                            final live = snap.data?.data() as Map<String, dynamic>?;
                            final bool off = _isInactive(live ?? donorData);
                            return _HeroChip(
                              icon: off ? Icons.cancel_rounded : Icons.check_circle_rounded,
                              text: off ? 'Deactivated' : 'Active',
                              solid: true,
                              color: off ? const Color(0xFFC62828) : DonationKit.green,
                            );
                          },
                        ),
                        if (country.isNotEmpty)
                          _HeroChip(icon: Icons.public_rounded, text: country),
                        if (since.isNotEmpty)
                          _HeroChip(icon: Icons.event_rounded, text: 'Since $since'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool solid;
  final Color color;
  const _HeroChip({
    required this.icon,
    required this.text,
    this.solid = false,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solid ? Colors.white : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: solid ? color : Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: solid ? color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}