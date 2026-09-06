import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_create_task_controller.dart';

class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerCreateTaskController());
    controller.clearForm();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Task Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _Field(label: 'Task Title *', controller: controller.titleController, hint: 'e.g. Blood Donation Camp — PWD'),
              const SizedBox(height: 12),
              _Field(label: 'Description *', controller: controller.descriptionController, hint: 'What does this task involve?', maxLines: 3),
              const SizedBox(height: 12),
              _Field(label: 'Location', controller: controller.locationController, hint: 'e.g. LSOH Office, Islamabad'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.pickDate(context),
                    child: AbsorbPointer(
                      child: _Field(label: 'Date *', controller: controller.dateController, hint: 'Select date', suffixIcon: Icons.calendar_today_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.pickTime(context),
                    child: AbsorbPointer(
                      child: _Field(label: 'Time *', controller: controller.timeController, hint: 'Select time', suffixIcon: Icons.access_time_rounded),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _Field(label: 'Additional Instructions (optional)', controller: controller.instructionsController, hint: 'Anything the volunteer should know...', maxLines: 2),
            ])),
            const SizedBox(height: 14),

            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Task Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Select the category that matches volunteer roles', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8, runSpacing: 8,
                children: ManagerCreateTaskController.taskCategories.map((cat) {
                  final isSel = controller.selectedCategory.value == cat;
                  return GestureDetector(
                    onTap: () => controller.onCategorySelected(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? _emerald : const Color(0xFFF4FAF7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? _emerald : Colors.grey.shade300),
                      ),
                      child: Text(cat, style: TextStyle(
                        fontSize: 12, color: isSel ? Colors.white : Colors.grey[700],
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                      )),
                    ),
                  );
                }).toList(),
              )),
            ])),
            const SizedBox(height: 14),

            Obx(() {
              if (controller.selectedCategory.value == null) return const SizedBox();
              if (controller.isLoadingVolunteers.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: _emerald)),
                );
              }
              final volunteers = controller.matchingVolunteers;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.people_outline_rounded, size: 15, color: _emerald),
                    const SizedBox(width: 6),
                    Text('Matching Volunteers (${volunteers.length})',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  if (volunteers.isEmpty)
                    _Card(child: Row(children: [
                      Icon(Icons.person_off_outlined, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        'No verified volunteers have selected "${controller.selectedCategory.value}" as their role.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      )),
                    ]))
                  else
                    ...volunteers.map((v) => _VolunteerMatchCard(volunteer: v, controller: controller)),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _VolunteerMatchCard extends StatelessWidget {
  final Map<String, dynamic> volunteer;
  final ManagerCreateTaskController controller;
  const _VolunteerMatchCard({required this.volunteer, required this.controller});

  static const Color _emerald = Color(0xFF0F6E4F);

  @override
  Widget build(BuildContext context) {
    final name = volunteer['name'] ?? 'Volunteer';
    final categories = (volunteer['categories'] as List?) ?? [];
    final pastExperience = (volunteer['pastExperience'] ?? '').toString().trim();
    final availableDays = controller.availableDaysFor(volunteer);
    final isOnline = volunteer['isOnline'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Stack(children: [
              CircleAvatar(radius: 22, backgroundColor: const Color(0xFFE6F5EE),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'V',
                      style: const TextStyle(color: _emerald, fontWeight: FontWeight.bold))),
              if (isOnline)
                Positioned(right: 0, bottom: 0, child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: const Color(0xFF2FBF87), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                )),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              Wrap(spacing: 4, children: categories.take(3).map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(color: const Color(0xFFF4FAF7), borderRadius: BorderRadius.circular(6)),
                child: Text(c.toString(), style: TextStyle(fontSize: 9.5, color: Colors.grey[600])),
              )).toList()),
            ])),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: availableDays.isEmpty ? Colors.grey[400] : _emerald),
            const SizedBox(width: 5),
            Expanded(child: Text(
              availableDays.isEmpty
                  ? 'Availability not provided'
                  : availableDays.map((d) => (d['day'] as String).substring(0, 3)).join(', '),
              style: TextStyle(fontSize: 11, color: availableDays.isEmpty ? Colors.grey[400] : Colors.grey[700]),
            )),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.work_history_outlined, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 5),
            Expanded(child: Text(
              pastExperience.isEmpty ? 'No previous experience provided' : pastExperience,
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: pastExperience.isEmpty ? FontStyle.italic : FontStyle.normal),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 12),
          Obx(() => SizedBox(
            width: double.infinity, height: 42,
            child: ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : () async {
                bool ok = await controller.createAndAssignTask(
                  volunteerId: volunteer['uid'],
                  volunteerName: name,
                );
                if (ok) Get.back();
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Assign This Task', style: TextStyle(fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final IconData? suffixIcon;
  const _Field({required this.label, required this.controller, required this.hint, this.maxLines = 1, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18, color: Colors.grey[400]) : null,
          filled: true, fillColor: const Color(0xFFF4FAF7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F6E4F))),
        ),
      ),
    ]);
  }
}