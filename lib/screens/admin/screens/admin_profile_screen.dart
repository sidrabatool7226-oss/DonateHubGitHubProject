import 'package:donatehub_android_studio/screens/admin/screens/shared/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/profile_controller.dart';
import '../../../widgets/appearance_selector_sheet.dart';
import '../../shared/notifications_screen.dart';
import '../../shared/donors_list_screen.dart';
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header with back button ─────────────────────────
                _ProfileHeader(controller: controller),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Info card
                      _InfoCard(controller: controller),
                      const SizedBox(height: 16),

                      // Account Settings section
                      _SectionTitle(title: 'Account Settings'),
                      const SizedBox(height: 10),

                      _ActionCard(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        subtitle: 'Update name and phone number',
                        color: _green,
                        onTap: () =>
                            _showEditSheet(context, controller),
                      ),

                      const SizedBox(height: 10),

                      _ActionCard(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        subtitle: 'Update your account password',
                        color: const Color(0xFF1565C0),
                        onTap: () =>
                            _showPasswordSheet(context, controller),
                      ),

                      const SizedBox(height: 10),

                      // ── NEW: Appearance ────────────────────────────
                      _ActionCard(
                        icon: Icons.dark_mode_outlined,
                        label: 'Appearance',
                        subtitle: 'Light, Dark or System Default',
                        color: const Color(0xFF6A1B9A),
                        onTap: () =>
                            AppearanceSelectorSheet.show(
                              context,
                              accentColor: _green,
                            ),
                      ),

                      const SizedBox(height: 10),

                      // ── Notifications ─────────────────────────────
                      _ActionCard(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle:
                        'View your recent activity alerts',
                        color: const Color(0xFF1565C0),
                        onTap: () => Get.to(
                              () => const NotificationsScreen(
                            accentColor: _green,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Management section
                      _SectionTitle(title: 'Management'),
                      const SizedBox(height: 10),

                      _ActionCard(
                        icon: Icons.feedback_outlined,
                        label: 'View Feedback',
                        subtitle:
                        'Manage donor and volunteer feedback',
                        color: const Color(0xFF00838F),
                        onTap: () =>
                            _showFeedbackSheet(
                              context,
                              controller,
                            ),
                      ),
                      _ActionCard(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Donor Rewards',
                        subtitle: 'View donor reward points and badges',
                        color: const Color(0xFFDB7C26),
                        onTap: () => Get.to(() => const DonorsListScreen(accentColor: _green)),
                      ),
                      const SizedBox(height: 10),

                      const SizedBox(height: 20),

                      // Logout
                      _LogoutButton(
                        controller: controller,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'DonateHub v1.0 — Little Smiles Orphan Home',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),

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

  void _showEditSheet(
      BuildContext context,
      ProfileController controller,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) =>
          _EditProfileSheet(
            controller: controller,
          ),
    );
  }

  void _showPasswordSheet(
      BuildContext context,
      ProfileController controller,
      ) {
    controller.currentPasswordController.clear();
    controller.newPasswordController.clear();
    controller.confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) =>
          _ChangePasswordSheet(
            controller: controller,
          ),
    );
  }

  void _showFeedbackSheet(
      BuildContext context,
      ProfileController controller,
      ) {
    controller.loadFeedback();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) =>
          _FeedbackSheet(
            controller: controller,
          ),
    );
  }
}

// ==========================================================================
// PROFILE HEADER
// ==========================================================================

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;

  const _ProfileHeader({
    required this.controller,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  static const Color _lightGreen =
  Color(0xFF2D8A52);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final name =
          controller.adminData['name'] ??
              'Admin';

      final email =
          controller.adminData['email'] ??
              '';

      final initial =
      name.isNotEmpty
          ? name[0].toUpperCase()
          : 'A';

      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          28,
        ),
        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _green,
              _lightGreen,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Back button row
            Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons
                          .arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const Text(
                  'My Profile',
                  style:
                  TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration:
              BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white
                      .withOpacity(0.5),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style:
                  const TextStyle(
                    fontSize: 32,
                    fontWeight:
                    FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              name,
              style:
              const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              email,
              style:
              TextStyle(
                color: Colors.white
                    .withOpacity(0.8),
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child:
              const Text(
                'Administrator',
                style:
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ==========================================================================
// INFO CARD
// ==========================================================================

class _InfoCard extends StatelessWidget {
  final ProfileController controller;

  const _InfoCard({
    required this.controller,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final phone =
          controller.adminData['phone'] ??
              'Not added';

      final status =
          controller.adminData['status'] ??
              'active';

      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(16),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 8,
              offset:
              const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style:
              TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            _InfoRow(
              icon:
              Icons.phone_outlined,
              label: 'Phone',
              value: phone,
            ),

            const Divider(
              height: 16,
            ),

            _InfoRow(
              icon: Icons
                  .admin_panel_settings_outlined,
              label: 'Role',
              value: 'Administrator',
            ),

            const Divider(
              height: 16,
            ),

            _InfoRow(
              icon: Icons.circle,
              label: 'Status',
              value:
              status[0]
                  .toUpperCase() +
                  status.substring(1),
              valueColor:
              status == 'active'
                  ? _green
                  : Colors.red[700],
            ),
          ],
        ),
      );
    });
  }
}

// ==========================================================================
// INFO ROW
// ==========================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: _green,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          label,
          style:
          TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style:
          TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color:
            valueColor ??
                const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// SECTION TITLE
// ==========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      Alignment.centerLeft,
      child: Text(
        title,
        style:
        TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ==========================================================================
// ACTION CARD
// ==========================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(14),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 6,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color:
                color.withOpacity(0.1),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                    TextStyle(
                      fontSize: 12,
                      color:
                      Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size: 14,
              color:
              Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// LOGOUT BUTTON
// ==========================================================================

class _LogoutButton extends StatelessWidget {
  final ProfileController controller;

  const _LogoutButton({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              title:
              const Text(
                'Logout',
              ),
              content:
              const Text(
                'Are you sure you want to logout?',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                      ),
                  child:
                  const Text(
                    'Cancel',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                    controller.logout();
                  },
                  child:
                  Text(
                    'Logout',
                    style:
                    TextStyle(
                      color:
                      Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
      ),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(14),
        decoration:
        BoxDecoration(
          color:
          Colors.red[50],
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border:
          Border.all(
            color:
            Colors.red[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color:
                Colors.red[100],
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                Icons.logout_rounded,
                color:
                Colors.red[700],
                size: 20,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style:
                    TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Colors.red[700],
                    ),
                  ),
                  Text(
                    'Sign out from your account',
                    style:
                    TextStyle(
                      fontSize: 12,
                      color:
                      Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons
                  .arrow_forward_ios_rounded,
              size: 14,
              color:
              Colors.red[400],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// EDIT PROFILE SHEET
// ==========================================================================

class _EditProfileSheet
    extends StatelessWidget {
  final ProfileController controller;

  const _EditProfileSheet({
    required this.controller,
  });

  static const Color _green =
  Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context)
            .viewInsets
            .bottom +
            20,
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration:
              BoxDecoration(
                color:
                Colors.grey[300],
                borderRadius:
                BorderRadius.circular(
                  2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Edit Profile',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _SheetField(
            controller:
            controller.nameController,
            label:
            'Full Name *',
            hint:
            'Enter your name',
            icon:
            Icons.person_outline,
          ),

          const SizedBox(
            height: 12,
          ),

          _SheetField(
            controller:
            controller.phoneController,
            label:
            'Phone Number',
            hint:
            'e.g. 0300-1234567',
            icon:
            Icons.phone_outlined,
            keyboardType:
            TextInputType.phone,
          ),

          const SizedBox(
            height: 20,
          ),

          Obx(
                () => SizedBox(
              width:
              double.infinity,
              height: 48,
              child:
              ElevatedButton(
                onPressed:
                controller
                    .isSaving
                    .value
                    ? null
                    : controller
                    .updateProfile,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  _green,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child: controller
                    .isSaving
                    .value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    color:
                    Colors.white,
                    strokeWidth:
                    2,
                  ),
                )
                    : const Text(
                  'Save Changes',
                  style:
                  TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CHANGE PASSWORD SHEET
// ==========================================================================

class _ChangePasswordSheet
    extends StatelessWidget {
  final ProfileController controller;

  const _ChangePasswordSheet({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context)
            .viewInsets
            .bottom +
            20,
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration:
              BoxDecoration(
                color:
                Colors.grey[300],
                borderRadius:
                BorderRadius.circular(
                  2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Change Password',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            'Enter your current password to continue',
            style:
            TextStyle(
              fontSize: 12,
              color:
              Colors.grey[500],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _SheetField(
            controller: controller
                .currentPasswordController,
            label:
            'Current Password *',
            hint:
            'Enter current password',
            icon:
            Icons.lock_outline,
            isPassword: true,
          ),

          const SizedBox(
            height: 12,
          ),

          _SheetField(
            controller: controller
                .newPasswordController,
            label:
            'New Password *',
            hint:
            'Min 6 characters',
            icon:
            Icons.lock_reset_outlined,
            isPassword: true,
          ),

          const SizedBox(
            height: 12,
          ),

          _SheetField(
            controller: controller
                .confirmPasswordController,
            label:
            'Confirm New Password *',
            hint:
            'Re-enter new password',
            icon:
            Icons.check_circle_outline,
            isPassword: true,
          ),

          const SizedBox(
            height: 20,
          ),

          Obx(
                () => SizedBox(
              width:
              double.infinity,
              height: 48,
              child:
              ElevatedButton(
                onPressed:
                controller
                    .isSaving
                    .value
                    ? null
                    : controller
                    .changePassword,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  const Color(
                    0xFF1565C0,
                  ),
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child: controller
                    .isSaving
                    .value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    color:
                    Colors.white,
                    strokeWidth:
                    2,
                  ),
                )
                    : const Text(
                  'Update Password',
                  style:
                  TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// FEEDBACK SHEET
// ==========================================================================

class _FeedbackSheet
    extends StatelessWidget {
  final ProfileController controller;

  const _FeedbackSheet({
    required this.controller,
  });

  static const Color _teal =
  Color(0xFF00838F);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder:
          (context, scrollController) {
        return Container(
          decoration:
          const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(
                24,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 12,
                  bottom: 8,
                ),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.grey[300],
                    borderRadius:
                    BorderRadius.circular(
                      2,
                    ),
                  ),
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.feedback_outlined,
                      color: _teal,
                      size: 20,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(
                      'Feedback Management',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                          () => Text(
                        '${controller.filteredFeedback.length} items',
                        style:
                        TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: TextField(
                  onChanged:
                      (val) => controller
                      .searchQuery
                      .value = val,
                  style:
                  const TextStyle(
                    fontSize: 13,
                  ),
                  decoration:
                  InputDecoration(
                    hintText:
                    'Search feedback...',
                    hintStyle:
                    TextStyle(
                      color:
                      Colors.grey[400],
                      fontSize: 13,
                    ),
                    prefixIcon:
                    const Icon(
                      Icons.search,
                      size: 18,
                      color:
                      Colors.grey,
                    ),
                    filled: true,
                    fillColor:
                    const Color(
                      0xFFF4F6F8,
                    ),
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              SizedBox(
                height: 34,
                child: Obx(() {
                  final selected =
                      controller
                          .selectedFeedbackFilter
                          .value;

                  return SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: controller
                          .feedbackFilters
                          .map((filter) {
                        final isSelected =
                            selected ==
                                filter;

                        return GestureDetector(
                          onTap: () =>
                          controller
                              .selectedFeedbackFilter
                              .value =
                              filter,
                          child: Container(
                            margin:
                            const EdgeInsets
                                .only(
                              right: 8,
                            ),
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration:
                            BoxDecoration(
                              color: isSelected
                                  ? _teal
                                  : const Color(
                                0xFFF4F6F8,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              filter,
                              style:
                              TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),

              const SizedBox(
                height: 10,
              ),

              const Divider(
                height: 1,
              ),

              Expanded(
                child: Obx(() {
                  if (controller
                      .feedbackLoading
                      .value) {
                    return const Center(
                      child:
                      CircularProgressIndicator(
                        color: _teal,
                      ),
                    );
                  }

                  final list = controller
                      .filteredFeedback;

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Icon(
                            Icons
                                .feedback_outlined,
                            size: 48,
                            color:
                            Colors.grey[300],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'No feedback found',
                            style:
                            TextStyle(
                              color:
                              Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller:
                    scrollController,
                    padding:
                    const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                    list.length,
                    itemBuilder:
                        (context, index) {
                      return _FeedbackCard(
                        data:
                        list[index],
                        controller:
                        controller,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================================
// FEEDBACK CARD
// ==========================================================================

class _FeedbackCard
    extends StatelessWidget {
  final Map<String, dynamic> data;
  final ProfileController controller;

  const _FeedbackCard({
    required this.data,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        data['userName'] ?? 'Anonymous';

    final String message =
        data['message'] ?? '';

    final String role =
        data['userRole'] ?? 'donor';

    final int rating =
        data['rating'] ?? 0;

    final bool isReviewed =
        data['isReviewed'] ?? false;

    final String docId =
        data['docId'] ?? '';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: isReviewed
              ? Colors.green
              .withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 6,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                role == 'donor'
                    ? const Color(
                  0xFFE8F5E9,
                )
                    : const Color(
                  0xFFE3F2FD,
                ),
                child:
                Text(
                  name[0]
                      .toUpperCase(),
                  style:
                  TextStyle(
                    color:
                    role == 'donor'
                        ? const Color(
                      0xFF1B6B3A,
                    )
                        : const Color(
                      0xFF1565C0,
                    ),
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      name,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration:
                      BoxDecoration(
                        color: role ==
                            'donor'
                            ? const Color(
                          0xFFE8F5E9,
                        )
                            : const Color(
                          0xFFE3F2FD,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          6,
                        ),
                      ),
                      child:
                      Text(
                        role[0]
                            .toUpperCase() +
                            role.substring(
                                1),
                        style:
                        TextStyle(
                          fontSize: 10,
                          color: role ==
                              'donor'
                              ? const Color(
                            0xFF1B6B3A,
                          )
                              : const Color(
                            0xFF1565C0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isReviewed)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.green[50],
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .check_circle,
                        size: 12,
                        color:
                        Colors.green[
                        700],
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        'Reviewed',
                        style:
                        TextStyle(
                          fontSize: 10,
                          color:
                          Colors.green[
                          700],
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          if (rating > 0) ...[
            Row(
              children:
              List.generate(
                5,
                    (i) => Icon(
                  i < rating
                      ? Icons
                      .star_rounded
                      : Icons
                      .star_outline_rounded,
                  size: 16,
                  color:
                  Colors.amber[600],
                ),
              ),
            ),
            const SizedBox(
              height: 6,
            ),
          ],

          Text(
            message,
            style:
            TextStyle(
              fontSize: 13,
              color:
              Colors.grey[700],
              height: 1.4,
            ),
          ),

          if (!isReviewed &&
              docId.isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: () =>
                  controller
                      .markAsReviewed(
                    docId,
                  ),
              child:
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    8,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children:
                  const [
                    Icon(
                      Icons
                          .check_rounded,
                      size: 14,
                      color:
                      Color(
                        0xFF1B6B3A,
                      ),
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      'Mark as Reviewed',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF1B6B3A,
                        ),
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// SHEET FIELD
// ==========================================================================

class _SheetField
    extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType =
        TextInputType.text,
  });

  @override
  State<_SheetField> createState() =>
      _SheetFieldState();
}

class _SheetFieldState
    extends State<_SheetField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        TextField(
          controller:
          widget.controller,
          obscureText:
          widget.isPassword &&
              _obscure,
          keyboardType:
          widget.keyboardType,
          style:
          const TextStyle(
            fontSize: 13,
          ),
          decoration:
          InputDecoration(
            hintText:
            widget.hint,
            hintStyle:
            TextStyle(
              color:
              Colors.grey[400],
              fontSize: 13,
            ),
            prefixIcon:
            Icon(
              widget.icon,
              size: 18,
              color:
              Colors.grey[500],
            ),
            suffixIcon:
            widget.isPassword
                ? IconButton(
              icon:
              Icon(
                _obscure
                    ? Icons
                    .visibility_off_outlined
                    : Icons
                    .visibility_outlined,
                size: 18,
                color:
                Colors.grey[400],
              ),
              onPressed:
                  () =>
                  setState(
                        () => _obscure =
                    !_obscure,
                  ),
            )
                : null,
            filled: true,
            fillColor:
            const Color(
              0xFFF4F6F8,
            ),
            contentPadding:
            const EdgeInsets
                .symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                10,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey[300]!,
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                10,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey[300]!,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                10,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(
                  0xFF1B6B3A,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// MENU CARD / MENU ITEM
// ==========================================================================

class _MenuCard
    extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuCard({
    required this.items,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.05,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children:
        items.asMap().entries.map(
              (e) {
            final index =
                e.key;
            final item =
                e.value;

            return Column(
              children: [
                ListTile(
                  leading:
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                    BoxDecoration(
                      color: item
                          .color
                          .withOpacity(
                        0.1,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color:
                      item.color,
                      size: 18,
                    ),
                  ),
                  title:
                  Text(
                    item.label,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight
                          .w500,
                    ),
                  ),
                  trailing:
                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 14,
                    color:
                    Colors.grey[400],
                  ),
                  onTap:
                  item.onTap,
                ),
                if (index <
                    items.length -
                        1)
                  Divider(
                    height: 1,
                    indent: 66,
                    color:
                    Colors.grey[100],
                  ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}