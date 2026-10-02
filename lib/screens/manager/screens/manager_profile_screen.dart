import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW — input formatters for the phone field
import 'package:get/get.dart';
import '../../../controllers/manager_profile_controller.dart';
import '../../admin/screens/shared/notifications_screen.dart';
import 'rewards_overview_screen.dart';
class ManagerProfileScreen extends StatelessWidget {
  final VoidCallback? onBack; // NEW: used when profile is shown as a dashboard tab
  const ManagerProfileScreen({super.key, this.onBack});

  static const Color _emerald = Color(0xFF0F6E4F);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerProfileController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _emerald));
          }

          final name = controller.managerData['name'] ?? 'Manager';
          final email = controller.managerData['email'] ?? '';
          final phone = controller.managerData['phone'] ?? 'Not added';
          final status = controller.managerData['status'] ?? 'active';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_emerald, _mint],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onBack ?? () => Get.back(),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Profile & Settings',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                        child: Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _emerald)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Manager', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                            const Divider(height: 16),
                            _InfoRow(icon: Icons.circle, label: 'Status',
                                value: status[0].toUpperCase() + status.substring(1),
                                valueColor: status == 'active' ? _emerald : Colors.red[700]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _SectionTitle(title: 'Account Settings'),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.edit_outlined, label: 'Edit Profile',
                        subtitle: 'Update your name and phone number',
                        color: _emerald,
                        onTap: () => _showEditSheet(context, controller),
                      ),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.lock_outline_rounded, label: 'Change Password',
                        subtitle: 'Update your account password',
                        color: const Color(0xFF2563EB),
                        onTap: () => _showPasswordSheet(context, controller),
                      ),
                      const SizedBox(height: 20),

                      _SectionTitle(title: 'Preferences'),
                      const SizedBox(height: 10),

                      _ActionCard(
                        icon: Icons.notifications_outlined, label: 'Notifications',
                        subtitle: 'View your recent activity alerts',
                        color: const Color(0xFF2563EB),
                        onTap: () => Get.to(() => const NotificationsScreen(accentColor: _emerald)),
                      ),
                      // CHANGED — "Donor Rewards" card removed (Rewards & Recognition below covers it)
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          children: [
                            // CHANGED — saved to Firestore and respected by the notification
                            // backend. The "Email Alerts" switch was removed: no emails are
                            // sent to managers, so it never did anything.
                            Obx(() => _ToggleTile(
                              icon: Icons.notifications_outlined,
                              label: 'Push Notifications',
                              subtitle: 'New donations, task updates and volunteer alerts on your phone',
                              value: controller.pushNotifications.value,
                              onChanged: controller.setPushNotifications,
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _SectionTitle(title: 'Recognition'),
                      const SizedBox(height: 10),
                      _ActionCard(
                        icon: Icons.emoji_events_outlined, label: 'Rewards & Recognition',
                        subtitle: 'View donor and volunteer achievements',
                        color: const Color(0xFFDB7C26),
                        onTap: () => Get.to(() => const RewardsOverviewScreen(),
                            transition: Transition.rightToLeft),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => _confirmLogout(context, controller),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50], borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.logout_rounded, color: Colors.red[700], size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[700])),
                                    Text('Sign out from your account', style: TextStyle(fontSize: 12, color: Colors.red[400])),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.red[400]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('DonateHub — Little Smiles Orphan Home',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      const SizedBox(height: 8),
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

  void _showEditSheet(BuildContext context, ManagerProfileController controller) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SheetField(controller: controller.nameController, label: 'Full Name *', icon: Icons.person_outline),
            const SizedBox(height: 12),
            // CHANGED — digits only, stops at 11 digits (validated again on save)
            _SheetField(
              controller: controller.phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hint: '03001234567',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: controller.isSaving.value ? null : controller.updateProfile,
                style: ElevatedButton.styleFrom(backgroundColor: _emerald, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: controller.isSaving.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showPasswordSheet(BuildContext context, ManagerProfileController controller) {
    controller.currentPasswordController.clear();
    controller.newPasswordController.clear();
    controller.confirmPasswordController.clear();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SheetField(controller: controller.currentPasswordController, label: 'Current Password *', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 12),
            _SheetField(controller: controller.newPasswordController, label: 'New Password *', icon: Icons.lock_reset_outlined, isPassword: true, hint: 'Min 8 characters'),
            const SizedBox(height: 12),
            _SheetField(controller: controller.confirmPasswordController, label: 'Confirm New Password *', icon: Icons.check_circle_outline, isPassword: true),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: controller.isSaving.value ? null : controller.changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: controller.isSaving.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Password'),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, ManagerProfileController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); controller.logout(); },
            child: Text('Logout', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});
  static const Color _emerald = Color(0xFF0F6E4F);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: _emerald), const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])), const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF14251E))),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title; const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5)));
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final String subtitle; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,3))]),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon; final String label; final bool value; final ValueChanged<bool> onChanged;
  final String? subtitle; // NEW — short explanation of what the switch controls
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged, this.subtitle});
  static const Color _emerald = Color(0xFF0F6E4F);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: _emerald), const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13.5)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: _emerald),
      ]),
    );
  }
}

class _SheetField extends StatefulWidget {
  final TextEditingController controller; final String label; final IconData icon;
  final bool isPassword; final TextInputType keyboardType;
  final String? hint; // NEW
  final List<TextInputFormatter>? inputFormatters; // NEW
  const _SheetField({required this.controller, required this.label, required this.icon, this.isPassword = false, this.keyboardType = TextInputType.text, this.hint, this.inputFormatters});
  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: widget.controller, obscureText: widget.isPassword && _obscure, keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: Icon(widget.icon, size: 18, color: Colors.grey[500]),
          suffixIcon: widget.isPassword
              ? IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey[400]),
              onPressed: () => setState(() => _obscure = !_obscure))
              : null,
          filled: true, fillColor: const Color(0xFFF4FAF7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F6E4F))),
        ),
      ),
    ]);
  }
}