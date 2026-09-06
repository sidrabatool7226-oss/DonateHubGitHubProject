import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_nav_controller.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_campaigns_events_tab.dart';
import 'tabs/admin_inventory_tab.dart';
import 'tabs/admin_utilization_tab.dart';
import 'tabs/admin_user_management_tab.dart';
import 'tabs/admin_reports_tab.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color _green = Color(0xFF1B6B3A);

  final List<Widget> _tabs = const [
    AdminHomeTab(),
    AdminCampaignsEventsTab(),
    AdminInventoryTab(),
    AdminUtilizationTab(),
    AdminUserManagementTab(),
    AdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(AdminNavController());

    return WillPopScope(
      onWillPop: () async {
        // Agar kisi tab pe hain but Home nahi hai, pehle Home pe le jao
        if (navController.currentIndex.value != 0) {
          navController.changeTab(0);
          return false;
        }
        // Home pe hain — exit confirm karo
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit DonateHub'),
            content: const Text('Are you sure you want to exit DonateHub?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
            false;
      },
      child: Obx(() => Scaffold(
        body: IndexedStack(index: navController.currentIndex.value, children: _tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: BottomNavigationBar(
            currentIndex: navController.currentIndex.value,
            onTap: navController.changeTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _green,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: 'Campaigns'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
              BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_rounded), label: 'Utilization'),
              BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Users'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
            ],
          ),
        ),
      )),
    );
  }
}