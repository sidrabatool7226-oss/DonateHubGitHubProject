// ============================================================
// FILE: lib/widgets/web_dashboard_shell.dart
// CHANGE: content area now wrapped in SingleChildScrollView so
// any tab taller than the viewport scrolls instead of overflowing.
// Sidebar/topbar logic UNCHANGED.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW — for the notification badge count

class WebNavItem {
  final IconData icon;
  final String label;
  const WebNavItem(this.icon, this.label);
}

/// NEW — put this on a tab widget (`class MyTab extends StatelessWidget implements WebFullBleedPage`)
/// when the tab wants the WHOLE content area on web: no 28px side padding and no 1400px width cap.
/// The tab then lays itself out, and its own scrollbar sits on the far edge of the window.
/// Every other page is untouched.
abstract class WebFullBleedPage {}

class WebDashboardShell extends StatelessWidget {
  final String brandTitle;
  final String brandSubtitle;
  final Color accent;
  final Color accentDark;
  final List<WebNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Widget> pages;
  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap; // NEW — optional, so existing callers (Manager) are unaffected
  final String? currentUserId; // NEW — optional, only needed to show the unread badge count

  const WebDashboardShell({
    super.key,
    required this.brandTitle,
    required this.brandSubtitle,
    required this.accent,
    required this.accentDark,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.pages,
    required this.onLogout,
    this.onProfileTap,
    this.onNotificationTap, // NEW
    this.currentUserId, // NEW
  });

  @override
  Widget build(BuildContext context) {
    // NEW — does the page on screen want the full content area? (see WebFullBleedPage)
    final bool fullBleed = selectedIndex >= 0 &&
        selectedIndex < pages.length &&
        pages[selectedIndex] is WebFullBleedPage;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 980;
          return Row(
            children: [
              _Sidebar(
                compact: compact,
                items: items,
                selectedIndex: selectedIndex,
                onSelect: onSelect,
                accent: accent,
                accentDark: accentDark,
                brandTitle: brandTitle,
                brandSubtitle: brandSubtitle,
                onLogout: onLogout,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      title: items[selectedIndex].label,
                      accent: accent,
                      onProfileTap: onProfileTap,
                      onNotificationTap: onNotificationTap, // NEW
                      currentUserId: currentUserId, // NEW
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: fullBleed ? double.infinity : 1400), // CHANGED — only the width value depends on the page
                          child: Padding(
                            padding: fullBleed ? EdgeInsets.zero : const EdgeInsets.fromLTRB(28, 22, 28, 22), // CHANGED
                            child: IndexedStack(index: selectedIndex, children: pages),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── SIDEBAR ─────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final bool compact;
  final List<WebNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color accent;
  final Color accentDark;
  final String brandTitle;
  final String brandSubtitle;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.compact,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.accent,
    required this.accentDark,
    required this.brandTitle,
    required this.brandSubtitle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 84 : 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, accentDark],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(3, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 26),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.4),
              ),
              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              Text(brandTitle, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(brandSubtitle, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(height: 28),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (_, i) => _NavTile(
                  item: items[i],
                  selected: i == selectedIndex,
                  compact: compact,
                  onTap: () => onSelect(i),
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
            _NavTile(
              item: WebNavItem(Icons.logout_rounded, 'Logout'),
              selected: false,
              compact: compact,
              onTap: onLogout,
              isDanger: true,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final WebNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final bool isDanger;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? Colors.white.withOpacity(0.18)
        : _hovering
        ? Colors.white.withOpacity(0.08)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: widget.selected
                  ? Border.all(color: Colors.white.withOpacity(0.35), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.item.icon,
                  size: 21,
                  color: widget.isDanger ? const Color(0xFFFFC9C0) : Colors.white,
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        color: widget.isDanger ? const Color(0xFFFFC9C0) : Colors.white,
                        fontSize: 13.5,
                        fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── TOP BAR ──────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback? onProfileTap; // NEW
  final VoidCallback? onNotificationTap; // NEW
  final String? currentUserId; // NEW
  const _TopBar({
    required this.title,
    required this.accent,
    this.onProfileTap,
    this.onNotificationTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF14251E))),
          const Spacer(),
          // NEW — bell icon, only rendered when a handler was actually
          // given (Manager's web dashboard doesn't pass one, so nothing
          // changes there).
          if (onNotificationTap != null) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_outlined, color: accent, size: 20),
                      if (currentUserId != null && currentUserId!.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('notifications')
                                .where('toUserId', isEqualTo: currentUserId)
                                .where('isRead', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.data?.docs.length ?? 0;
                              if (count == 0) return const SizedBox();
                              final label = count > 9 ? '9+' : '$count';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1.3)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: accent, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}