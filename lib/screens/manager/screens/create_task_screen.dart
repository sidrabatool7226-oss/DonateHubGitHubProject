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
              if (controller.selectedCategory.value != 'Blood Donation') return const SizedBox();
              final selected = controller.selectedBloodGroup.value;
              return Column(children: [
                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Blood Group Needed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Optional — shows compatible donors only, exact group first',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Any', ...ManagerCreateTaskController.bloodGroups].map((g) {
                      final isSel = g == 'Any' ? selected == null : selected == g;
                      return GestureDetector(
                        onTap: () => controller.selectedBloodGroup.value = g == 'Any' ? null : g,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFC0392B) : const Color(0xFFF4FAF7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? const Color(0xFFC0392B) : Colors.grey.shade300),
                          ),
                          child: Text(g, style: TextStyle(
                            fontSize: 12, color: isSel ? Colors.white : Colors.grey[700],
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ])),
                const SizedBox(height: 14),
              ]);
            }),

            Obx(() {
              if (controller.selectedCategory.value == null) return const SizedBox();
              if (controller.isLoadingVolunteers.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: _emerald)),
                );
              }
              // CHANGED — shows the filtered / sorted list (online first, available
              // on the task date, fewer open tasks) instead of the raw list.
              final bool noRoleMatch = controller.matchingVolunteers.isEmpty;
              final bool onlyOnline = controller.onlineOnly.value;
              final volunteers = controller.visibleVolunteers;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.people_outline_rounded, size: 15, color: _emerald),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Matching Volunteers (${volunteers.length})',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                    Text('Online only', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: onlyOnline,
                        activeTrackColor: _emerald,
                        onChanged: (v) => controller.onlineOnly.value = v,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  if (volunteers.isEmpty)
                    _Card(child: Row(children: [
                      Icon(Icons.person_off_outlined, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        noRoleMatch
                            ? 'No verified volunteers have selected "${controller.selectedCategory.value}" as their role.'
                            : 'No volunteers match the current filters (online only / blood group).',
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
              Row(children: [
                Flexible(child: Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                // NEW — blood group (Blood Donation tasks only)
                if (volunteer['_showBlood'] == true && (volunteer['bloodGroup'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: volunteer['_exactBlood'] == true ? const Color(0xFFC0392B) : const Color(0xFFFCEBEA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      volunteer['bloodGroup'].toString(),
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: volunteer['_exactBlood'] == true ? Colors.white : const Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ],
              ]),
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
          // NEW — schedule on the task's weekday (today until a date is picked) + open task count
          Row(children: [
            Icon(Icons.schedule_rounded, size: 12,
                color: volunteer['_availableOnDate'] == true ? _emerald : Colors.grey[400]),
            const SizedBox(width: 5),
            Expanded(child: Text(
              (volunteer['_scheduleText'] ?? '').toString(),
              style: TextStyle(
                fontSize: 11,
                color: volunteer['_availableOnDate'] == true ? _emerald : Colors.grey[500],
                fontWeight: volunteer['_availableOnDate'] == true ? FontWeight.w600 : FontWeight.normal,
              ),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (volunteer['_activeTasks'] ?? 0) == 0 ? const Color(0xFFE6F5EE) : const Color(0xFFFFF3E4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (volunteer['_activeTasks'] ?? 0) == 0
                    ? 'No active tasks'
                    : '${volunteer['_activeTasks']} active task${volunteer['_activeTasks'] == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: (volunteer['_activeTasks'] ?? 0) == 0 ? _emerald : const Color(0xFFDB7C26),
                ),
              ),
            ),
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
              onPressed: () async {
                if (controller.isSaving.value) return; // already saving — ignore extra taps
                bool ok = await controller.createAndAssignTask(
                  volunteerId: volunteer['uid'],
                  volunteerName: name,
                  showMessage: false,
                );
                // CHANGED — close the screen first, then show the message
                // (Get.back() would otherwise close the snackbar, not the screen).
                if (ok) {
                  Get.back();
                  Get.snackbar('Task Assigned', 'Task assigned to $name',
                      backgroundColor: Colors.green[50], colorText: Colors.green[700],
                      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
                }
              },
              // CHANGED — only the pressed volunteer's button shows the spinner
              icon: controller.isSaving.value && controller.assigningVolunteerId.value == volunteer['uid']
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 16),
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