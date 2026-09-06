import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(child: Text('No data found'));
            }

            final String stage = data['verificationStage'] ?? 'Pending';
            final String name = data['name'] ?? 'Volunteer';

            // Agar verified ho gaya — automatically dashboard pe bhejo
            if (stage == 'Verified') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/volunteer_dashboard', (r) => false);
              });
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_green, _lightGreen],
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
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hi $name 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your Application Status',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Status Timeline ──────────────────────────
                        _StatusTimelineCard(stage: stage),
                        const SizedBox(height: 14),

                        // ── Stage-specific content ───────────────────
                        _buildStageContent(context, stage, data),

                        const SizedBox(height: 14),

                        // ── Info footer ───────────────────────────────
                        _InfoFooter(stage: stage),

                        const SizedBox(height: 20),

                        // ── Logout ────────────────────────────────────
                        GestureDetector(
                          onTap: () => _confirmLogout(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded,
                                    color: Colors.red[700], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
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

  // ==========================================================================
  // STAGE-SPECIFIC CONTENT
  // ==========================================================================
  Widget _buildStageContent(
      BuildContext context, String stage, Map<String, dynamic> data) {
    switch (stage) {
      case 'Pending':
      case 'Form_Reviewed':
        return _PendingCard(stage: stage);

      case 'Video_Scheduled':
        return _VideoCallCard(
          date: data['videoCallDate'] ?? '',
          time: data['videoCallTime'] ?? '',
          link: data['videoCallLink'] ?? '',
        );

      case 'Physical_Scheduled':
        return _PhysicalVisitCard(
          date: data['physicalDate'] ?? '',
          time: data['physicalTime'] ?? '',
          location: data['physicalLocation'] ?? '',
          notes: data['physicalNotes'] ?? '',
        );

      case 'Rejected':
        return _RejectedCard(
          reason: data['rejectionReason'] ?? 'No reason provided.',
        );

      case 'Verified':
        return _ApprovedCard();

      default:
        return _PendingCard(stage: 'Pending');
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (r) => false);
            },
            child: Text('Logout', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// STATUS TIMELINE CARD
// ==========================================================================
class _StatusTimelineCard extends StatelessWidget {
  final String stage;
  const _StatusTimelineCard({required this.stage});

  static const Color _green = Color(0xFF1B6B3A);

  int _stepIndex(String stage) {
    switch (stage) {
      case 'Pending':
        return 0;
      case 'Form_Reviewed':
        return 1;
      case 'Video_Scheduled':
        return 2;
      case 'Physical_Scheduled':
        return 3;
      case 'Verified':
        return 4;
      case 'Rejected':
        return -1; // special case
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Submitted',
      'Reviewed',
      'Video Call',
      'Physical',
      'Approved',
    ];
    final activeIndex = _stepIndex(stage);
    final isRejected = stage == 'Rejected';

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
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = !isRejected && index <= activeIndex;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isRejected && index == 0
                              ? Colors.red[400]
                              : isDone
                              ? _green
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRejected && index == 0
                              ? Icons.close_rounded
                              : isDone
                              ? Icons.check_rounded
                              : Icons.circle,
                          color: isDone || (isRejected && index == 0)
                              ? Colors.white
                              : Colors.grey[400],
                          size: isDone || isRejected ? 15 : 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 8.5,
                          color: isDone ? _green : Colors.grey[400],
                          fontWeight:
                          isDone ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: index < activeIndex && !isRejected
                          ? _green
                          : Colors.grey[200],
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
// PENDING CARD
// ==========================================================================
class _PendingCard extends StatelessWidget {
  final String stage;
  const _PendingCard({required this.stage});

  static const Color _orange = Color(0xFFDB7C26);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _orange.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: _orange, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            stage == 'Form_Reviewed'
                ? 'Form Reviewed'
                : 'Application Under Review',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            stage == 'Form_Reviewed'
                ? 'Your form has been reviewed. A video call interview will be scheduled soon.'
                : 'Thank you for applying! Our manager is reviewing your application. We\'ll notify you once the next step is scheduled.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// VIDEO CALL SCHEDULED CARD
// ==========================================================================
class _VideoCallCard extends StatelessWidget {
  final String date;
  final String time;
  final String link;
  const _VideoCallCard({required this.date, required this.time, required this.link});

  static const Color _blue = Color(0xFF2563EB);

  Future<void> _openLink(BuildContext context) async {
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open the link'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.videocam_rounded, color: _blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Video Interview Scheduled',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.bold)),
                    Text('Join at the scheduled time',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date + Time
          Row(
            children: [
              Expanded(
                child: _detailBox(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: date,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailBox(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Meeting Link
          GestureDetector(
            onTap: () => _openLink(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Join Video Call',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Join a few minutes early and ensure good lighting and internet connection.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _detailBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _blue),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// PHYSICAL VISIT SCHEDULED CARD
// ==========================================================================
class _PhysicalVisitCard extends StatelessWidget {
  final String date;
  final String time;
  final String location;
  final String notes;
  const _PhysicalVisitCard({
    required this.date,
    required this.time,
    required this.location,
    required this.notes,
  });

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.location_on_rounded, color: _purple),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Physical Verification Scheduled',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.bold)),
                    Text('Please visit in-person',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _box(icon: Icons.calendar_today_rounded, label: 'Date', value: date),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _box(icon: Icons.access_time_rounded, label: 'Time', value: time),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _box(icon: Icons.location_on_outlined, label: 'Location', value: location, fullWidth: true),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: _purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(notes,
                        style: const TextStyle(fontSize: 12, color: _purple)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _box({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _purple),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// REJECTED CARD
// ==========================================================================
class _RejectedCard extends StatelessWidget {
  final String reason;
  const _RejectedCard({required this.reason});

  static const Color _red = Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEBEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_rounded, color: _red, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Application Not Approved',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCEBEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _red, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// APPROVED CARD (brief flash before redirect)
// ==========================================================================
class _ApprovedCard extends StatelessWidget {
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_green, Color(0xFF2D8A52)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Congratulations! You\'re Approved 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Taking you to your dashboard...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// INFO FOOTER
// ==========================================================================
class _InfoFooter extends StatelessWidget {
  final String stage;
  const _InfoFooter({required this.stage});

  @override
  Widget build(BuildContext context) {
    if (stage == 'Verified') return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1B6B3A)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This page updates automatically once our manager takes action on your application.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF1B6B3A)),
            ),
          ),
        ],
      ),
    );
  }
}