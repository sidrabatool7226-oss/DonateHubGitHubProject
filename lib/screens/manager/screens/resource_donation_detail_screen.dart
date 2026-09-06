import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/manager_donations_controller.dart';
import '../../../controllers/manager_tasks_controller.dart';
import 'assign_volunteer_screen.dart';

class ResourceDonationDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ResourceDonationDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _value(List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  String _display(List<String> keys) {
    final value = _value(keys);
    return value.isEmpty ? 'Not provided' : value;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ManagerDonationsController>()) {
      Get.put(ManagerDonationsController());
    }

    final controller = Get.find<ManagerDonationsController>();

    final String imageUrl = _value([
      'itemImageUrl',
      'imageUrl',
      'image',
      'receiptImageUrl',
    ]);

    final String status = _text(data['status']).isEmpty
        ? 'pending'
        : _text(data['status']);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Resource Donation Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageSection(imageUrl),
            const SizedBox(height: 14),

            _section(
              title: 'Donation Information',
              icon: Icons.inventory_2_outlined,
              children: [
                _InfoRow(
                  label: 'Item Name',
                  value: _display(['itemName']),
                ),
                _InfoRow(
                  label: 'Category',
                  value: _display(['category']),
                ),
                _InfoRow(
                  label: 'Quantity',
                  value: _display(['quantity']),
                ),
                _InfoRow(
                  label: 'Condition',
                  value: _display([
                    'condition',
                    'itemCondition',
                  ]),
                ),
                _InfoRow(
                  label: 'Description',
                  value: _display([
                    'description',
                    'itemDescription',
                  ]),
                ),
                _InfoRow(
                  label: 'Campaign',
                  value: _display([
                    'campaignName',
                    'campaign',
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _section(
              title: 'Logistics',
              icon: Icons.local_shipping_outlined,
              children: [
                _InfoRow(
                  label: 'Donation Type',
                  value: _display([
                    'logisticsType',
                    'donationType',
                  ]),
                ),
                _InfoRow(
                  label: 'Address',
                  value: _display([
                    'address',
                    'pickupAddress',
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _section(
              title: 'Donor Information',
              icon: Icons.person_outline_rounded,
              children: [
                _InfoRow(
                  label: 'Name',
                  value: _display([
                    'donorName',
                    'name',
                  ]),
                ),
                _InfoRow(
                  label: 'Email',
                  value: _display([
                    'userEmail',
                    'donorEmail',
                    'email',
                  ]),
                ),
                _InfoRow(
                  label: 'Phone',
                  value: _display([
                    'donorPhone',
                    'phone',
                  ]),
                ),
                _InfoRow(
                  label: 'CNIC',
                  value: _display([
                    'donorCnic',
                    'cnic',
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _statusCard(status),

            if (status == 'pending') ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showRejectSheet(context, controller),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC0392B),
                        side: const BorderSide(
                          color: Color(0xFFC0392B),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                          () => ElevatedButton.icon(
                        onPressed: controller.isSaving.value
                            ? null
                            : () => _approveAndAssign(
                          context,
                          controller,
                        ),
                        icon: controller.isSaving.value
                            ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.check_rounded,
                          size: 18,
                        ),
                        label: Text(
                          controller.isSaving.value
                              ? 'Approving...'
                              : 'Approve',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () =>
                    _confirmDelete(context, controller),
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  size: 18,
                  color: Color(0xFFC0392B),
                ),
                label: const Text(
                  'Delete as Illegal Item',
                  style: TextStyle(
                    color: Color(0xFFC0392B),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAndAssign(
      BuildContext context,
      ManagerDonationsController controller,
      ) async {
    final bool ok =
    await controller.approveResourceDonation(docId);

    if (!ok) return;

    if (!Get.isRegistered<ManagerTasksController>()) {
      Get.put(ManagerTasksController());
    }

    final taskController = Get.find<ManagerTasksController>();

    Get.off(
          () => AssignVolunteerScreen(
        donationId: docId,
        data: data,
      ),
      transition: Transition.rightToLeft,
    );

    // Make sure controller is actually retained for AssignVolunteerScreen.
    taskController.selectedTab.value = 0;
  }

  Widget _imageSection(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF9AA9A2),
          size: 48,
        ),
      )
          : Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF9AA9A2),
              size: 45,
            ),
          );
        },
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _emerald,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14251E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _statusCard(String status) {
    Color color;
    Color background;
    String label;

    switch (status) {
      case 'approved':
        color = const Color(0xFF1565C0);
        background = const Color(0xFFE3F2FD);
        label = 'Approved';
        break;

      case 'pickup_assigned':
        color = const Color(0xFF1565C0);
        background = const Color(0xFFE3F2FD);
        label = 'Pickup Assigned';
        break;

      case 'completed':
        color = _emerald;
        background = const Color(0xFFE6F5EE);
        label = 'Completed';
        break;

      case 'rejected':
        color = const Color(0xFFC0392B);
        background = const Color(0xFFFCEBEA);
        label = 'Rejected';
        break;

      default:
        color = const Color(0xFFDB7C26);
        background = const Color(0xFFFFF3E4);
        label = 'Pending Review';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            status == 'rejected'
                ? Icons.cancel_outlined
                : status == 'completed'
                ? Icons.check_circle_outline
                : Icons.pending_actions_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectSheet(
      BuildContext context,
      ManagerDonationsController controller,
      ) {
    controller.rejectReasonController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reject Donation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller.rejectReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection...',
                  filled: true,
                  fillColor: const Color(0xFFF4FAF7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final bool ok =
                    await controller.rejectDonation(docId);

                    if (ok && context.mounted) {
                      Navigator.pop(context);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Confirm Rejection'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context,
      ManagerDonationsController controller,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Donation'),
        content: const Text(
          'This will permanently remove this donation. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final bool ok =
              await controller.deleteDonation(docId);

              if (ok) {
                Get.back();
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFC0392B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty || value == 'Not provided') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Not provided',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9AA9A2),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14251E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}