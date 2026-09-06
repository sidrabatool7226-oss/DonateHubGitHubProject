// volunteer_profile_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/appearance_selector_sheet.dart';
import '../../admin/screens/shared/notifications_screen.dart';
import '../../shared/notifications_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/help_support_screen.dart';

class VolunteerProfileTab extends StatefulWidget {
  const VolunteerProfileTab({super.key});

  @override
  State<VolunteerProfileTab> createState() =>
      _VolunteerProfileTabState();
}

class _VolunteerProfileTabState extends State<VolunteerProfileTab> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data =
            snapshot.data?.data() as Map<String, dynamic>?;

            final name = data?['name'] ?? 'Volunteer';
            final phone = data?['phone'] ?? '';
            final cnic = data?['cnic'] ?? '';
            final stage = data?['verificationStage'] ?? 'Pending';
            final categories =
                (data?['categories'] as List?) ?? [];
            final points = data?['rewardPoints'] ?? 0;
            final isVerified = stage == 'Verified';

            if (!_isEditing) {
              _nameController.text = name.toString();
              _phoneController.text = phone.toString();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      32,
                    ),
                    decoration: const BoxDecoration(
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
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.toString().isNotEmpty
                                  ? name.toString()[0].toUpperCase()
                                  : 'V',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.3),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                isVerified
                                    ? '✓ Verified Volunteer'
                                    : stage.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$points pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    color: _green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Profile Information',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _isSaving
                                        ? null
                                        : () {
                                      if (_isEditing) {
                                        _saveProfile(uid);
                                      } else {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isEditing
                                            ? _green
                                            : const Color(0xFFE8F5E9),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _isEditing ? 'Save' : 'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isEditing
                                              ? Colors.white
                                              : _green,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _ProfileField(
                                label: 'Full Name',
                                controller: _nameController,
                                enabled: _isEditing,
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Email',
                                controller:
                                TextEditingController(
                                  text: email,
                                ),
                                enabled: false,
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Phone',
                                controller: _phoneController,
                                enabled: _isEditing,
                                icon: Icons.phone_outlined,
                                keyboardType:
                                TextInputType.phone,
                              ),
                              if (cnic.toString().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _ProfileField(
                                  label: 'CNIC',
                                  controller:
                                  TextEditingController(
                                    text: cnic.toString(),
                                  ),
                                  enabled: false,
                                  icon: Icons.badge_outlined,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (categories.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.category_rounded,
                                      color: _green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'My Roles',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                  categories.map((c) {
                                    return Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFFE8F5E9),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        c.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _green,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        _MenuCard(
                          items: [
                            _MenuItem(
                              icon:
                              Icons.notifications_outlined,
                              label: 'Notifications',
                              color:
                              const Color(0xFF1565C0),
                              onTap: () => Get.to(
                                    () =>
                                const NotificationsScreen(
                                  accentColor: _green,
                                ),
                              ),
                            ),

                            _MenuItem(
                              icon: Icons.lock_outline,
                              label: 'Change Password',
                              color:
                              const Color(0xFF6A1B9A),
                              onTap: () =>
                                  _showChangePassword(context),
                            ),

                            _MenuItem(
                              icon: Icons.dark_mode_outlined,
                              label: 'Appearance',
                              color:
                              const Color(0xFF6A1B9A),
                              onTap: () =>
                                  AppearanceSelectorSheet.show(
                                    context,
                                    accentColor: _green,
                                  ),
                            ),

                            _MenuItem(
                              icon:
                              Icons.help_outline_rounded,
                              label: 'Help & Support',
                              color:
                              const Color(0xFF00838F),
                              onTap: () => Get.to(
                                    () =>
                                const HelpSupportScreen(),
                              ),
                            ),

                            _MenuItem(
                              icon: Icons.info_outline_rounded,
                              label: 'About Us',
                              color:
                              const Color(0xFF1B6B3A),
                              onTap: () => Get.to(
                                    () =>
                                const AboutUsScreen(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        GestureDetector(
                          onTap: () =>
                              _confirmLogout(context),
                          child: Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration:
                                  BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w600,
                                          color:
                                          Colors.red[700],
                                        ),
                                      ),
                                      Text(
                                        'Sign out from your account',
                                        style: TextStyle(
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
                                  color: Colors.red[400],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveProfile(String uid) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _isEditing = false);

      Get.snackbar(
        'Updated',
        'Profile updated successfully!',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to update profile. Please try again.',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content:
        const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (r) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    bool isSaving = false;

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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _ProfileField(
                label: 'Current Password',
                controller: currentPw,
                enabled: true,
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 10),

              _ProfileField(
                label: 'New Password',
                controller: newPw,
                enabled: true,
                icon: Icons.lock_reset_outlined,
                isPassword: true,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (currentPw.text.trim().isEmpty ||
                        newPw.text.trim().isEmpty) {
                      Get.snackbar(
                        'Required',
                        'Please enter both passwords.',
                        snackPosition:
                        SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    if (newPw.text.trim().length < 6) {
                      Get.snackbar(
                        'Invalid Password',
                        'New password must contain at least 6 characters.',
                        snackPosition:
                        SnackPosition.BOTTOM,
                      );
                      return;
                    }

                    setSheetState(
                          () => isSaving = true,
                    );

                    try {
                      final user =
                      FirebaseAuth.instance.currentUser!;

                      final cred =
                      EmailAuthProvider.credential(
                        email: user.email!,
                        password:
                        currentPw.text.trim(),
                      );

                      await user
                          .reauthenticateWithCredential(
                        cred,
                      );

                      await user.updatePassword(
                        newPw.text.trim(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }

                      Get.snackbar(
                        'Success',
                        'Password changed!',
                        backgroundColor:
                        Colors.green[50],
                        colorText:
                        Colors.green[700],
                        snackPosition:
                        SnackPosition.BOTTOM,
                        margin:
                        const EdgeInsets.all(16),
                      );
                    } on FirebaseAuthException catch (e) {
                      String message =
                          'Unable to change password.';

                      if (e.code ==
                          'wrong-password') {
                        message =
                        'Current password is incorrect.';
                      } else if (e.code ==
                          'weak-password') {
                        message =
                        'The new password is too weak.';
                      } else if (e.code ==
                          'requires-recent-login') {
                        message =
                        'Please login again and try.';
                      }

                      Get.snackbar(
                        'Error',
                        message,
                        snackPosition:
                        SnackPosition.BOTTOM,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Unable to change password.',
                        snackPosition:
                        SnackPosition.BOTTOM,
                      );
                    } finally {
                      setSheetState(
                            () => isSaving = false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Password',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_ProfileField> createState() =>
      _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText:
          widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(
              widget.icon,
              size: 18,
              color: Colors.grey[500],
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
            )
                : null,
            filled: true,
            fillColor: widget.enabled
                ? const Color(0xFFF4F6F8)
                : Colors.grey[100],
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1B6B3A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (e) {
            final index = e.key;
            final item = e.value;

            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                      item.color.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  onTap: item.onTap,
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 66,
                    color: Colors.grey[100],
                  ),
              ],
            );
          },
        )
            .toList(),
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