import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonorFeedbackTab extends StatefulWidget {
  const DonorFeedbackTab({super.key});

  @override
  State<DonorFeedbackTab> createState() =>
      _DonorFeedbackTabState();
}

class _DonorFeedbackTabState
    extends State<DonorFeedbackTab> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  final _messageController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing',
        'Please write your feedback',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      final name =
          (userDoc.data() as Map?)?['name'] ?? 'Donor';

      await FirebaseFirestore.instance
          .collection('feedback')
          .add({
        'userId': user?.uid ?? '',
        'userName': name,
        'userEmail': user?.email ?? '',
        'userRole': 'donor',
        'message': _messageController.text.trim(),
        'rating': _rating,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() => _rating = 0);

      Get.snackbar(
        'Thank You! 🎉',
        'Your feedback has been submitted',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit feedback',
        backgroundColor: Colors.red[50],
        colorText: Colors.red[700],
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() => _isSubmitting = false);
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 28),
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Share Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Help us improve DonateHub',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Rating card ──────────────────
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'How was your experience?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children:
                            List.generate(5, (i) {
                              return GestureDetector(
                                onTap: () => setState(
                                        () => _rating = i + 1),
                                child: Padding(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 4),
                                  child: Icon(
                                    i < _rating
                                        ? Icons
                                        .star_rounded
                                        : Icons
                                        .star_outline_rounded,
                                    size: 40,
                                    color:
                                    Colors.amber[600],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rating == 0
                                ? 'Tap to rate'
                                : _ratingText(_rating),
                            style: TextStyle(
                              fontSize: 13,
                              color: _rating == 0
                                  ? Colors.grey[400]
                                  : Colors.amber[700],
                              fontWeight: _rating > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Message card ─────────────────
                    Container(
                      width: double.infinity,
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
                                  Icons
                                      .edit_note_rounded,
                                  color: _green,
                                  size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Your Feedback',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller:
                            _messageController,
                            maxLines: 5,
                            style: const TextStyle(
                                fontSize: 13),
                            decoration: InputDecoration(
                              hintText:
                              'Share your thoughts about the app and your donation experience...',
                              hintStyle: TextStyle(
                                  color:
                                  Colors.grey[400],
                                  fontSize: 13),
                              filled: true,
                              fillColor: const Color(
                                  0xFFF4F6F8),
                              contentPadding:
                              const EdgeInsets.all(
                                  14),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                borderSide: BorderSide(
                                    color: Colors
                                        .grey[300]!),
                              ),
                              enabledBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                borderSide: BorderSide(
                                    color: Colors
                                        .grey[300]!),
                              ),
                              focusedBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                                borderSide:
                                const BorderSide(
                                    color: _green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : _submitFeedback,
                        icon: _isSubmitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.send_rounded,
                            size: 18),
                        label: Text(
                          _isSubmitting
                              ? 'Submitting...'
                              : 'Submit Feedback',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                14),
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

  String _ratingText(int rating) {
    switch (rating) {
      case 1: return 'Poor 😞';
      case 2: return 'Fair 😐';
      case 3: return 'Good 🙂';
      case 4: return 'Very Good 😊';
      case 5: return 'Excellent! 🤩';
      default: return '';
    }
  }
}