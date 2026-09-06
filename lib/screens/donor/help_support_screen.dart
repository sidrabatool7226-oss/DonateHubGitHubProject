import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFFEAF6EF);
  static const Color _background = Color(0xFFF7FAF8);
  static const Color _text = Color(0xFF1B2A22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // SUPPORT HERO
              // ----------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 15),
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
                      'Find answers to common questions about DonateHub '
                          'and your donations.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.88),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 27),

              // ----------------------------------------------------------
              // FAQ TITLE
              // ----------------------------------------------------------
              const _SectionTitle(
                title: 'Frequently Asked Questions',
                icon: Icons.help_outline_rounded,
              ),

              const SizedBox(height: 13),

              // ----------------------------------------------------------
              // FAQ 1
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'How can I donate?',
                answer:
                'You can donate through the donation options available '
                    'inside DonateHub. You may support an active campaign '
                    'through a fund donation or donate useful resources.',
              ),

              // ----------------------------------------------------------
              // FAQ 2
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'How can I donate an item?',
                answer:
                'Open the Donate Items option from your donor dashboard, '
                    'select the relevant category and provide the requested '
                    'donation details. Your donation will be reviewed before '
                    'approval.',
              ),

              // ----------------------------------------------------------
              // FAQ 3
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'Why is my donation showing as pending?',
                answer:
                'Pending means that your donation has been submitted and '
                    'is waiting for verification by the responsible team. '
                    'Please allow the team time to review the submitted details.',
              ),

              // ----------------------------------------------------------
              // FAQ 4
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'What happens after my donation is approved?',
                answer:
                'Once approved, your donation becomes part of the '
                    'organization\'s donation workflow. Resource donations may '
                    'also move into the relevant volunteer and task workflow.',
              ),

              // ----------------------------------------------------------
              // FAQ 5
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'How can I check my donation status?',
                answer:
                'Open the relevant donation section from your donor account '
                    'to view the available information and current status of '
                    'your submitted donation.',
              ),

              // ----------------------------------------------------------
              // FAQ 6
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'Can I edit a submitted donation?',
                answer:
                'Donation changes depend on the current status and workflow '
                    'of the donation. If you need to correct information, '
                    'contact the responsible LSOH support team.',
              ),

              // ----------------------------------------------------------
              // FAQ 7
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'What should I do if I face a payment problem?',
                answer:
                'First check that the payment information and proof have '
                    'been submitted correctly. If the issue continues, contact '
                    'the Little Smiles Orphan Home support team for assistance.',
              ),

              // ----------------------------------------------------------
              // FAQ 8
              // ----------------------------------------------------------
              const _FaqTile(
                question: 'What if my uploaded image is not working?',
                answer:
                'Make sure you have selected a valid image and that your '
                    'internet connection is working. Try uploading the image '
                    'again if the problem continues.',
              ),

              const SizedBox(height: 27),

              // ----------------------------------------------------------
              // NEED MORE HELP
              // ----------------------------------------------------------
              const _SectionTitle(
                title: 'Need More Help?',
                icon: Icons.contact_support_outlined,
              ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
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
                child: Column(
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.contact_support_outlined,
                        color: _green,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Little Smiles Orphan Home',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'For donation, account or application-related issues, '
                          'please contact the responsible LSOH team through the '
                          'official support channel provided by the organization.',
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

              const SizedBox(height: 25),

              // ----------------------------------------------------------
              // FOOTER
              // ----------------------------------------------------------
              Center(
                child: Text(
                  'We are here to help you support little smiles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
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

// ==========================================================================
// SECTION TITLE
// ==========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6EF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1B6B3A),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2A22),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// FAQ TILE
// ==========================================================================

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

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
          iconColor: const Color(0xFF1B6B3A),
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
              color: Color(0xFF1B6B3A),
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