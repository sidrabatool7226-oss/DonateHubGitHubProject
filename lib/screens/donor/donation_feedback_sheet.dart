// ============================================================
// FILE: lib/screens/donor/donation_feedback_sheet.dart (NEW)
// Lightweight post-donation feedback prompt — triggered
// automatically once per donation after fund approval or
// resource completion. Separate from the general "Give Feedback"
// screen in Profile so that screen's existing logic stays untouched.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DonationFeedbackSheet extends StatefulWidget {
  final String donationId;
  final bool isFund;

  const DonationFeedbackSheet({
    super.key,
    required this.donationId,
    required this.isFund,
  });

  static const Color green = Color(0xFF1B6B3A);

  @override
  State<DonationFeedbackSheet> createState() => _DonationFeedbackSheetState();
}

class _DonationFeedbackSheetState extends State<DonationFeedbackSheet> {
  int _rating = 0;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  static const Color _green = Color(0xFF1B6B3A);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
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
      final name = (userDoc.data() as Map?)?['name'] ?? 'Donor';

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? '',
        'userName': name,
        'userEmail': user?.email ?? '',
        'userRole': 'donor',
        'donationId': widget.donationId,
        'message': _messageController.text.trim().isEmpty
            ? 'No comments provided'
            : _messageController.text.trim(),
        'rating': _rating,
        'isReviewed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to submit. You can try again from Profile.'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.celebration_rounded, color: _green, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            widget.isFund ? 'Thank You for Your Donation!' : 'Your Donation Reached LSOH!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'How was your experience with DonateHub?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38,
                    color: Colors.amber[600],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _messageController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Any comments? (optional)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5),
              filled: true,
              fillColor: const Color(0xFFF4F6F8),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('Maybe Later', style: TextStyle(color: Colors.grey[500])),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}