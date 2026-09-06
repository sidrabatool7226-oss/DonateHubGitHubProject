import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController {
  static const String _storageKey = 'app_theme_mode';
  final GetStorage _box = GetStorage();

  var themeMode = AppThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    final saved = _box.read<String>(_storageKey);
    if (saved != null) {
      themeMode.value = AppThemeMode.values.firstWhere(
            (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    themeMode.value = mode;
    await _box.write(_storageKey, mode.name);
  }
}