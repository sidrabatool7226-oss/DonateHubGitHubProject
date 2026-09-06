import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/volunteer_home_controller.dart';
import '../../../controllers/volunteer_tasks_controller.dart';
import 'volunteer_tasks_tab.dart';

class VolunteerHomeTab extends StatelessWidget {
  const VolunteerHomeTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerHomeController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _Header(controller: controller),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _AvailabilityToggleCard(controller: controller),
                      const SizedBox(height: 14),
                      _StatsRow(controller: controller),
                      const SizedBox(height: 20),
                      _WeeklyScheduleCard(controller: controller),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ==========================================================================
// HEADER
// ==========================================================================
class _Header extends StatelessWidget {
  final VolunteerHomeController controller;
  const _Header({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(controller.volunteerName.value,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 22),
          ),
        ],
      )),
    );
  }
}

// ==========================================================================
// AVAILABILITY TOGGLE CARD — FIXED: own Obx wraps the switch
// ==========================================================================
class _AvailabilityToggleCard extends StatelessWidget {
  final VolunteerHomeController controller;
  const _AvailabilityToggleCard({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final online = controller.isOnline.value; // explicit read — required for GetX
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: online ? const Color(0xFFE8F5E9) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                online ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                color: online ? _green : Colors.grey[400],
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(online ? 'You\'re Online' : 'You\'re Offline',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    online ? 'You can receive task assignments now' : 'Toggle on to start receiving tasks',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Switch(
              value: online,
              onChanged: controller.toggleOnlineStatus,
              activeColor: _green,
            ),
          ],
        ),
      );
    });
  }
}

// ==========================================================================
// STATS ROW — FIXED: own Obx + now tappable → navigates to My Tasks
// ==========================================================================
class _StatsRow extends StatelessWidget {
  final VolunteerHomeController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending',
            value: '${controller.pendingTasks.value}',
            color: const Color(0xFFDB7C26),
            bg: const Color(0xFFFFF3E4),
            onTap: () => _goToTasks(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_shipping_rounded,
            label: 'Active',
            value: '${controller.activeTasks.value}',
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
            onTap: () => _goToTasks(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '${controller.completedTasks.value}',
            color: const Color(0xFF1B6B3A),
            bg: const Color(0xFFE8F5E9),
            onTap: () => _goToTasks(2),
          ),
        ),
      ],
    ));
  }

  // 0 = New (pending), 1 = Accepted (active), 2 = Completed
  void _goToTasks(int tabIndex) {
    final tasksController = Get.isRegistered<VolunteerTasksController>()
        ? Get.find<VolunteerTasksController>()
        : Get.put(VolunteerTasksController());
    tasksController.selectedTab.value = tabIndex;
    Get.to(() => const VolunteerTasksTab(), transition: Transition.rightToLeft);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon, required this.label, required this.value,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// WEEKLY SCHEDULE CARD — FIXED: own Obx wraps Save button state
// ==========================================================================
class _WeeklyScheduleCard extends StatelessWidget {
  final VolunteerHomeController controller;
  const _WeeklyScheduleCard({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.calendar_month_rounded, size: 17, color: _green),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Availability', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    Text('Let your manager know when you\'re free', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Each day row manages its own reactivity internally now
          ...controller.daysOfWeek.map((day) => _DayRow(day: day, controller: controller)),

          const SizedBox(height: 14),
          Obx(() => SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: controller.isSavingSchedule.value ? null : controller.saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: controller.isSavingSchedule.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================================================
// DAY ROW — FIXED: own Obx — THIS was the missing piece causing
// "selection nahi ho rahi" bug
// ==========================================================================
class _DayRow extends StatelessWidget {
  final String day;
  final VolunteerHomeController controller;
  const _DayRow({required this.day, required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entry = controller.weeklySchedule[day]!; // explicit read — required for GetX
      final isAvailable = entry['isAvailable'] as bool;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAvailable ? _green.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.toggleDayAvailability(day),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isAvailable ? _green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isAvailable ? _green : Colors.grey.shade400, width: 1.5),
                ),
                child: isAvailable ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                  color: isAvailable ? const Color(0xFF14251E) : Colors.grey[500],
                ),
              ),
            ),
            if (isAvailable)
              GestureDetector(
                onTap: () => _showTimeRangeSheet(context, day, entry),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: _green),
                      const SizedBox(width: 4),
                      Text('${entry['startTime']} - ${entry['endTime']}',
                          style: const TextStyle(fontSize: 10.5, color: _green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showTimeRangeSheet(BuildContext context, String day, Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day Availability', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePickerBtn(
                    label: 'From',
                    time: entry['startTime'],
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _green)),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        controller.updateDayTime(day, picked.format(context), entry['endTime']);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerBtn(
                    label: 'To',
                    time: entry['endTime'],
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 17, minute: 0),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _green)),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        controller.updateDayTime(day, entry['startTime'], picked.format(context));
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _TimePickerBtn extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimePickerBtn({required this.label, required this.time, required this.onTap});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _green)),
          ],
        ),
      ),
    );
  }
}