// ============================================================
// FILE: lib/widgets/admin_account_status_card.dart (NEW)
//
// PURPOSE
// Reusable "Account Status" section for Admin detail screens —
// shows whether a user (Donor or Volunteer) is active/inactive
// and lets the Admin toggle it, the same way
// UserManagementController.toggleUserStatus() already does
// for Managers, but generalized to any role via the shared
// 'users/{uid}.status' field (no role-specific collection like
// 'managers' is touched here — Donors/Volunteers don't have one).
//
// Reads LIVE from the 'users/{docId}' document via StreamBuilder,
// so the badge/button update immediately after a toggle without
// needing to pop and reopen the screen.
//
// This status is now actually enforced at login (see
// AuthService.loginUser() / signInWithGoogle()) — a deactivated
// account cannot sign back in until reactivated here.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAccountStatusCard extends StatelessWidget {
  final String docId;
  final String roleLabel; // e.g. 'Donor', 'Volunteer' — used in dialog/snackbar text only

  const AdminAccountStatusCard({
    super.key,
    required this.docId,
    required this.roleLabel,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(docId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final String status = (data?['status'] ?? 'active').toString();
        final bool isActive = status != 'inactive';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Status',
                style: TextStyle(fontSize: 14, color: _green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 13,
                          color: isActive ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive ? 'Active' : 'Deactivated',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => isActive
                        ? _confirmDeactivate(context, docId, roleLabel)
                        : _activate(context, docId, roleLabel),
                    icon: Icon(
                      isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: isActive ? Colors.red[700] : Colors.green[700],
                    ),
                    label: Text(
                      isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isActive) ...[
                const SizedBox(height: 4),
                Text(
                  'This account cannot sign in while deactivated.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static void _confirmDeactivate(BuildContext context, String docId, String roleLabel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Deactivate $roleLabel'),
        content: Text(
          'Are you sure you want to deactivate this $roleLabel\'s account? '
              'They will not be able to sign in until you reactivate it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setStatus(context, docId, 'inactive', roleLabel);
            },
            child: Text('Deactivate', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  static void _activate(BuildContext context, String docId, String roleLabel) {
    _setStatus(context, docId, 'active', roleLabel);
  }

  static Future<void> _setStatus(
      BuildContext context,
      String docId,
      String newStatus,
      String roleLabel,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'status': newStatus,
      });
      if (!context.mounted) return;
      final bool activated = newStatus == 'active';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activated ? '$roleLabel account activated.' : '$roleLabel account deactivated.'),
          backgroundColor: activated ? Colors.green[700] : Colors.red[700],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update account status.'), backgroundColor: Colors.red[700]),
      );
    }
  }
}