import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'donor_home_tab.dart';
import 'donor_campaigns_tab.dart';
import 'donor_donations_tab.dart';
import 'donor_rewards_tab.dart';
import 'donor_impact_tab.dart';
import 'donor_profile_tab.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  int _currentIndex = 0;

  static const Color _green = Color(0xFF1B6B3A);

  final List<Widget> _tabs = const [
    DonorHomeTab(),
    DonorCampaignsTab(),
    DonorDonationsTab(),
    DonorRewardsTab(),
    DonorImpactTab(),
    DonorProfileTab(),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Exit DonateHub'),
            content: const Text('Are you sure you want to exit DonateHub?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
            false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _green,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: 'Campaigns'),
              BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_rounded), label: 'Donations'),
              BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Rewards'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Impact'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}