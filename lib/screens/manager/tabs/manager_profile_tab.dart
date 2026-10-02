import 'package:flutter/material.dart';
import '../screens/manager_profile_screen.dart';

class ManagerProfileTab extends StatelessWidget {
  final VoidCallback? onBack; // NEW
  const ManagerProfileTab({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ManagerProfileScreen(onBack: onBack);
  }
}