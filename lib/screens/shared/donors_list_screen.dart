import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/donors_list_controller.dart';

class DonorsListScreen extends StatelessWidget {
  final Color accentColor;
  const DonorsListScreen({super.key, this.accentColor = const Color(0xFF1B6B3A)});

  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DonorsListController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Donor Rewards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      onChanged: (v) => controller.searchQuery.value = v,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search donor by name or email...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }
                final list = controller.filtered;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No donors found', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final d = list[index];
                    final name = d['name'] ?? 'Donor';
                    final email = d['email'] ?? '';
                    final pts = d['rewardPoints'] ?? 0;
                    final totalDonations = d['totalDonations'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22, backgroundColor: accentColor.withOpacity(0.12),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                const SizedBox(height: 4),
                                Text('$totalDonations donation${totalDonations == 1 ? '' : 's'}',
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey[400])),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$pts pts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                              Text(controller.badgeFor(pts), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}