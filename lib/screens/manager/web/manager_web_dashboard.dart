import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FIXED (Bug 8) — current manager's uid for the unread badge
import '../../../services/auth_service.dart';
import '../../../controllers/manager_tasks_controller.dart';
import '../../../widgets/web_dashboard_shell.dart';
import '../tabs/manager_home_tab.dart';
import '../tabs/manager_volunteers_tab.dart';
import '../tabs/manager_donations_tab.dart';
import '../tabs/manager_tasks_tab.dart';
import '../tabs/manager_profile_tab.dart';
import 'manager_home_tab_web.dart';
import '../screens/manager_profile_screen.dart';
import '../../admin/screens/shared/notifications_screen.dart'; // FIXED (Bug 8) — same screen the mobile bell and Admin web already use
class ManagerWebDashboard extends StatefulWidget {
  const ManagerWebDashboard({super.key});

  @override
  State<ManagerWebDashboard> createState() => _ManagerWebDashboardState();
}

class _ManagerWebDashboardState extends State<ManagerWebDashboard> {
  int _currentIndex = 0;

  static const Color _teal = Color(0xFF0F6E4F);
  static const Color _tealDark = Color(0xFF08432F);

  static const List<WebNavItem> _items = [
    WebNavItem(Icons.dashboard_rounded, 'Home'),
    WebNavItem(Icons.groups_rounded, 'Volunteers'),
    WebNavItem(Icons.volunteer_activism_rounded, 'Donations'),
    WebNavItem(Icons.assignment_rounded, 'Tasks'),
    WebNavItem(Icons.person_rounded, 'Profile'),
  ];

  late final List<Widget> _pages = [
    ManagerHomeTabWeb(
      onGoToActiveTasks: () {
        // open Tasks page on its "Active" section
        Get.put(ManagerTasksController()).selectedTab.value = 1;
        setState(() => _currentIndex = 3);
      },
      onGoToCompletedTasks: () {
        // NEW — open Tasks page on its "Completed" section
        Get.put(ManagerTasksController()).selectedTab.value = 3;
        setState(() => _currentIndex = 3);
      },
    ),
    const ManagerVolunteersTab(),
    const ManagerDonationsTab(),
    const ManagerTasksTab(),
    ManagerProfileTab(onBack: () => setState(() => _currentIndex = 0)),
  ];

  @override
  Widget build(BuildContext context) {
    return WebDashboardShell(
      brandTitle: 'DonateHub',
      brandSubtitle: 'Manager Panel',
      accent: _teal,
      accentDark: _tealDark,
      items: _items,
      selectedIndex: _currentIndex,
      onSelect: (i) => setState(() => _currentIndex = i),
      pages: _pages,
      onProfileTap: () => Get.to(() => const ManagerProfileScreen()),
      onNotificationTap: () => Get.to(() => const NotificationsScreen(accentColor: _teal)), // FIXED (Bug 8) — manager web had no bell at all
      currentUserId: FirebaseAuth.instance.currentUser?.uid, // FIXED (Bug 8)
      onLogout: () async {
        await AuthService().signOut();
        Get.offAllNamed('/login');
      },
    );
  }
}