import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/admin_donation_kit.dart';
import 'admin_donation_details_screen.dart';

enum AdminDonationsListMode {
  approvedAndCompleted,
  pending,
}

// Same class name and constructor as before — the Home cards that open this screen
// (AdminDonationsListScreen(mode: ..., title: ...)) keep working.
class AdminDonationsListScreen extends StatelessWidget {
  final AdminDonationsListMode mode;
  final String title;

  const AdminDonationsListScreen({
    super.key,
    required this.mode,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DonationKit.bg,
      appBar: AppBar(
        backgroundColor: DonationKit.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: _DonationsListBody(mode: mode),
    );
  }
}

// Which donations belong on this screen — same rule as before.
bool _shouldShowDonation(AdminDonationsListMode mode, Map<String, dynamic> data) {
  if (data['isDeleted'] == true) {
    return false;
  }

  final String status = (data['status'] ?? '').toString().trim().toLowerCase();

  if (mode == AdminDonationsListMode.pending) {
    return status == 'pending';
  }
  // Approved and everything that moved on after approval (pickup_assigned, received, completed...)
  return DonationKit.approvedFamily.contains(status);
}

bool _matchesQuery(Map<String, dynamic> data, String query) {
  final String haystack = [
    data['donorName'],
    data['userEmail'],
    data['donorEmail'],
    data['itemName'],
    data['category'],
    data['campaignName'],
    data['donationTargetName'],
    data['transactionId'],
    data['verifiedAmount'] ?? data['amount'],
  ].map((v) => DonationKit.valueText(v).toLowerCase()).join(' ');
  return haystack.contains(query);
}

// ==========================================================================
// BODY  (summary + filters + list, all in ONE scroll)
// ==========================================================================
class _DonationsListBody extends StatefulWidget {
  final AdminDonationsListMode mode;
  const _DonationsListBody({required this.mode});

  @override
  State<_DonationsListBody> createState() => _DonationsListBodyState();
}

class _DonationsListBodyState extends State<_DonationsListBody> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filter = 'all'; // 'all' | 'fund' | 'resource'

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
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
            title: 'Could not load donations',
            subtitle: 'Please check your connection and try again.',
          );
        }

        final List<QueryDocumentSnapshot> all =
        (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _shouldShowDonation(widget.mode, data);
        }).toList();

        int fundCount = 0;
        double fundTotal = 0;
        for (final doc in all) {
          final data = doc.data() as Map<String, dynamic>;
          if (DonationKit.isFund(data)) {
            fundCount++;
            fundTotal += DonationKit.amountOf(data);
          }
        }
        final int resourceCount = all.length - fundCount;

        final List<QueryDocumentSnapshot> shown = all.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isFund = DonationKit.isFund(data);
          if (_filter == 'fund' && !isFund) return false;
          if (_filter == 'resource' && isFund) return false;
          if (_query.isEmpty) return true;
          return _matchesQuery(data, _query);
        }).toList();

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
                      mode: widget.mode,
                      total: all.length,
                      fundTotal: fundTotal,
                      resourceCount: resourceCount,
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
                      funds: fundCount,
                      resources: resourceCount,
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyFor(all.isEmpty),
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
                        mainAxisExtent: 116,
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

  Widget _cardFor(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _DonationCard(
      data: data,
      onTap: () => Get.to(
            () => AdminDonationDetailsScreen(
          donationId: doc.id,
          initialData: data,
        ),
        transition: Transition.rightToLeft,
      ),
    );
  }

  Widget _emptyFor(bool nothingAtAll) {
    if (nothingAtAll) {
      return _EmptyState(
        icon: widget.mode == AdminDonationsListMode.pending
            ? Icons.inbox_rounded
            : Icons.task_alt_rounded,
        title: widget.mode == AdminDonationsListMode.pending
            ? 'No pending donations'
            : 'No approved or completed donations',
        subtitle: widget.mode == AdminDonationsListMode.pending
            ? 'New submissions waiting for review will appear here.'
            : 'Approved donations will appear here.',
      );
    }
    return const _EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No donations match',
      subtitle: 'Try a different search or filter.',
    );
  }

  // ── filter chips + search ───────────────────────────────────────────
  Widget _buildFilters({
    required bool wide,
    required int all,
    required int funds,
    required int resources,
  }) {
    final Widget chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('all', 'All', all),
          const SizedBox(width: 8),
          _chip('fund', 'Funds', funds),
          const SizedBox(width: 8),
          _chip('resource', 'Resources', resources),
        ],
      ),
    );

    final Widget search = TextField(
      controller: _search,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Search donor, item or campaign',
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

// ==========================================================================
// SUMMARY HEADER
// ==========================================================================
class _SummaryHeader extends StatelessWidget {
  final AdminDonationsListMode mode;
  final int total;
  final double fundTotal;
  final int resourceCount;
  final bool wide;

  const _SummaryHeader({
    required this.mode,
    required this.total,
    required this.fundTotal,
    required this.resourceCount,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final bool pending = mode == AdminDonationsListMode.pending;

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
              pending ? Icons.hourglass_top_rounded : Icons.verified_rounded,
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
                      pending ? Icons.hourglass_top_rounded : Icons.verified_rounded,
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
                          pending ? 'Waiting for review' : 'Approved & completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: wide ? 19 : 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total donation${total == 1 ? '' : 's'}',
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
                  Expanded(
                    child: _HeaderStat(label: 'Total', value: '$total', wide: wide),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _HeaderStat(
                      label: pending ? 'Funds pending' : 'Funds',
                      value: DonationKit.money(fundTotal),
                      wide: wide,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderStat(
                      label: 'Resources',
                      value: '$resourceCount',
                      wide: wide,
                    ),
                  ),
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
                fontSize: wide ? 22 : 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// DONATION CARD
// ==========================================================================
class _DonationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _DonationCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFund = DonationKit.isFund(data);
    final DonationStatusStyle st = DonationKit.statusStyle(data['status']);

    final String key = DonationKit.purposeKey(data);
    final DonationPurposeStyle ps = DonationKit.purposeStyle(key);

    final Color accent = isFund ? ps.color : DonationKit.teal;
    final Color accentBg = isFund ? ps.bg : const Color(0xFFE0F7FA);
    final IconData icon = isFund ? ps.icon : Icons.inventory_2_rounded;

    final String qty = DonationKit.valueText(data['quantity']);
    final String item = DonationKit.valueText(data['itemName']).isNotEmpty
        ? DonationKit.valueText(data['itemName'])
        : (DonationKit.valueText(data['category']).isNotEmpty
        ? DonationKit.valueText(data['category'])
        : 'Resource donation');

    final String title = isFund
        ? DonationKit.money(DonationKit.amountOf(data))
        : (qty.isNotEmpty ? '$item  ×$qty' : item);

    String donor = DonationKit.valueText(data['donorName']);
    if (donor.isEmpty) donor = DonationKit.valueText(data['userEmail']);
    if (donor.isEmpty) donor = DonationKit.valueText(data['donorEmail']);
    if (donor.isEmpty) donor = 'Donor';

    final String target = DonationKit.targetName(data);
    final String category = DonationKit.valueText(data['category']);
    final String chipText = isFund
        ? ((target.isNotEmpty && key != 'general_fund') ? target : ps.single)
        : (category.isNotEmpty ? category : 'Resource');

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: DonationKit.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        donor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: accent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                chipText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: st.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        st.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: st.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DonationKit.shortDate(data['createdAt']),
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// EMPTY STATE
// ==========================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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