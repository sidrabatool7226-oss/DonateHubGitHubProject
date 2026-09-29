import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/web_dashboard_shell.dart';
import '../tabs/manager_home_tab.dart';
import '../tabs/manager_volunteers_tab.dart';
import '../tabs/manager_donations_tab.dart';
import '../tabs/manager_tasks_tab.dart';
import '../tabs/manager_profile_tab.dart';
import 'manager_home_tab_web.dart';
import '../screens/manager_profile_screen.dart';
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

  static const List<Widget> _pages = [
    ManagerHomeTabWeb(),
    ManagerVolunteersTab(),
    ManagerDonationsTab(),
    ManagerTasksTab(),
    ManagerProfileTab(),
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
      onLogout: () async {
        await AuthService().signOut();
        Get.offAllNamed('/login');
      },
    );
  }
}