import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  const ManagerBackButton({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onBack ?? () => Get.back(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}