import 'package:flutter/material.dart';
import 'tabs/manager_home_tab.dart';
import 'tabs/manager_volunteers_tab.dart';
import 'tabs/manager_donations_tab.dart';
import 'tabs/manager_tasks_tab.dart';
import 'tabs/manager_profile_tab.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;

  static const Color _teal = Color(0xFF0F6E4F);

  final List<Widget> _tabs = const [
    ManagerHomeTab(),
    ManagerVolunteersTab(),
    ManagerDonationsTab(),
    ManagerTasksTab(),
    ManagerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _teal,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Volunteers'),
              BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_rounded), label: 'Donations'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}