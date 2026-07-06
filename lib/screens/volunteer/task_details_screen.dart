import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  static const Color primaryGreen = Color(0xFF1FA15C);
  bool _isAccepting = false;

  Future<void> _navigateToLocation(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  Future<void> _callDonor(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _acceptTask() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isAccepting = true);

    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'status': 'in_progress',
        'assignedVolunteerId': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task accepted! Head over to pick it up.'),
            backgroundColor: primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _isAccepting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .doc(widget.taskId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.data!.exists) {
              return const Center(child: Text('Task not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final description = data['description'] ?? '';
            final address = data['address'] ?? '';
            final imageUrl = data['imageUrl'] ?? '';
            final donorName = data['donorName'] ?? '';
            final donorPhone = data['donorPhone'] ?? '';
            final status = data['status'] ?? 'available';
            final alreadyTaken = status != 'available';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('D',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Text('DonateHub',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.notifications_none, size: 24),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.settings_outlined, size: 22),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: const [
                          Icon(Icons.arrow_back, size: 16, color: primaryGreen),
                          SizedBox(width: 4),
                          Text('Back',
                              style: TextStyle(color: primaryGreen, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Task Details',
                        style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    // Task image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl.toString().isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 170,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image,
                              color: Colors.grey, size: 40),
                        ),
                      )
                          : Container(
                        height: 170,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image,
                            color: Colors.grey, size: 40),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item description card
                    _infoCard(
                      title: 'Item Description',
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 14),

                    // Donor info card
                    _infoCard(
                      title: 'Donor Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(donorName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(address,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black87)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _callDonor(donorPhone),
                            child: Row(
                              children: [
                                const Icon(Icons.call_outlined,
                                    size: 16, color: primaryGreen),
                                const SizedBox(width: 6),
                                Text(donorPhone,
                                    style: const TextStyle(
                                        fontSize: 13, color: primaryGreen)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Navigate button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToLocation(address),
                        icon: const Icon(Icons.navigation_outlined,
                            color: primaryGreen),
                        label: const Text('Navigate to Location',
                            style: TextStyle(color: primaryGreen)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Accept button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (alreadyTaken || _isAccepting)
                            ? null
                            : _acceptTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isAccepting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : Text(alreadyTaken
                            ? 'Already Accepted'
                            : 'Accept & Mark as Picked'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}