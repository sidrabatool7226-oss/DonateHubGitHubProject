import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class AppearanceSelectorSheet extends StatelessWidget {
  final Color accentColor;
  const AppearanceSelectorSheet({super.key, this.accentColor = const Color(0xFF1B6B3A)});

  static void show(BuildContext context, {Color accentColor = const Color(0xFF1B6B3A)}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AppearanceSelectorSheet(accentColor: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Choose how DonateHub looks on this device',
              style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.6))),
          const SizedBox(height: 16),
          Obx(() => Column(
            children: [
              _option(context, icon: Icons.light_mode_rounded, label: 'Light',
                  mode: AppThemeMode.light, current: controller.themeMode.value, controller: controller),
              const SizedBox(height: 10),
              _option(context, icon: Icons.dark_mode_rounded, label: 'Dark',
                  mode: AppThemeMode.dark, current: controller.themeMode.value, controller: controller),
              const SizedBox(height: 10),
              _option(context, icon: Icons.settings_suggest_rounded, label: 'System Default',
                  mode: AppThemeMode.system, current: controller.themeMode.value, controller: controller),
            ],
          )),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, {
    required IconData icon,
    required String label,
    required AppThemeMode mode,
    required AppThemeMode current,
    required ThemeController controller,
  }) {
    final isSelected = current == mode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: () => controller.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? accentColor : Colors.grey.withOpacity(0.25), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? accentColor : textColor?.withOpacity(0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : textColor,
              )),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}