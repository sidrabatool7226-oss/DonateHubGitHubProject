import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/user_management_controller.dart';

class AdminUserManagementTab extends StatelessWidget {
  const AdminUserManagementTab({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserManagementController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () =>
                  _showCreateManagerSheet(context, controller),
              icon: const Icon(Icons.add_rounded,
                  color: _green, size: 18),
              label: const Text(
                'Add Manager',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Stats Row ──────────────────────────────────────────────
          _StatsRow(controller: controller),

          // ── Filter Tabs ────────────────────────────────────────────
          _FilterTabs(controller: controller),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: Obx(() => StreamBuilder<QuerySnapshot>(
              stream: controller.usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: _green),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(
                    filter: controller.selectedFilter.value,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;
                    return _UserCard(
                      docId: doc.id,
                      data: data,
                      controller: controller,
                    );
                  },
                );
              },
            )),
          ),
        ],
      ),
    );
  }

  void _showCreateManagerSheet(
      BuildContext context,
      UserManagementController controller) {
    controller.clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _CreateManagerSheet(controller: controller),
    );
  }
}

// ==========================================================================
// STATS ROW
// ==========================================================================
class _StatsRow extends StatelessWidget {
  final UserManagementController controller;
  const _StatsRow({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _StatChip(
            label: 'Managers',
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'manager')
                .snapshots(),
            color: _green,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Donors',
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'donor')
                .snapshots(),
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Volunteers',
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'volunteer')
                .snapshots(),
            color: const Color(0xFF00838F),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot> stream;
  final Color color;

  const _StatChip({
    required this.label,
    required this.stream,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================================================
// FILTER TABS
// ==========================================================================
class _FilterTabs extends StatelessWidget {
  final UserManagementController controller;
  const _FilterTabs({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Managers', 'value': 'manager'},
    {'label': 'Donors', 'value': 'donor'},
    {'label': 'Volunteers', 'value': 'volunteer'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: Obx(() => Row(
        children: _tabs.map((tab) {
          final isSelected =
              controller.selectedFilter.value ==
                  tab['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => controller
                  .selectedFilter.value = tab['value'],
              child: Column(
                children: [
                  Text(
                    tab['label'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? _green
                          : Colors.grey[400],
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20),
                    color: isSelected
                        ? _green
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      )),
    );
  }
}

// ==========================================================================
// USER CARD
// ==========================================================================
class _UserCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final UserManagementController controller;

  const _UserCard({
    required this.docId,
    required this.data,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Unknown';
    final String email = data['email'] ?? '';
    final String role = data['role'] ?? '';
    final String status = data['status'] ?? 'active';
    final bool isActive = status == 'active';
    final String stage =
        data['verificationStage'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: _roleColor(role).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: _roleColor(role),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (role == 'volunteer' && stage.isNotEmpty)
                  Text(
                    'Verification: $stage',
                    style: TextStyle(
                      fontSize: 11,
                      color: stage == 'Verified'
                          ? _green
                          : Colors.orange[700],
                    ),
                  ),
              ],
            ),
          ),

          // Status + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Only show actions for managers
              if (role == 'manager') ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Edit
                    GestureDetector(
                      onTap: () => _showEditSheet(
                          context, data, docId),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Deactivate/Activate
                    GestureDetector(
                      onTap: () =>
                          controller.toggleManagerStatus(
                            docId,
                            isActive,
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline,
                          size: 14,
                          color: isActive
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager': return const Color(0xFF1B6B3A);
      case 'donor': return const Color(0xFF1565C0);
      case 'volunteer': return const Color(0xFF00838F);
      default: return Colors.grey;
    }
  }

  void _showEditSheet(BuildContext context,
      Map<String, dynamic> data, String docId) {
    final controller =
    Get.find<UserManagementController>();
    controller.editNameController.text =
        data['name'] ?? '';
    controller.editPhoneController.text =
        data['phone'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditManagerSheet(
        docId: docId,
        controller: controller,
      ),
    );
  }
}

// ==========================================================================
// CREATE MANAGER SHEET
// ==========================================================================
class _CreateManagerSheet extends StatelessWidget {
  final UserManagementController controller;
  const _CreateManagerSheet({required this.controller});

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Create Manager Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manager will receive login credentials via email',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            _Field(
              controller: controller.nameController,
              label: 'Full Name *',
              hint: 'e.g. Sara Ahmed',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: controller.emailController,
              label: 'Email Address *',
              hint: 'e.g. manager@lsoh.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: controller.phoneController,
              label: 'Phone Number',
              hint: 'e.g. 0300-1234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            _Field(
              controller: controller.passwordController,
              label: 'Temporary Password *',
              hint: 'Min 6 characters',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            // Error message
            Obx(() => controller
                .errorMessage.value.isNotEmpty
                ? Container(
              padding: const EdgeInsets.all(10),
              margin:
              const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            )
                : const SizedBox()),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                  bool ok = await controller
                      .createManagerAccount();
                  if (ok && context.mounted) {
                    Navigator.pop(context);
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
                child: controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Create Manager Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// EDIT MANAGER SHEET
// ==========================================================================
class _EditManagerSheet extends StatelessWidget {
  final String docId;
  final UserManagementController controller;
  const _EditManagerSheet({
    required this.docId,
    required this.controller,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Edit Manager',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _Field(
            controller: controller.editNameController,
            label: 'Full Name *',
            hint: 'Enter name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),

          _Field(
            controller: controller.editPhoneController,
            label: 'Phone Number',
            hint: 'Enter phone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),

          Obx(() => SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                bool ok = await controller
                    .updateManager(docId);
                if (ok && context.mounted) {
                  Navigator.pop(context);
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
              child: controller.isSaving.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================================================
// FIELD WIDGET
// ==========================================================================
class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
                color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(widget.icon,
                size: 18, color: Colors.grey[500]),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey[400],
              ),
              onPressed: () => setState(
                      () => _obscure = !_obscure),
            )
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F6F8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1B6B3A)),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// EMPTY STATE
// ==========================================================================
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No ${filter}s found',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}