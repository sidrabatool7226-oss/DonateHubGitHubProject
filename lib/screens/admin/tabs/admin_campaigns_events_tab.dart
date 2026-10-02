import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/campaign_controller.dart';
import '../../../controllers/event_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/event_participants_screen.dart';
import '../../../widgets/picked_image_preview.dart';
import '../screens/admin_general_fund_screen.dart'; // NEW
import '../../../controllers/admin_nav_controller.dart';
import '../../../widgets/admin_page_kit.dart';
class AdminCampaignsEventsTab extends StatefulWidget {
  const AdminCampaignsEventsTab({super.key});

  @override
  State<AdminCampaignsEventsTab> createState() =>
      _AdminCampaignsEventsTabState();
}

// CHANGED — Events is no longer hidden. A segmented toggle now switches
// this whole tab between "Fundraising" (Campaigns/Projects/Sponsorships)
// and "Events" (volunteer coordination) — two genuinely different admin
// jobs that don't belong mixed into one undifferentiated list, but also
// don't need two separate bottom-nav tabs.
class _AdminCampaignsEventsTabState
    extends State<AdminCampaignsEventsTab> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _blue = Color(0xFF1565C0);

  int _selectedTab = 0; // 0 = Fundraising, 1 = Events
  Worker? _navWorker;
  @override
  void initState() {
    super.initState();
    // Sync with AdminNavController so "Add Event" / stat-card taps
    // from Home actually switch this tab, not just the controller's value.
    final nav = Get.find<AdminNavController>();
    _selectedTab = nav.campaignEventsTabIndex.value;
    _navWorker = ever(nav.campaignEventsRequestId, (_) {
      if (mounted) {
        setState(() => _selectedTab = nav.campaignEventsTabIndex.value);
      }
    });
  }

  @override
  void dispose() {
    _navWorker?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final campaignController = Get.put(CampaignController());
    final eventController = Get.put(EventController());
    final bool isEvents = _selectedTab == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: AdminPageScroll(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEvents
                        ? [_blue, const Color(0xFF1E88E5)]
                        : const [Color(0xFF1B6B3A), Color(0xFF2D8A52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AdminBackButton(), // NEW — back to Home tab
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEvents ? 'Events' : 'Campaigns & Projects',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isEvents
                                      ? 'Coordinate volunteer turnout'
                                      : 'Manage campaigns, projects & sponsorships',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // General Fund quick access — only relevant to
                          // Fundraising, hidden on the Events segment.
                          if (!isEvents)
                            GestureDetector(
                              onTap: () => Get.to(
                                    () => const AdminGeneralFundScreen(),
                                transition: Transition.rightToLeft,
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                ),
                                child: const Icon(Icons.savings_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          // Add button
                          Builder(builder: (ctx) {
                            return GestureDetector(
                              onTap: () => isEvents
                                  ? _showAddEventSheet(ctx, eventController)
                                  : _showAddCampaignSheet(ctx, campaignController),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withOpacity(0.2),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.4)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: Colors.white,
                                        size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add New',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // NEW — Fundraising / Events segmented toggle
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentButton(
                                label: 'Fundraising',
                                icon: Icons.campaign_rounded,
                                selected: !isEvents,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                            ),
                            Expanded(
                              child: _SegmentButton(
                                label: 'Events',
                                icon: Icons.event_rounded,
                                selected: isEvents,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── List ─────────────────────────────────────────────────
              // CHANGED — no Expanded; the whole page scrolls (AdminPageScroll).
              isEvents
                  ? _EventsList(controller: eventController)
                  : _CampaignsList(controller: campaignController),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCampaignSheet(
      BuildContext context, CampaignController controller) {
    controller.clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _AddCampaignSheet(controller: controller),
    );
  }

  void _showAddEventSheet(
      BuildContext context, EventController controller) {
    controller.clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddEventSheet(controller: controller),
    );
  }
}

// ==========================================================================
// SEGMENT BUTTON (NEW) — Fundraising / Events toggle
// ==========================================================================
class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? const Color(0xFF1B6B3A) : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF1B6B3A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// CAMPAIGNS LIST — Improved UI
// ==========================================================================
class _CampaignsList extends StatelessWidget {
  final CampaignController controller;
  const _CampaignsList({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: controller.campaignsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: _green),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: _EmptyCampaigns(),
          );
        }

        // CHANGED — list no longer scrolls on its own; the whole page does.
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _CampaignCard(
              docId: doc.id,
              data: data,
              controller: controller,
            );
          },
        );
      },
    );
  }
}

// ==========================================================================
// IMPROVED CAMPAIGN CARD
// ==========================================================================
class _CampaignCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final CampaignController controller;

  const _CampaignCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description = data['description'] ?? '';
    final double goal =
    (data['goalAmount'] ?? 0).toDouble();
    final double collected =
    (data['collectedAmount'] ?? 0).toDouble();
    final String imageUrl = data['image'] ?? '';
    final String endDate = data['endDate'] ?? '';
    final bool isActive = data['isActive'] ?? true;
    final List needs = data['needs'] ?? [];
    final double progress =
    goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();
    // NEW — 'campaign' | 'project' | 'sponsorship'; older docs without
    // this field are treated as plain campaigns.
    final String category =
    (data['category'] ?? 'campaign').toString();
    final String categoryLabel = _categoryLabel(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner Image ─────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholder(),
                )
                    : _placeholder(),
              ),

              // Gradient overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category badge — NEW (top-left; Active/Inactive keeps top-right)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                    isActive ? _green : Colors.grey[600],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress % overlay
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent% Funded',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[100],
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                        _green),
                  ),
                ),
                const SizedBox(height: 8),

                // Amount row
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raised',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Rs. ${collected.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Goal',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Rs. ${goal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // End date
                if (endDate.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Ends: $endDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],

                // Needs chips
                if (needs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: needs.map((need) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 12,
                                color: Colors.orange[700]),
                            const SizedBox(width: 3),
                            Text(
                              need,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: isActive
                            ? 'Deactivate'
                            : 'Activate',
                        icon: isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: _green,
                        onTap: () => controller.toggleActive(
                            docId, isActive),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: () => _confirmDelete(
                            context, docId, title, controller),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'project':
        return 'Project';
      case 'sponsorship':
        return 'Sponsorship';
      case 'campaign':
      default:
        return 'Campaign';
    }
  }

  Widget _placeholder() {
    return Container(
      height: 150,
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.campaign_outlined,
            size: 48, color: Color(0xFF1B6B3A)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId,
      String title, CampaignController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Campaign'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteCampaign(docId);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ACTION BUTTON
// ==========================================================================
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border:
          Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// EVENTS LIST — Improved UI
// ==========================================================================
class _EventsList extends StatelessWidget {
  final EventController controller;
  const _EventsList({required this.controller});

  static const Color _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: controller.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: _blue),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: _EmptyEvents(),
          );
        }

        // CHANGED — list no longer scrolls on its own; the whole page does.
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _EventCard(
              docId: doc.id,
              data: data,
              controller: controller,
            );
          },
        );
      },
    );
  }
}

// ==========================================================================
// IMPROVED EVENT CARD
// ==========================================================================
class _EventCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final EventController controller;

  const _EventCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _blue = Color(0xFF1565C0);
  static const Color _green = Color(0xFF1B6B3A); // NEW — for "fully staffed" state

  String _monthName(String month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    int m = int.tryParse(month) ?? 0;
    return m > 0 && m < 13 ? months[m] : '--';
  }

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? '';
    final String description = data['description'] ?? '';
    final String location = data['location'] ?? '';
    final String startDate = data['startDateStr'] ?? '';
    final String endDate = data['endDateStr'] ?? '';
    final String imageUrl = data['image'] ?? '';
    final bool isActive = data['isActive'] ?? true;
    final int volunteersNeeded = (data['volunteersNeeded'] ?? 0) is int
        ? data['volunteersNeeded'] ?? 0
        : int.tryParse(data['volunteersNeeded'].toString()) ?? 0; // NEW

    final List<String> dateParts =
    startDate.isNotEmpty ? startDate.split('/') : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Blue Header ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_blue, _blue.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Text(
                        dateParts.isNotEmpty
                            ? dateParts[0]
                            : '--',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _blue,
                        ),
                      ),
                      Text(
                        dateParts.length > 1
                            ? _monthName(dateParts[1])
                            : '--',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.white70),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green[400]
                        : Colors.grey[400],
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Banner image
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Date range chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: _blue),
                      const SizedBox(width: 6),
                      Text(
                        startDate == endDate
                            ? startDate
                            : '$startDate → $endDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // CHANGED — now shows progress against volunteersNeeded
                // when the admin specified a target, not just a raw count.
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Get.to(
                          () => EventParticipantsScreen(
                        eventId: docId,
                        eventTitle: title,
                        volunteersNeeded: volunteersNeeded,
                      ),
                      transition:
                      Transition.rightToLeft,
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .doc(docId)
                          .collection('participants')
                          .snapshots(),
                      builder: (context, snap) {
                        final count =
                            snap.data?.docs.length ?? 0;
                        final bool hasTarget = volunteersNeeded > 0;
                        final bool isFull = hasTarget && count >= volunteersNeeded;
                        final double progress = hasTarget
                            ? (count / volunteersNeeded).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFull
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFE3F2FD),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      isFull
                                          ? Icons.check_circle_rounded
                                          : Icons.people_outline_rounded,
                                      size: 15,
                                      color: isFull ? _green : const Color(0xFF1565C0)),
                                  const SizedBox(width: 6),
                                  Text(
                                    hasTarget
                                        ? '$count of $volunteersNeeded Volunteers Joined'
                                        : '$count Volunteers Joined',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: isFull ? _green : const Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (hasTarget) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.white,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        isFull ? _green : const Color(0xFF1565C0)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isFull
                                      ? 'Fully staffed'
                                      : '${volunteersNeeded - count} more needed',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isFull ? _green : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: isActive
                            ? 'Deactivate'
                            : 'Activate',
                        icon: isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: _blue,
                        onTap: () => controller.toggleActive(
                            docId, isActive),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onTap: () => _confirmDelete(
                            context,
                            docId,
                            title,
                            controller),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId,
      String title, EventController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteEvent(docId);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ADD CAMPAIGN SHEET
// ==========================================================================
class _AddCampaignSheet extends StatelessWidget {
  final CampaignController controller;
  const _AddCampaignSheet({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            const SizedBox(height: 16),
            const Text(
              'New Entry',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // NEW — what kind of fundraising entry this is
            const Text(
              'Type',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                {'value': 'campaign', 'label': 'Campaign'},
                {'value': 'project', 'label': 'Project'},
                {'value': 'sponsorship', 'label': 'Sponsor a Child'},
              ].map((opt) {
                final bool sel =
                    controller.selectedCategory.value == opt['value'];
                return GestureDetector(
                  onTap: () =>
                      controller.selectCategory(opt['value']!), // CHANGED
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _green : const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? _green : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: sel ? Colors.white : Colors.grey[700],
                        fontWeight:
                        sel ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 16),

            // Photo / Banner Image
            // CHANGED — branches by type. Sponsorship gets a circular
            // "child photo" picker (matches how a sponsorship profile
            // photo actually looks); Campaign/Project keep the exact
            // rectangular banner picker they always had.
            Obx(() {
              final bool isSponsorship =
                  controller.selectedCategory.value == 'sponsorship';

              if (isSponsorship) {
                return Center(child: _ChildPhotoPicker(controller: controller));
              }

              return GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFE8F5E9),
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                        color:
                        _green.withOpacity(0.3)),
                  ),
                  child: controller
                      .selectedImage.value !=
                      null
                      ? ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                        14),
                    child: buildPickedImagePreview(
                      controller.selectedImage.value!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                          Icons
                              .add_photo_alternate_outlined,
                          size: 32,
                          color: _green),
                      SizedBox(height: 6),
                      Text(
                          'Add Banner Image',
                          style: TextStyle(
                              color: _green,
                              fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Fields — CHANGED — a genuinely separate field set for
            // Sponsorship (Name / Age / About / fixed monthly amount)
            // instead of relabeled Campaign fields. Campaign/Project
            // keep the exact same fields, in the exact same order,
            // as before.
            Obx(() {
              final bool isSponsorship =
                  controller.selectedCategory.value == 'sponsorship';

              if (isSponsorship) {
                return _SponsorshipFields(controller: controller);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormField2(
                      controller: controller.titleController,
                      label: controller.selectedCategory.value == 'project'
                          ? 'Project Title *'
                          : 'Campaign Title *',
                      hint: 'e.g. Winter Clothes Drive'),
                  const SizedBox(height: 10),
                  _FormField2(
                      controller: controller.descController,
                      label: 'Description *',
                      hint: 'What is this campaign about?',
                      maxLines: 2),
                  const SizedBox(height: 10),
                  _FormField2(
                      controller: controller.goalController,
                      label: 'Goal Amount (Rs.) *',
                      hint: 'e.g. 50000',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _pickDate(context, controller),
                    child: AbsorbPointer(
                      child: _FormField2(
                        controller: controller.endDateController,
                        label: 'End Date',
                        hint: 'Select end date',
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Urgent Needs',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.allNeeds.map((need) {
                      final sel = controller.selectedNeeds.contains(need);
                      return GestureDetector(
                        onTap: () => controller.toggleNeed(need),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? _green : const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? _green : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            need,
                            style: TextStyle(
                              fontSize: 12,
                              color: sel ? Colors.white : Colors.grey[700],
                              fontWeight:
                              sel ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                ],
              );
            }),
            const SizedBox(height: 20),

            Obx(() => _SubmitBtn(
              label: controller.selectedCategory.value == 'sponsorship'
                  ? 'Add Sponsorship'
                  : controller.selectedCategory.value == 'project'
                  ? 'Add Project'
                  : 'Add Campaign',
              color: _green,
              isLoading:
              controller.isLoading.value,
              onTap: () async {
                bool ok =
                await controller.addCampaign();
                if (ok && context.mounted) {
                  Navigator.pop(context);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
      BuildContext context,
      CampaignController c) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(
              primary: Color(0xFF1B6B3A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      c.endDateController.text =
      '${picked.day}/${picked.month}/${picked.year}';
    }
  }
}

// ==========================================================================
// ADD EVENT SHEET
// ==========================================================================
class _AddEventSheet extends StatelessWidget {
  final EventController controller;
  const _AddEventSheet({required this.controller});

  static const Color _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            const SizedBox(height: 16),
            const Text(
              'New Event',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Image
            Obx(() => GestureDetector(
              onTap: controller.pickImage,
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE3F2FD),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                      color:
                      _blue.withOpacity(0.3)),
                ),
                child: controller
                    .selectedImage.value !=
                    null
                    ? ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                      14),
                  child: buildPickedImagePreview(
                    controller.selectedImage.value!,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                        Icons
                            .add_photo_alternate_outlined,
                        size: 30,
                        color: _blue),
                    SizedBox(height: 6),
                    Text(
                        'Add Event Banner',
                        style: TextStyle(
                            color: _blue,
                            fontSize: 12)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 12),

            _FormField2(
                controller:
                controller.titleController,
                label: 'Event Title *',
                hint:
                'e.g. Eid Celebration at LSOH'),
            const SizedBox(height: 10),
            _FormField2(
                controller:
                controller.descController,
                label: 'Description *',
                hint: 'What will happen?',
                maxLines: 2),
            const SizedBox(height: 10),
            _FormField2(
              controller:
              controller.locationController,
              label: 'Location *',
              hint: 'e.g. LSOH, Wah Cantt',
              suffixIcon:
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            // NEW — lets Admin flag how many volunteers this event
            // needs, so volunteers see "X of Y joined" and Admin can
            // tell at a glance whether an event is fully staffed.
            _FormField2(
              controller: controller.volunteersNeededController,
              label: 'Volunteers Needed (Optional)',
              hint: 'e.g. 10',
              keyboardType: TextInputType.number,
              suffixIcon: Icons.people_outline_rounded,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.pickStartDate(
                            context),
                    child: AbsorbPointer(
                      child: _FormField2(
                        controller: controller
                            .startDateController,
                        label: 'Start Date *',
                        hint: 'DD/MM/YYYY',
                        suffixIcon: Icons
                            .calendar_today_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.pickEndDate(
                            context),
                    child: AbsorbPointer(
                      child: _FormField2(
                        controller: controller
                            .endDateController,
                        label: 'End Date *',
                        hint: 'DD/MM/YYYY',
                        suffixIcon: Icons
                            .calendar_today_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Obx(() => _SubmitBtn(
              label: 'Add Event',
              color: _blue,
              isLoading:
              controller.isLoading.value,
              onTap: () async {
                bool ok =
                await controller.addEvent();
                if (ok && context.mounted) {
                  Navigator.pop(context);
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// EMPTY STATES
// ==========================================================================
class _EmptyCampaigns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No campaigns yet',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Add New to create one',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(Icons.event_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No events yet',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Add New to create one',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CHILD PHOTO PICKER (NEW) — circular picker for a Sponsor-a-Child entry.
// A portrait child photo (matching the printed sponsorship flyers) reads
// far better as a circular avatar than the rectangular campaign banner,
// so this is a distinct widget rather than reusing the banner picker.
// ==========================================================================
class _ChildPhotoPicker extends StatelessWidget {
  final CampaignController controller;
  const _ChildPhotoPicker({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final picked = controller.selectedImage.value;
      return GestureDetector(
        onTap: controller.pickImage,
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9),
                border: Border.all(color: _green.withOpacity(0.35), width: 2),
              ),
              child: picked != null
                  ? ClipOval(
                child: buildPickedImagePreview(picked, fit: BoxFit.cover),
              )
                  : const Icon(Icons.child_care_rounded, size: 42, color: _green),
            ),
            const SizedBox(height: 8),
            Text(
              picked != null ? 'Change Photo' : "Add Child's Photo *",
              style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }
}

// ==========================================================================
// SPONSORSHIP FIELDS (NEW) — genuinely separate form for a Sponsor-a-Child
// entry: Name / Age / About the Child, plus a fixed (non-editable) monthly
// amount summary. Deliberately has NO end date and NO "needs" checklist —
// a child's sponsorship is an open-ended program, not a time-bound drive,
// and the 6 support categories are fixed program policy, not a per-entry
// checklist (see lib/models/sponsorship_categories.dart).
// ==========================================================================
class _SponsorshipFields extends StatelessWidget {
  final CampaignController controller;
  const _SponsorshipFields({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormField2(
          controller: controller.titleController,
          label: "Child's Name *",
          hint: 'e.g. Sufyan',
        ),
        const SizedBox(height: 10),
        _FormField2(
          controller: controller.ageController,
          label: 'Age *',
          hint: 'e.g. 4 years',
        ),
        const SizedBox(height: 10),
        _FormField2(
          controller: controller.descController,
          label: 'About the Child *',
          hint: 'e.g. Sharp in studies, has a bright future ahead.',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, color: _green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rs. 30,000 / month',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _green),
                    ),
                    Text(
                      'Full Sponsorship — fixed across all 6 support categories. '
                          'Donors can also sponsor individual categories.',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600], height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ==========================================================================
// SHARED SMALL WIDGETS
// ==========================================================================
class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius:
          BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _FormField2 extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final IconData? suffixIcon;

  const _FormField2({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 13),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon,
                size: 16,
                color: Colors.grey[400])
                : null,
            filled: true,
            fillColor:
            const Color(0xFFF4F6F8),
            contentPadding:
            const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Colors.grey[300]!),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Colors.grey[300]!),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1B6B3A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _SubmitBtn({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w600),
        ),
      ),
    );
  }
}