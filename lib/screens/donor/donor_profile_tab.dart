import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin/screens/shared/notifications_screen.dart';
import 'contact_us_screen.dart';
import 'donor_feedback_tab.dart'; // NEW
import '../../widgets/appearance_selector_sheet.dart';
import '../shared/notifications_screen.dart'; // NEW
import 'about_us_screen.dart';
import 'help_support_screen.dart';
class DonorProfileTab extends StatefulWidget {
  const DonorProfileTab({super.key});

  @override
  State<DonorProfileTab> createState() =>
      _DonorProfileTabState();
}

class _DonorProfileTabState
    extends State<DonorProfileTab> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String? _phoneError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    final email =
        FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data()
            as Map<String, dynamic>?;
            final name = data?['name'] ?? 'Donor';
            final phone = data?['phone'] ?? '';

            if (!_isEditing) {
              _nameController.text = name;
              _phoneController.text = phone;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Profile Header ────────────────
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.fromLTRB(
                        20, 24, 20, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _green,
                          Color(0xFF2D8A52)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
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
                              name.isNotEmpty
                                  ? name[0]
                                  .toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight:
                                FontWeight.bold,
                                color: _green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
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
                            color: Colors.white
                                .withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Donor badge
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore
                              .instance
                              .collection('donors')
                              .doc(uid)
                              .snapshots(),
                          builder: (ctx, donorSnap) {
                            final donorData =
                            donorSnap.data?.data()
                            as Map<String,
                                dynamic>?;
                            final pts =
                                donorData?['rewardPoints'] ??
                                    0;
                            return Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                              ),
                              child: Text(
                                '$pts pts • ${_getBadge(pts)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Edit Profile ─────────────
                        Container(
                          padding:
                          const EdgeInsets.all(16),
                          decoration: BoxDecoration(
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
                              Row(
                                children: [
                                  const Icon(
                                      Icons
                                          .person_outline_rounded,
                                      color: _green,
                                      size: 18),
                                  const SizedBox(
                                      width: 6),
                                  const Text(
                                    'Profile Information',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      if (_isEditing) {
                                        _saveProfile(
                                            uid);
                                      } else {
                                        setState(() {
                                          _isEditing = true;
                                          _phoneError = null;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal:
                                          12,
                                          vertical:
                                          5),
                                      decoration:
                                      BoxDecoration(
                                        color: _isEditing
                                            ? _green
                                            : const Color(
                                            0xFFE8F5E9),
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            20),
                                      ),
                                      child: Text(
                                        _isEditing
                                            ? 'Save'
                                            : 'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isEditing
                                              ? Colors
                                              .white
                                              : _green,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _ProfileField(
                                label: 'Full Name',
                                controller:
                                _nameController,
                                enabled: _isEditing,
                                icon:
                                Icons.person_outline,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Email',
                                controller:
                                TextEditingController(
                                    text: email),
                                enabled: false,
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'Phone',
                                controller:
                                _phoneController,
                                enabled: _isEditing,
                                icon:
                                Icons.phone_outlined,
                                keyboardType:
                                TextInputType.phone,
                                maxLength: 16,
                                errorText: _phoneError,
                                onChanged: (value) {
                                  if (_phoneError != null) {
                                    setState(() {
                                      _phoneError = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Menu items ────────────────
                        _MenuCard(
                          items: [
                            _MenuItem(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              color: const Color(0xFF1565C0),
                              onTap: () => Get.to(() => const NotificationsScreen(accentColor: _green)),
                            ),
                            _MenuItem(
                              icon: Icons.lock_outline,
                              label: 'Change Password',
                              color: const Color(
                                  0xFF6A1B9A),
                              onTap: () =>
                                  _showChangePassword(
                                      context),
                            ),
                            _MenuItem(
                              icon: Icons.dark_mode_outlined,
                              label: 'Appearance',
                              color: const Color(0xFF6A1B9A),
                              onTap: () => AppearanceSelectorSheet.show(context, accentColor: _green),
                            ),
                            // NEW — permanent, always-available feedback
                            _MenuItem(
                              icon: Icons.star_outline_rounded,
                              label: 'Give Feedback',
                              color: const Color(0xFFFFA000),
                              onTap: () => Get.to(() => const DonorFeedbackTab()),
                            ),
                            _MenuItem(
                              icon: Icons
                                  .help_outline_rounded,
                              label: 'Help & Support',
                              color: const Color(
                                  0xFF00838F),
                              onTap: () {},
                            ),
                            _MenuItem(
                              icon: Icons.contact_support_outlined,
                              label: 'Contact Us',
                              color: const Color(0xFFE65100),
                              onTap: () => Get.to(() => const ContactUsScreen()),
                            ),
                            _MenuItem(
                              icon: Icons.info_outline_rounded,
                              label: 'About Us',
                              color: const Color(0xFF37474F),
                              onTap: () {
                                Get.snackbar(
                                  'Coming Soon',
                                  'About Us page is on the way.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Logout ────────────────────
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
                              BorderRadius.circular(
                                  14),
                              border: Border.all(
                                  color: Colors.red[200]!),
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
                                    BorderRadius
                                        .circular(10),
                                  ),
                                  child: Icon(
                                      Icons
                                          .logout_rounded,
                                      color:
                                      Colors.red[700],
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight
                                              .w600,
                                          color: Colors
                                              .red[700],
                                        ),
                                      ),
                                      Text(
                                        'Sign out from your account',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors
                                              .red[400],
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
                                    Colors.red[400]),
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
    final phoneError =
    _validatePhoneNumber(_phoneController.text);

    if (phoneError != null) {
      setState(() {
        _phoneError = phoneError;
      });

      Get.snackbar(
        'Invalid Phone Number',
        phoneError,
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      return;
    }

    setState(() {
      _phoneError = null;
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(
          _nameController.text.trim());

      setState(() {
        _isEditing = false;
        _phoneError = null;
      });

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
        'Could not update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validatePhoneNumber(String value) {
    final phone = value
        .trim()
        .replaceAll(RegExp(r'[\s\-()]'), '');

    if (phone.isEmpty) {
      return 'Phone number is required.';
    }

    // Pakistan local format: 03XXXXXXXXX
    if (RegExp(r'^03\d{9}$').hasMatch(phone)) {
      return null;
    }

    // Pakistan international format: +92XXXXXXXXXX
    if (RegExp(r'^\+92\d{10}$').hasMatch(phone)) {
      return null;
    }

    // General international format (E.164-style).
    if (RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(phone)) {
      return null;
    }

    return 'Enter a valid mobile number, e.g. 03001234567 or +923001234567.';
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Get.offAllNamed('/login');
            },
            child: Text('Logout',
                style:
                TextStyle(color: Colors.red[700])),
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
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
            MediaQuery.of(ctx).viewInsets.bottom +
                20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius:
                    BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Password',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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
                    setSheetState(
                            () => isSaving = true);
                    try {
                      final user = FirebaseAuth
                          .instance.currentUser!;
                      final cred =
                      EmailAuthProvider.credential(
                        email: user.email!,
                        password:
                        currentPw.text.trim(),
                      );
                      await user
                          .reauthenticateWithCredential(
                          cred);
                      await user.updatePassword(
                          newPw.text.trim());
                      Navigator.pop(ctx);
                      Get.snackbar(
                        'Success',
                        'Password changed!',
                        backgroundColor:
                        Colors.green[50],
                        colorText:
                        Colors.green[700],
                        snackPosition:
                        SnackPosition.BOTTOM,
                        margin: const EdgeInsets
                            .all(16),
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Current password incorrect',
                        snackPosition:
                        SnackPosition.BOTTOM,
                      );
                    } finally {
                      setSheetState(() =>
                      isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF1B6B3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBadge(int pts) {
    if (pts >= 500) return 'Platinum 💎';
    if (pts >= 200) return 'Gold 🥇';
    if (pts >= 100) return 'Silver 🥈';
    if (pts >= 50) return 'Bronze 🥉';
    return 'New Donor 🌱';
  }
}

// ==========================================================================
// PROFILE FIELD
// ==========================================================================
class _ProfileField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  @override
  State<_ProfileField> createState() =>
      _ProfileFieldState();
}

class _ProfileFieldState
    extends State<_ProfileField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            errorText: widget.errorText,
            counterText: widget.maxLength != null ? '' : null,
            prefixIcon: Icon(widget.icon,
                size: 18, color: Colors.grey[500]),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons
                    .visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
              onPressed: () => setState(
                      () => _obscure = !_obscure),
            )
                : null,
            filled: true,
            fillColor: widget.enabled
                ? const Color(0xFFF4F6F8)
                : Colors.grey[100],
            contentPadding:
            const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1B6B3A)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// MENU CARD
// ==========================================================================
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color
                        .withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon,
                      color: item.color, size: 18),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[400]),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                    height: 1,
                    indent: 66,
                    color: Colors.grey[100]),
            ],
          );
        }).toList(),
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