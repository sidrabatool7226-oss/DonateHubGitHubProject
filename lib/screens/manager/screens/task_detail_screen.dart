import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_tasks_controller.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> data;

  const TaskDetailScreen({super.key, required this.taskId, required this.data});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ManagerTasksController>();
    final String proofUrl = data['deliveryProofUrl'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Review Delivery Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Proof Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: proofUrl.isEmpty ? null : () => showDialog(
                context: context,
                builder: (_) => Dialog(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(proofUrl, fit: BoxFit.contain))),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: proofUrl.isEmpty
                    ? Container(height: 240, color: Colors.white, child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40))
                    : Image.network(proofUrl, height: 260, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 240, color: Colors.white, child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]))),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Item', value: data['itemName'] ?? ''),
                  _InfoRow(label: 'Quantity', value: '${data['quantity'] ?? ''}'),
                  _InfoRow(label: 'Volunteer', value: data['volunteerName'] ?? ''),
                  _InfoRow(label: 'Donor', value: data['donorName'] ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _emerald.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: _emerald, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marking complete will update inventory automatically and notify the donor with a thank-you message.',
                      style: TextStyle(fontSize: 11.5, color: _emerald),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: controller.isSaving.value ? null : () async {
                  bool ok = await controller.completeTask(taskId: taskId, taskData: data);
                  if (ok) Get.back();
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: controller.isSaving.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Mark as Completed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}