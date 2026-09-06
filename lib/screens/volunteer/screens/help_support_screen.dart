import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _text = Color(0xFF1B2A22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Find answers to common questions about '
                        'DonateHub and your donations.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.88),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),

            const SizedBox(height: 12),

            const _FaqTile(
              question: 'How can I volunteer?',
              answer:
              'Complete the volunteer registration process in '
                  'DonateHub and provide the required information. '
                  'Your application will be reviewed by the responsible '
                  'LSOH team before verification.',
            ),

            const _FaqTile(
              question:
              'Why is my volunteer application pending?',
              answer:
              'Pending means your application is still being '
                  'reviewed. The verification process may include '
                  'reviewing your submitted information and completing '
                  'the required verification stages.',
            ),

            const _FaqTile(
              question:
              'When can I participate in volunteer tasks?',
              answer:
              'Volunteer tasks become available according to your '
                  'verification status, selected roles and the tasks '
                  'assigned by the responsible LSOH team.',
            ),

            const _FaqTile(
              question:
              'How are volunteer roles selected?',
              answer:
              'Your selected volunteer roles are saved with your '
                  'volunteer profile. These roles help the organization '
                  'identify suitable opportunities and tasks.',
            ),

            const _FaqTile(
              question:
              'What are reward points?',
              answer:
              'Reward points represent the points associated with '
                  'your volunteer participation. Your current points '
                  'can be viewed from your volunteer profile.',
            ),

            const _FaqTile(
              question:
              'I cannot see a task. What should I do?',
              answer:
              'Task availability depends on your verification '
                  'status, eligibility and the current volunteer '
                  'requirements. If an expected task is not visible, '
                  'please check your profile status and contact the '
                  'responsible LSOH team if the issue continues.',
            ),

            const _FaqTile(
              question:
              'How can I update my profile?',
              answer:
              'Open your Profile section and select Edit in the '
                  'Profile Information card. You can update the '
                  'available editable information and save your changes.',
            ),

            const _FaqTile(
              question:
              'What should I do if I forgot my password?',
              answer:
              'Use the password recovery option available on the '
                  'login screen to recover access to your account.',
            ),

            const SizedBox(height: 26),

            const Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.contact_support_outlined,
                    color: _green,
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Little Smiles Orphan Home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'For volunteer account, verification or task-related '
                        'issues, please contact the responsible LSOH team '
                        'through the official support channel provided by '
                        'the organization.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF68766E),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Little Smiles Orphan Home • DonateHub',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  // ✅ FIX: _green was missing inside _FaqTile
  static const Color _green = Color(0xFF1B6B3A);

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: const Color(0xFFEAF6EF),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 3,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          iconColor: _green,
          collapsedIconColor: const Color(0xFF718078),
          leading: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: _green,
              size: 19,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF24332B),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF68766E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}