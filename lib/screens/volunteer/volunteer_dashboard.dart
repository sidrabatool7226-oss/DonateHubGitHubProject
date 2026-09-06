import 'package:flutter/material.dart';
import 'tabs/volunteer_home_tab.dart';
import 'tabs/volunteer_tasks_tab.dart';
import 'tabs/volunteer_rewards_tab.dart';
import 'tabs/volunteer_events_tab.dart';
import 'tabs/volunteer_profile_tab.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _currentIndex = 0;

  static const Color _green = Color(0xFF1B6B3A);

  final List<Widget> _tabs = const [
    VolunteerHomeTab(),
    VolunteerTasksTab(),
    VolunteerRewardsTab(),
    VolunteerEventsTab(),
    VolunteerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit DonateHub'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
            false;
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _green,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'My Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Rewards'),
              BottomNavigationBarItem(icon: Icon(Icons.event_rounded), label: 'Events'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}