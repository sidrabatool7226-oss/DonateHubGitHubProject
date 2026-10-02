import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/volunteer_tasks_controller.dart';
import '../../../widgets/task_pickup_map_section.dart'; // NEW — embedded pickup map
import '../../../widgets/task_category_style.dart'; // NEW — role icon / wording

class VolunteerTaskDetailScreen extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> data;
  const VolunteerTaskDetailScreen({super.key, required this.taskId, required this.data});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF2F7F4);

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

  // NEW — "2h ago" style text for when the task was assigned
  String _assignedAgo() {
    final ts = data['assignedAt'];
    if (ts is! Timestamp) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays >= 1) return 'Assigned ${diff.inDays}d ago';
    if (diff.inHours >= 1) return 'Assigned ${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return 'Assigned ${diff.inMinutes}m ago';
    return 'Assigned just now';
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
    final String requiredBlood = (data['requiredBloodGroup'] ?? '').toString(); // NEW
    final style = TaskCategoryStyle.of(category); // NEW
    final String assignedAgo = _assignedAgo(); // NEW

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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        title: const Text('Task Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ───────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: _green.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: Icon(style.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF14251E))),
                            if (category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                child: Text(category, style: const TextStyle(fontSize: 10.5, color: _green, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (assignedAgo.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Text(assignedAgo, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                    ]),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.45)),
                  ],
                  // NEW — blood donation: the blood group the manager asked for
                  if (requiredBlood.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC0392B).withOpacity(0.18)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.bloodtype_rounded, color: Color(0xFFC0392B), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Blood group needed', style: TextStyle(fontSize: 12.5, color: Color(0xFFC0392B), fontWeight: FontWeight.w600))),
                        Text(requiredBlood, style: const TextStyle(fontSize: 20, color: Color(0xFFC0392B), fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ],
                  if (quantity > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFF6FAF8), borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.numbers_rounded, size: 14, color: _green),
                        const SizedBox(width: 5),
                        Text('Quantity: $quantity', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Progress timeline (NEW) ─────────────────────────────
            if (status != 'rejected') ...[
              _Card(child: _StatusTimeline(status: status)),
              const SizedBox(height: 14),
            ],

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
                      const _SectionTitle(icon: Icons.contact_page_outlined, title: 'Contact Information'),
                      const SizedBox(height: 12),
                      Row(children: [
                        _iconTile(Icons.person_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category == 'Resource Pickup' ? 'Donor' : 'Contact', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              Text(donorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ]),
                    ],
                    if (location.isNotEmpty) ...[
                      if (donorName.isEmpty) ...[
                        _SectionTitle(icon: Icons.place_outlined, title: style.locationLabel),
                        const SizedBox(height: 12),
                      ] else
                        const SizedBox(height: 12),
                      Row(children: [
                        _iconTile(Icons.location_on_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (donorName.isNotEmpty)
                                Text(style.locationLabel, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              Text(location, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── NEW — embedded pickup-location map ──────────────────
            // Additive only: does not replace the address text above,
            // the existing "Navigate to Location" button below, or any
            // other existing task information/actions on this screen.
            if (location.isNotEmpty) ...[
              TaskPickupMapSection(
                taskId: taskId,
                taskData: data,
                pickupAddress: location,
              ),
              const SizedBox(height: 14),
            ],

            if (instructions.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(icon: Icons.lightbulb_outline_rounded, title: 'Special Instructions'),
                    const SizedBox(height: 10),
                    Text(instructions, style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.45)),
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
                    const _SectionTitle(icon: Icons.verified_outlined, title: 'Completion Proof'),
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
                decoration: BoxDecoration(color: const Color(0xFFFFF3E4), borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFDB7C26)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Waiting for manager to confirm completion.', style: TextStyle(fontSize: 12.5, color: Color(0xFFDB7C26)))),
                ]),
              ),
            if (status == 'rejected')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFC0392B)),
                  SizedBox(width: 10),
                  Expanded(child: Text('You rejected this task.', style: TextStyle(fontSize: 12.5, color: Color(0xFFC0392B)))),
                ]),
              ),
            if (status == 'completed')
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
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

  Widget _iconTile(IconData icon) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, size: 18, color: _green),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      _iconTile(icon),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }
}

// ==========================================================================
// NEW — progress timeline: Assigned → Accepted → Delivered → Completed
// ==========================================================================
class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const Color _green = Color(0xFF1B6B3A);
  static const List<String> _labels = ['Assigned', 'Accepted', 'Delivered', 'Completed'];

  int get _index {
    switch (status) {
      case 'accepted':
        return 1;
      case 'delivered':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int current = _index;
    return Row(
      children: List.generate(_labels.length, (i) {
        final bool done = i < current;
        final bool active = i == current;
        final Color leftLine = i <= current ? _green : Colors.grey.shade300;
        final Color rightLine = i < current ? _green : Colors.grey.shade300;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : leftLine)),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: done || active ? _green : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: done || active ? _green : Colors.grey.shade300, width: 2),
                      boxShadow: active ? [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 8)] : null,
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : active
                        ? const Icon(Icons.circle, size: 8, color: Colors.white)
                        : null,
                  ),
                  Expanded(child: Container(height: 2, color: i == _labels.length - 1 ? Colors.transparent : rightLine)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: done || active ? _green : Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF1B6B3A)),
      const SizedBox(width: 7),
      Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF14251E))),
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

// CHANGED — now a StatefulWidget only so a photo picked for a previous task is
// cleared when this screen opens (the controller keeps one shared proofImage,
// which could otherwise be submitted as proof for the wrong task).
class _UploadProofSection extends StatefulWidget {
  final String taskId;
  final String assignedBy;
  final VolunteerTasksController controller;
  const _UploadProofSection({required this.taskId, required this.assignedBy, required this.controller});

  @override
  State<_UploadProofSection> createState() => _UploadProofSectionState();
}

class _UploadProofSectionState extends State<_UploadProofSection> {
  static const Color _green = Color(0xFF1B6B3A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.proofImage != null) widget.controller.clearProofImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GetBuilder<VolunteerTasksController>(
      builder: (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.camera_alt_outlined, title: 'Upload Completion Proof'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: c.pickProofImage,
            child: Container(
              height: 170, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _green.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: _green.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: c.proofImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(c.proofImage!, fit: BoxFit.cover))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: _green, size: 26),
                ),
                const SizedBox(height: 10),
                const Text('Take a photo as proof of completion', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 50,
            child: Obx(() => ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : () async {
                bool ok = await controller.uploadDeliveryProof(widget.taskId, widget.assignedBy);
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF1B6B3A).withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))]),
      child: child,
    );
  }
}