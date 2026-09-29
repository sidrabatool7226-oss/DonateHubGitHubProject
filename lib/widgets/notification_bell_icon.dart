// ============================================================
// FILE: lib/widgets/notification_bell_icon.dart (NEW)
//
// PURPOSE
// Reusable notification bell for a dashboard Home header — shows
// a live, numbered, capped ("9+") unread-count badge (same style
// already used on Admin's Home tab) and opens the existing
// NotificationsScreen on tap. Shared by Donor, Volunteer, and
// Manager Home tabs so the badge logic isn't duplicated three
// times; Admin's Home tab already has its own working copy of
// this and is left untouched.
//
// Sizing/colors are parameterized because each Home tab has a
// different header style: Volunteer/Manager use a colored
// gradient container (translucent white icon circle), while
// Donor's Home uses a plain white AppBar (light-green icon
// circle instead) — same widget, different look via params.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/admin/screens/shared/notifications_screen.dart';

class NotificationBellIcon extends StatelessWidget {
  final Color accentColor; // badge border + passed to NotificationsScreen's AppBar color
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color borderColor;
  final double size;

  const NotificationBellIcon({
    super.key,
    required this.accentColor,
    this.iconBackgroundColor = const Color(0x2EFFFFFF),
    this.iconColor = Colors.white,
    this.borderColor = const Color(0x66FFFFFF),
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: () => Get.to(
            () => NotificationsScreen(accentColor: accentColor),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_outlined, color: iconColor, size: size * 0.48),
            Positioned(
              top: size * 0.08,
              right: size * 0.1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUserId', isEqualTo: uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snap) {
                  final int count = snap.data?.docs.length ?? 0;
                  if (count == 0) return const SizedBox();

                  final String label = count > 9 ? '9+' : count.toString();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
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