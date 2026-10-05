import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VolunteerFeedbackScreen extends StatefulWidget {
  const VolunteerFeedbackScreen({super.key});

  @override
  State<VolunteerFeedbackScreen> createState() =>
      _VolunteerFeedbackScreenState();
}

class _VolunteerFeedbackScreenState extends State<VolunteerFeedbackScreen> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  static const Map<String, String> _aspects = {
    'taskClarity': 'Task clarity and instructions',
    'coordination': 'Coordination and manager support',
    'communication': 'Communication and response time',
    'safety': 'Safety and working conditions',
    'recognition': 'Appreciation and recognition',
  };

  static const List<String> _ratingWords = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  static const List<String> _recommendOptions = ['Yes', 'Maybe', 'No'];
  static const List<String> _continueOptions = [
    'Definitely',
    'Probably',
    'Not sure',
    'No',
  ];

  final TextEditingController _experience = TextEditingController();
  final TextEditingController _suggestions = TextEditingController();
  final TextEditingController _appComment = TextEditingController();

  final Map<String, int> _aspectRatings = {
    'taskClarity': 0,
    'coordination': 0,
    'communication': 0,
    'safety': 0,
    'recognition': 0,
  };

  int _overall = 0;
  int _appRating = 0;
  String _recommend = '';
  String _continuePlan = '';
  bool _submitting = false;

  @override
  void dispose() {
    _experience.dispose();
    _suggestions.dispose();
    _appComment.dispose();
    super.dispose();
  }

  void _notify(String title, String message, {bool error = true}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: error ? Colors.red[50] : Colors.green[50],
      colorText: error ? Colors.red[700] : Colors.green[700],
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_overall == 0) {
      _notify('Rating needed', 'Please rate your overall volunteering experience');
      return;
    }
    if (_experience.text.trim().isEmpty) {
      _notify('Missing', 'Please tell us about your experience');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _notify('Error', 'Please log in again to send feedback');
      return;
    }

    setState(() => _submitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final String name = (userDoc.data()?['name'] ?? 'Volunteer').toString();

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'userName': name,
        'userEmail': user.email ?? '',
        'userRole': 'volunteer',
        'feedbackType': 'volunteer_experience',
        'message': _experience.text.trim(),
        'rating': _overall,
        'ratings': Map<String, int>.from(_aspectRatings),
        'recommend': _recommend,
        'continueVolunteering': _continuePlan,
        'suggestions': _suggestions.text.trim(),
        'appRating': _appRating,
        'appComment': _appComment.text.trim(),
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Get.back();
      _notify('Thank you', 'Your feedback has been submitted', error: false);
    } catch (e) {
      _notify('Error', 'Failed to submit feedback. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _section(
                      icon: Icons.star_rounded,
                      title: 'Overall experience',
                      subtitle: 'How was your time volunteering with Little Smiles?',
                      child: Column(
                        children: [
                          _stars(
                            value: _overall,
                            size: 40,
                            onChanged: (v) => setState(() => _overall = v),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _ratingWords[_overall],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section(
                      icon: Icons.fact_check_outlined,
                      title: 'Rate each area',
                      subtitle: 'Optional — tap a star, tap it again to clear',
                      child: Column(
                        children: _aspects.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _stars(
                                  value: _aspectRatings[e.key] ?? 0,
                                  size: 22,
                                  onChanged: (v) =>
                                      setState(() => _aspectRatings[e.key] = v),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Your plans',
                      subtitle: 'Optional',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Would you recommend volunteering with us to others?'),
                          const SizedBox(height: 8),
                          _choices(
                            options: _recommendOptions,
                            selected: _recommend,
                            onSelect: (v) => setState(
                                  () => _recommend = _recommend == v ? '' : v,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _label('Do you want to continue volunteering with us?'),
                          const SizedBox(height: 8),
                          _choices(
                            options: _continueOptions,
                            selected: _continuePlan,
                            onSelect: (v) => setState(
                                  () => _continuePlan = _continuePlan == v ? '' : v,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section(
                      icon: Icons.edit_note_rounded,
                      title: 'Your words',
                      subtitle: 'Help us understand your experience',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Tell us about your experience *'),
                          const SizedBox(height: 8),
                          _input(
                            controller: _experience,
                            hint: 'What went well? What was difficult?',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          _label('How can we improve the volunteer experience?'),
                          const SizedBox(height: 8),
                          _input(
                            controller: _suggestions,
                            hint: 'Your suggestions (optional)',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _section(
                      icon: Icons.phone_android_rounded,
                      title: 'Rate the DonateHub app',
                      subtitle: 'Your opinion about the app itself (optional)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: _stars(
                              value: _appRating,
                              size: 34,
                              onChanged: (v) => setState(() => _appRating = v),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _label('What should we fix or add in the app?'),
                          const SizedBox(height: 8),
                          _input(
                            controller: _appComment,
                            hint: 'Your comments about the app (optional)',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volunteering Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Share your experience and help us improve',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _green, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14251E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    );
  }

  Widget _stars({
    required int value,
    required double size,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final bool filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(value == i + 1 ? 0 : i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: filled ? Colors.amber[600] : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }

  Widget _choices({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final bool isSel = selected == o;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSel ? _green : const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? _green : Colors.grey.shade300,
              ),
            ),
            child: Text(
              o,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: 600,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.2),
        ),
      ),
    );
  }
}