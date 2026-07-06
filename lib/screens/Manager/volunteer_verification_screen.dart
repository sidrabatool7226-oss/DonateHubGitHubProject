import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerVerificationScreen extends StatefulWidget {
  final String volunteerId;
  final Map<String, dynamic> volunteerData;

  const VolunteerVerificationScreen({
    super.key,
    required this.volunteerId,
    required this.volunteerData,
  });

  @override
  State<VolunteerVerificationScreen> createState() =>
      _VolunteerVerificationScreenState();
}

class _VolunteerVerificationScreenState
    extends State<VolunteerVerificationScreen> {
  String? _selectedMode; // 'Online' or 'Physical'
  final _meetLinkController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendVerificationRequest() async {
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verification mode')),
      );
      return;
    }
    if (_selectedMode == 'Online' && _meetLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Google Meet link')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.volunteerId)
          .update({
        'verificationMode': _selectedMode,
        'meetLink': _selectedMode == 'Online'
            ? _meetLinkController.text.trim()
            : null,
        'verificationStage': 'scheduled',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedMode == 'Online'
                  ? 'Meet link sent to volunteer'
                  : 'Volunteer notified for physical verification',
            ),
            backgroundColor: const Color(0xFF2E7D6B),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _approveVolunteer() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.volunteerId)
          .update({
        'status': 'verified',
        'verificationStage': 'completed',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer Approved'),
            backgroundColor: Color(0xFF2E7D6B),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _rejectVolunteer() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.volunteerId)
          .update({
        'status': 'rejected',
        'verificationStage': 'rejected',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer Rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.volunteerData;
    final roles = (data['roles'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6B),
        title: const Text('Verify Volunteer',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: data['profileImage'] != null
                        ? NetworkImage(data['profileImage'])
                        : null,
                    backgroundColor: const Color(0xFF2E7D6B).withOpacity(0.15),
                    child: data['profileImage'] == null
                        ? const Icon(Icons.person,
                        size: 45, color: Color(0xFF2E7D6B))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(data['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(data['email'] ?? '',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(),
                  _infoRow('Phone', data['phone'] ?? ''),
                  _infoRow('CNIC', data['cnic'] ?? ''),
                  _infoRow('Father Name', data['fatherName'] ?? ''),
                  _infoRow('Address', data['address'] ?? ''),
                  _infoRow('City', data['city'] ?? ''),
                  _infoRow('Blood Group', data['bloodGroup'] ?? ''),
                  _infoRow('Organization', data['organization'] ?? ''),
                  const SizedBox(height: 8),
                  const Text('Roles Applied For',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: roles
                        .map((r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D6B)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.toString(),
                          style: const TextStyle(
                              color: Color(0xFF2E7D6B),
                              fontSize: 12)),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CNIC Image
            if (data['cnicImage'] != null) ...[
              const Text('CNIC Image',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(data['cnicImage'], height: 180,
                    width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
            ],

            // Verification mode selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Verification Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _modeButton('Online', Icons.video_call),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _modeButton('Physical', Icons.location_on),
                      ),
                    ],
                  ),
                  if (_selectedMode == 'Online') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _meetLinkController,
                      decoration: InputDecoration(
                        labelText: 'Google Meet Link',
                        hintText: 'https://meet.google.com/...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _sendVerificationRequest,
                      child: const Text('Send Verification Details',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Approve / Reject
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _rejectVolunteer,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D6B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _approveVolunteer,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String mode, IconData icon) {
    final selected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E7D6B)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D6B) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 6),
            Text(mode,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}