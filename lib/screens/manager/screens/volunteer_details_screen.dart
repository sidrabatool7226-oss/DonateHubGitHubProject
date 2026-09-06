import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_details_controller.dart';

class VolunteerDetailsScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const VolunteerDetailsScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerDetailsController());

    final String name = data['name'] ?? 'Volunteer';
    final String email = data['email'] ?? '';
    final String phone = data['phone'] ?? '';
    final String cnicNumber = data['cnic'] ?? '';
    final String cnicFrontUrl = data['cnicFrontUrl'] ?? '';
    final String cnicBackUrl = data['cnicBackUrl'] ?? '';
    final String stage = data['verificationStage'] ?? 'Pending';
    final List categories = (data['categories'] as List?) ?? const [];
    final String pastExperience = (data['pastExperience'] ?? '').toString().trim();
    final dynamic createdAt = data['createdAt'];
    final bool isVerified = stage == 'Verified';
    final bool isRejected = stage == 'Rejected';
    final bool canScheduleVideo = stage == 'Pending' || stage == 'Form_Reviewed';
    final bool canSchedulePhysical =
        stage == 'Video_Scheduled' || stage == 'Physical_Scheduled';
    final bool canDecide = !isVerified && !isRejected;

    String appliedDate = '';
    try {
      final d = (createdAt as dynamic).toDate();
      appliedDate = '${d.month}/${d.day}/${d.year}';
    } catch (_) {}

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _emerald,
            foregroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_emerald, _mint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: const Text(
                'Volunteer Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Card ────────────────────────────────
                  _ProfileHeaderCard(
                    name: name,
                    email: email,
                    phone: phone,
                    appliedDate: appliedDate,
                    stage: stage,
                  ),
                  const SizedBox(height: 14),

                  // ── CNIC Number ──────────────────────────────────
                  if (cnicNumber.isNotEmpty) ...[
                    _SectionCard(
                      title: 'CNIC Number',
                      icon: Icons.badge_outlined,
                      child: Text(
                        cnicNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF14251E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Preferred Roles ─────────────────────────────
                  _SectionCard(
                    title: 'Volunteer Roles',
                    icon: Icons.category_rounded,
                    trailing: '${categories.length} Selected',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.isEmpty
                          ? [
                        Text('No roles selected',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[400]))
                      ]
                          : categories.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5EE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _emerald.withOpacity(0.3)),
                          ),
                          child: Text(
                            c.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Weekly Availability ───────────────────────────
                  _SectionCard(
                    title: 'Weekly Availability',
                    icon: Icons.calendar_month_rounded,
                    child: _AvailabilityScheduleView(scheduleData: data['availabilitySchedule']),
                  ),
                  const SizedBox(height: 14),

                  // ── Past Experience ────────────────────────────────
                  _SectionCard(
                    title: 'Past Experience',
                    icon: Icons.work_history_outlined,
                    child: Text(
                      pastExperience.isEmpty ? 'No previous experience provided' : pastExperience,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: pastExperience.isEmpty ? Colors.grey[400] : const Color(0xFF14251E),
                        fontStyle: pastExperience.isEmpty ? FontStyle.italic : FontStyle.normal,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── CNIC Images ─────────────────────────────────
                  _SectionCard(
                    title: 'Identity Verification (CNIC)',
                    icon: Icons.credit_card_rounded,
                    child: Column(
                      children: [
                        _CnicImage(label: 'Front Side', url: cnicFrontUrl),
                        const SizedBox(height: 10),
                        _CnicImage(label: 'Back Side', url: cnicBackUrl),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Schedule status info (if any) ────────────────
                  if (stage == 'Video_Scheduled') ...[
                    _InfoBanner(
                      icon: Icons.videocam_rounded,
                      color: const Color(0xFF2563EB),
                      bg: const Color(0xFFEFF6FF),
                      title: 'Video Call Scheduled',
                      lines: [
                        '${data['videoCallDate'] ?? ''} at ${data['videoCallTime'] ?? ''}',
                        'Link: ${data['videoCallLink'] ?? ''}',
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (stage == 'Physical_Scheduled') ...[
                    _InfoBanner(
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFF7C3AED),
                      bg: const Color(0xFFF3E8FF),
                      title: 'Physical Visit Scheduled',
                      lines: [
                        '${data['physicalDate'] ?? ''} at ${data['physicalTime'] ?? ''}',
                        'Location: ${data['physicalLocation'] ?? ''}',
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (isRejected) ...[
                    _InfoBanner(
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFC0392B),
                      bg: const Color(0xFFFCEBEA),
                      title: 'Application Rejected',
                      lines: [data['rejectionReason'] ?? ''],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (isVerified) ...[
                    _InfoBanner(
                      icon: Icons.verified_rounded,
                      color: _emerald,
                      bg: const Color(0xFFE6F5EE),
                      title: 'Volunteer Verified',
                      lines: const ['This volunteer can now receive tasks.'],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Action Buttons ───────────────────────────────
                  if (canScheduleVideo || canSchedulePhysical) ...[
                    Row(
                      children: [
                        if (canScheduleVideo)
                          Expanded(
                            child: _ActionOutlineBtn(
                              icon: Icons.videocam_outlined,
                              label: 'Schedule\nVideo Call',
                              color: const Color(0xFF2563EB),
                              onTap: () => _showVideoCallSheet(
                                  context, controller, docId),
                            ),
                          ),
                        if (canScheduleVideo && canSchedulePhysical)
                          const SizedBox(width: 10),
                        if (canSchedulePhysical)
                          Expanded(
                            child: _ActionOutlineBtn(
                              icon: Icons.location_on_outlined,
                              label: 'Schedule\nPhysical Visit',
                              color: const Color(0xFF7C3AED),
                              onTap: () => _showPhysicalVisitSheet(
                                  context, controller, docId),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (canDecide) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showRejectSheet(context, controller, docId),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC0392B),
                              side: const BorderSide(color: Color(0xFFC0392B)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() => ElevatedButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : () async {
                              bool ok = await controller
                                  .approveVolunteer(docId);
                              if (ok) Get.back();
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoCallSheet(BuildContext context,
      VolunteerDetailsController controller, String volunteerId) {
    controller.videoDateController.clear();
    controller.videoTimeController.clear();
    controller.meetLinkController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.videocam_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Schedule Video Call',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Volunteer will receive this via notification',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => controller.pickVideoDate(context),
                child: AbsorbPointer(
                  child: _SheetField(
                    controller: controller.videoDateController,
                    label: 'Interview Date *',
                    hint: 'Select date',
                    suffixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => controller.pickVideoTime(context),
                child: AbsorbPointer(
                  child: _SheetField(
                    controller: controller.videoTimeController,
                    label: 'Interview Time *',
                    hint: 'Select time',
                    suffixIcon: Icons.access_time_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: controller.meetLinkController,
                label: 'Google Meet / Zoom Link *',
                hint: 'Paste meeting link here',
                suffixIcon: Icons.link_rounded,
              ),
              const SizedBox(height: 20),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                    bool ok = await controller
                        .scheduleVideoCall(volunteerId);
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Notify Volunteer',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhysicalVisitSheet(BuildContext context,
      VolunteerDetailsController controller, String volunteerId) {
    controller.physicalDateController.clear();
    controller.physicalTimeController.clear();
    controller.locationController.clear();
    controller.notesController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text('Schedule Physical Visit',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Set in-person verification appointment',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => controller.pickPhysicalDate(context),
                child: AbsorbPointer(
                  child: _SheetField(
                    controller: controller.physicalDateController,
                    label: 'Appointment Date *',
                    hint: 'Select date',
                    suffixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => controller.pickPhysicalTime(context),
                child: AbsorbPointer(
                  child: _SheetField(
                    controller: controller.physicalTimeController,
                    label: 'Preferred Time *',
                    hint: 'Select time',
                    suffixIcon: Icons.access_time_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: controller.locationController,
                label: 'Office Location *',
                hint: 'e.g. LSOH Office, Wah Cantt',
                suffixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: controller.notesController,
                label: 'Special Instructions (optional)',
                hint: 'Documents to bring, entrance info...',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                    bool ok = await controller
                        .schedulePhysicalVisit(volunteerId);
                    if (ok && context.mounted) {
                      Navigator.pop(context);
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Send Instructions',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectSheet(BuildContext context,
      VolunteerDetailsController controller, String volunteerId) {
    controller.rejectReasonController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.cancel_rounded, color: Color(0xFFC0392B)),
                SizedBox(width: 8),
                Text('Reject Application',
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('This reason will be sent to the volunteer',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            _SheetField(
              controller: controller.rejectReasonController,
              label: 'Rejection Reason *',
              hint: 'e.g. Incomplete documents, failed verification...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                  bool ok =
                  await controller.rejectVolunteer(volunteerId);
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
                child: controller.isSaving.value
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Rejection',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// AVAILABILITY SCHEDULE VIEW
// ==========================================================================
class _AvailabilityScheduleView extends StatelessWidget {
  final dynamic scheduleData;
  const _AvailabilityScheduleView({required this.scheduleData});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final List schedule = (scheduleData is List) ? scheduleData : [];

    if (schedule.isEmpty) {
      return Text(
        'Volunteer has not set their availability yet.',
        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
      );
    }

    final availableDays =
    schedule.where((e) => e['isAvailable'] == true).toList();

    if (availableDays.isEmpty) {
      return Row(
        children: [
          Icon(Icons.event_busy_rounded, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Volunteer has not marked any days as available.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      );
    }

    return Column(
      children: availableDays.map((entry) {
        final day = entry['day'] ?? '';
        final start = entry['startTime'] ?? '';
        final end = entry['endTime'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F5EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _emerald.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(color: _emerald, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(day, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF14251E))),
              ),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 13, color: _emerald),
                const SizedBox(width: 4),
                Text('$start - $end', style: const TextStyle(
                    fontSize: 11.5, color: _emerald, fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================================================
// PROFILE HEADER CARD
// ==========================================================================
class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String appliedDate;
  final String stage;

  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.appliedDate,
    required this.stage,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F5EE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'V',
                style: const TextStyle(
                  color: _emerald, fontSize: 22, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14251E))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(email,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(phone.isEmpty ? 'Not provided' : phone,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Applied $appliedDate',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SECTION CARD
// ==========================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.child,
  });

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _emerald),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.bold,
                      color: Color(0xFF14251E))),
              const Spacer(),
              if (trailing != null)
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 11.5, color: _emerald,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ==========================================================================
// CNIC IMAGE
// ==========================================================================
class _CnicImage extends StatelessWidget {
  final String label;
  final String url;

  const _CnicImage({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: url.isEmpty
          ? null
          : () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.isEmpty
                ? Container(
              height: 130,
              width: double.infinity,
              color: const Color(0xFFF4FAF7),
              child: Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey[400], size: 30),
            )
                : Image.network(
              url,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 130,
                color: const Color(0xFFF4FAF7),
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.grey[400]),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// INFO BANNER
// ==========================================================================
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final List<String> lines;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(l,
                      style: TextStyle(
                          fontSize: 11.5, color: color.withOpacity(0.85))),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ACTION OUTLINE BUTTON
// ==========================================================================
class _ActionOutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionOutlineBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// SHEET WIDGETS
// ==========================================================================
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final IconData? suffixIcon;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: Colors.grey[400])
                : null,
            filled: true,
            fillColor: const Color(0xFFF4FAF7),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F6E4F)),
            ),
          ),
        ),
      ],
    );
  }
}