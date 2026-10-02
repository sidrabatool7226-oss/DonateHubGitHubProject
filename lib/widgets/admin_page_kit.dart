// ============================================================
// FILE: lib/widgets/admin_page_kit.dart   (NEW)
// Shared by the admin tabs (mobile + web):
//  - AdminPageScroll : whole-page vertical scroll (header + filters + list
//                      scroll together) with its own controller and a
//                      visible scrollbar on web.
//  - AdminBackButton : round arrow used in tab headers, takes the admin
//                      back to the Home tab (works on app and web because
//                      both use AdminNavController).
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_nav_controller.dart';

class AdminPageScroll extends StatefulWidget {
  final Widget child;
  const AdminPageScroll({super.key, required this.child});

  @override
  State<AdminPageScroll> createState() => _AdminPageScrollState();
}

class _AdminPageScrollState extends State<AdminPageScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: kIsWeb,
      child: SingleChildScrollView(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}

class AdminBackButton extends StatelessWidget {
  final double size; // NEW — web headers use a larger one; every existing caller keeps 36
  const AdminBackButton({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Get.find<AdminNavController>().changeTab(0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: size >= 40 ? 20 : 16),
        ),
      ),
    );
  }
}