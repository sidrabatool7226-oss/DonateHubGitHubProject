// ============================================================
// FILE: lib/widgets/donor_pickup_volunteer_card.dart (NEW)
//
// PURPOSE
// Shown inside the Donor's existing "Pickup Information" card on
// DonationDetailScreen (lib/screens/donor/donor_donations_tab.dart)
// once a resource donation reaches status 'pickup_assigned'.
//
// Displays ONLY non-sensitive, operational information about the
// assigned volunteer — name, phone (tap to call), live task status,
// the item/quantity being collected, and the pickup address — plus
// the same embedded map already built for the Volunteer's own task
// screen (TaskPickupMapSection). This widget deliberately never
// reads or shows the volunteer's CNIC, home address, email, reward
// points, or any other personal profile field — those live only on
// the volunteer's own user document and are never queried here.
//
// Reads live from the SAME 'tasks' document already created by
// ManagerTasksController.assignVolunteer() (looked up by
// donationId), so status changes (assigned -> accepted -> delivered)
// reflect in real time without the donor refreshing the screen.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'task_pickup_map_section.dart';

class DonorPickupVolunteerCard extends StatelessWidget {
  final String donationId;

  const DonorPickupVolunteerCard({super.key, required this.donationId});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('donationId', isEqualTo: donationId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: _green),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          // The task document hasn't synced yet — fall back to the
          // original generic message rather than showing a blank card.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions_bike_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A volunteer has been assigned to collect your donation.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ),
            ],
          );
        }

        final taskDoc = docs.first;
        final taskData = taskDoc.data() as Map<String, dynamic>;
        final String taskStatus = (taskData['status'] ?? 'assigned').toString();

        if (taskStatus == 'rejected') {
          // The previously assigned volunteer declined — the Manager
          // will reassign. Showing their name/status here would be
          // confusing, so a neutral note is shown instead.
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E4), borderRadius: BorderRadius.circular(11)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.autorenew_rounded, size: 16, color: Color(0xFFDB7C26)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We\'re reassigning your pickup to another volunteer shortly.',
                    style: TextStyle(fontSize: 11.5, color: const Color(0xFFDB7C26), height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }

        final String volunteerName = (taskData['volunteerName'] ?? 'Volunteer').toString();
        final String volunteerPhone = (taskData['volunteerPhone'] ?? '').toString();
        final String itemName = (taskData['itemName'] ?? '').toString();
        final String quantity = (taskData['quantity'] ?? '').toString();
        final String pickupAddress = (taskData['pickupAddress'] ?? taskData['location'] ?? '').toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : 'V',
                    style: const TextStyle(color: _green, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(volunteerName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                      if (volunteerPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('📞 $volunteerPhone', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PickupStatusChip(taskStatus: taskStatus),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (itemName.isNotEmpty || quantity.isNotEmpty)
              _infoRow(
                Icons.inventory_2_outlined,
                'Donation',
                quantity.isNotEmpty ? '$itemName — $quantity' : itemName,
              ),
            if (pickupAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(Icons.location_on_outlined, 'Pickup Location', pickupAddress),
            ],
            if (volunteerPhone.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _callVolunteer(context, volunteerPhone),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call Volunteer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (pickupAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              TaskPickupMapSection(
                taskId: taskDoc.id,
                taskData: taskData,
                pickupAddress: pickupAddress,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _callVolunteer(BuildContext context, String phone) async {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitized.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: sanitized);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer on this device.')),
      );
    }
  }
}

class _PickupStatusChip extends StatelessWidget {
  final String taskStatus;
  const _PickupStatusChip({required this.taskStatus});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color bg;
    late final String label;

    switch (taskStatus) {
      case 'accepted':
        color = Colors.blue[700]!;
        bg = Colors.blue[50]!;
        label = 'On the Way';
        break;
      case 'delivered':
        color = Colors.teal[700]!;
        bg = Colors.teal[50]!;
        label = 'Picked Up';
        break;
      case 'completed':
        color = Colors.green[700]!;
        bg = Colors.green[50]!;
        label = 'Completed';
        break;
      case 'assigned':
      default:
        color = Colors.orange[700]!;
        bg = Colors.orange[50]!;
        label = 'Assigned';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w700)),
    );
  }
}