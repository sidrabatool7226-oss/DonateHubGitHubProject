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
  final double size;
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
              color: Colors.white, size: size * 0.44),
        ),
      ),
    );
  }
}