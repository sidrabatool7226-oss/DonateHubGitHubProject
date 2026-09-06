import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/volunteer_tasks_controller.dart';

class VolunteerTaskDetailScreen extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> data;
  const VolunteerTaskDetailScreen({super.key, required this.taskId, required this.data});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  Future<void> _openMaps(BuildContext context, String address) async {
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('No location provided for this task'), backgroundColor: Colors.red[700]),
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VolunteerTasksController>()
        ? Get.find<VolunteerTasksController>()
        : Get.put(VolunteerTasksController());

    final String status = data['status'] ?? 'assigned';
    final String title = data['title'] ?? data['itemName'] ?? 'Task';
    final String category = data['taskCategory'] ?? '';
    final String description = data['description'] ?? '';
    final int quantity = data['quantity'] is String
        ? int.tryParse(data['quantity']) ?? 0
        : (data['quantity'] as num?)?.toInt() ?? 0;
    final String donorName = data['donorName'] ?? '';
    final String location = (data['location'] ?? data['pickupAddress'] ?? '').toString();
    final String date = data['date'] ?? '';
    final String time = data['time'] ?? '';
    final String instructions = data['instructions'] ?? '';
    final String assignedBy = data['assignedBy'] ?? '';
    final String? proofUrl = data['deliveryProofUrl'];

    // FIXED: Navigate only shows for Resource Pickup tasks (always has an
    // address), OR for other categories when a genuine location was
    // provided by the Manager during task creation.
    final bool showNavigate = location.isNotEmpty && (category == 'Resource Pickup' || category.isEmpty || location.trim().length > 3);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Task Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                        child: Icon(
                          category == 'Resource Pickup' ? Icons.inventory_2_rounded : Icons.volunteer_activism_rounded,
                          color: _green, size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            if (category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                child: Text(category, style: const TextStyle(fontSize: 10.5, color: _green, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                  ],
                  if (quantity > 0) ...[
                    const SizedBox(height: 8),
                    Text('Quantity: $quantity', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (date.isNotEmpty || time.isNotEmpty) ...[
              _Card(
                child: Row(
                  children: [
                    if (date.isNotEmpty) Expanded(child: _detailRow(Icons.calendar_today_outlined, 'Date', date)),
                    if (time.isNotEmpty) Expanded(child: _detailRow(Icons.access_time_rounded, 'Time', time)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (donorName.isNotEmpty || location.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (donorName.isNotEmpty) ...[
                      const Text('Contact Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.person_outline, size: 15, color: _green),
                        const SizedBox(width: 8),
                        Text(donorName, style: const TextStyle(fontSize: 13)),
                      ]),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: _green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(location, style: const TextStyle(fontSize: 13))),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (instructions.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Special Instructions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(instructions, style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Navigate — category-conditional ─────────────────────
            if (status == 'accepted' && showNavigate)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _openMaps(context, location),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Navigate to Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (status == 'accepted' && showNavigate) const SizedBox(height: 14),

            if (proofUrl != null && proofUrl.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Completion Proof', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(proofUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (status == 'assigned') _NewTaskActions(taskId: taskId, assignedBy: assignedBy, controller: controller),
            if (status == 'accepted') _UploadProofSection(taskId: taskId, assignedBy: assignedBy, controller: controller),
            if (status == 'delivered')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E4), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFDB7C26)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Waiting for manager to confirm completion.', style: TextStyle(fontSize: 12.5, color: Color(0xFFDB7C26)))),
                ]),
              ),
            if (status == 'rejected')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFC0392B)),
                  SizedBox(width: 10),
                  Expanded(child: Text('You rejected this task.', style: TextStyle(fontSize: 12.5, color: Color(0xFFC0392B)))),
                ]),
              ),
            if (status == 'completed')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: _green),
                  SizedBox(width: 10),
                  Expanded(child: Text('Task completed. Thank you for your help!', style: TextStyle(fontSize: 12.5, color: _green))),
                ]),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: _green),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

class _NewTaskActions extends StatelessWidget {
  final String taskId;
  final String assignedBy;
  final VolunteerTasksController controller;
  const _NewTaskActions({required this.taskId, required this.assignedBy, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectSheet(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC0392B),
              side: const BorderSide(color: Color(0xFFC0392B)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : () async {
              bool ok = await controller.acceptTask(taskId, assignedBy);
              if (ok) Get.back();
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )),
        ),
      ],
    );
  }

  void _showRejectSheet(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reject Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl, maxLines: 3,
              decoration: InputDecoration(hintText: 'Reason (optional)...', filled: true, fillColor: const Color(0xFFF4F6F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  bool ok = await controller.rejectTask(taskId, assignedBy, reasonCtrl.text.trim().isEmpty ? 'No reason given' : reasonCtrl.text.trim());
                  if (ok && context.mounted) { Navigator.pop(context); Get.back(); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Confirm Rejection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadProofSection extends StatelessWidget {
  final String taskId;
  final String assignedBy;
  final VolunteerTasksController controller;
  const _UploadProofSection({required this.taskId, required this.assignedBy, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VolunteerTasksController>(
      builder: (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Completion Proof', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: c.pickProofImage,
            child: Container(
              height: 160, width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _green.withOpacity(0.3))),
              child: c.proofImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(c.proofImage!, fit: BoxFit.cover))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_outlined, color: _green, size: 30),
                SizedBox(height: 8),
                Text('Take a photo as proof of completion', style: TextStyle(color: _green, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 50,
            child: Obx(() => ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : () async {
                bool ok = await controller.uploadDeliveryProof(taskId, assignedBy);
                if (ok) Get.back();
              },
              icon: const Icon(Icons.upload_rounded),
              label: controller.isSaving.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Proof', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: child,
    );
  }
}