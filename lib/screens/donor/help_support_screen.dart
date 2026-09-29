import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'contact_us_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How long does volunteer verification take?',
      'a':
      'After you submit your registration form, our team reviews your application, schedules a video call interview, and may follow up with a physical visit. You can track your exact status anytime on the Verification Status screen.',
    },
    {
      'q': 'Why can\'t I see any tasks in my Volunteer dashboard?',
      'a':
      'Tasks are only shown to volunteers whose selected roles match the task category, and only after your account has been fully verified. Make sure you have set your weekly availability — the Manager uses this along with your roles to decide who to assign.',
    },
    {
      'q': 'I accidentally rejected a task by mistake — what do I do?',
      'a':
      'Once a task is accepted or rejected, that decision is final for that specific task to prevent conflicts with other volunteers. Please contact your Manager or use Contact Us below, and a new task can be assigned to you.',
    },
    {
      'q': 'My donation has been pending for a while. What\'s happening?',
      'a':
      'Every fund and resource donation is manually reviewed by our Admin/Manager team before approval — this ensures accuracy and prevents fraud. You can track the live status anytime from the Donations tab.',
    },
    {
      'q': 'I submitted a payment receipt — why hasn\'t it been verified yet?',
      'a':
      'Our OCR system reads the amount and transaction details from your receipt automatically, but a real person always manually verifies the actual payment before approval. This usually takes a short while depending on team availability.',
    },
    {
      'q': 'The app isn\'t responding or something looks broken.',
      'a':
      'Try closing and reopening the app first. If the issue continues, check your internet connection, make sure the app is updated to the latest version, and reach out to us using the Contact Us option below.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: _green,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_green, _lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 46, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.help_center_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text('Help & Support', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Answers to common questions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 12),
                  ..._faqs.map((faq) => _FaqTile(question: faq['q']!, answer: faq['a']!)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _green.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: _green, size: 32),
                        const SizedBox(height: 10),
                        const Text('Still need help?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Our team is happy to answer any question directly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Get.to(() => const ContactUsScreen()),
                            icon: const Icon(Icons.contact_support_outlined, size: 18),
                            label: const Text('Contact Us'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;
  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  ),
                  Icon(_expanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      color: _green, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(widget.answer, style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.5)),
            ),
        ],
      ),
    );
  }
}