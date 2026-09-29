import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW — for the current admin's uid
import '../../../controllers/admin_nav_controller.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/web_dashboard_shell.dart';
import '../tabs/admin_home_tab.dart';
import '../tabs/admin_campaigns_events_tab.dart';
import '../tabs/admin_inventory_tab.dart';
import '../tabs/admin_utilization_tab.dart';
import '../tabs/admin_user_management_tab.dart';
import '../tabs/admin_reports_tab.dart';
import 'admin_home_tab_web.dart';
import '../screens/admin_profile_screen.dart';
import '../screens/shared/notifications_screen.dart'; // NEW — same screen the mobile bell already uses
class AdminWebDashboard extends StatelessWidget {
  const AdminWebDashboard({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _greenDark = Color(0xFF0E3D22);

  static const List<WebNavItem> _items = [
    WebNavItem(Icons.dashboard_rounded, 'Home'),
    WebNavItem(Icons.campaign_rounded, 'Campaigns'),
    WebNavItem(Icons.inventory_2_rounded, 'Inventory'),
    WebNavItem(Icons.volunteer_activism_rounded, 'Utilization'),
    WebNavItem(Icons.manage_accounts_rounded, 'Users'),
    WebNavItem(Icons.bar_chart_rounded, 'Reports'),
  ];

  static const List<Widget> _pages = [
    AdminHomeTabWeb(),
    AdminCampaignsEventsTab(),
    AdminInventoryTab(),
    AdminUtilizationTab(),
    AdminUserManagementTab(),
    AdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(AdminNavController());

    return Obx(() => WebDashboardShell(
      brandTitle: 'DonateHub',
      brandSubtitle: 'Admin Panel',
      accent: _green,
      accentDark: _greenDark,
      items: _items,
      selectedIndex: navController.currentIndex.value,
      onSelect: navController.changeTab,
      pages: _pages,
      onProfileTap: () => Get.to(() => const AdminProfileScreen()),
      onNotificationTap: () => Get.to(() => const NotificationsScreen(accentColor: _green)), // NEW — fixes the missing/unlinked bell on web
      currentUserId: FirebaseAuth.instance.currentUser?.uid, // NEW
      onLogout: () async {
        await AuthService().signOut();
        Get.offAllNamed('/login');
      },
    ));
  }
}