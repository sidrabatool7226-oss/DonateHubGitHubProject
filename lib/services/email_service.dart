// ============================================================
// FILE: lib/services/email_service.dart
// PURPOSE: EmailJS integration — sends transactional emails
//          using the EmailJS REST API directly (client-side,
//          as EmailJS Free tier intends).
//
// CREDENTIALS: Public Key is safe to keep in client code by
// EmailJS's own design — it identifies the account but cannot
// send emails without the corresponding Service/Template IDs
// also matching, and "non-browser access" must be explicitly
// enabled on the EmailJS dashboard for this to work from a
// mobile app (see setup notes).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // ── EmailJS Credentials — put your values here ─────────────────────
  static const String _serviceId = 'service_9leml6o';
  static const String _volunteerTemplateId = 'template_lzshhq3';
  static const String _donationTemplateId = 'template_tnovidb';
  static const String _publicKey = 'GNrxkMPshpR2Guxbu';

  static const String _apiUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  // ==========================================================================
  // VOLUNTEER VERIFICATION EMAIL
  // Used for BOTH online-only and physical verification outcomes —
  // same EmailJS template, different message_body text.
  // ==========================================================================
  Future<bool> sendVolunteerVerificationEmail({
    required String toEmail,
    required String toName,
    required bool isPhysical,
  }) async {
    const String subject = 'Volunteer Verification Successful ✅';

    final String messageBody = isPhysical
        ? 'Congratulations! Your physical volunteer verification has been '
        'successfully completed. Your application has been reviewed and '
        'your volunteer status has been verified. You are now eligible '
        'to volunteer with Little Smiles Orphan Home and can access '
        'your DonateHub Volunteer Dashboard.'
        : 'Congratulations! Your online volunteer interview was successful. '
        'After reviewing your interview and application, we are pleased '
        'to confirm that you have been verified and are now eligible to '
        'volunteer with Little Smiles Orphan Home. You can now access '
        'your DonateHub Volunteer Dashboard and begin your volunteer '
        'journey with us.';

    return _send(
      templateId: _volunteerTemplateId,
      params: {
        'to_email': toEmail,
        'to_name': toName.isNotEmpty ? toName : 'Volunteer',
        'subject': subject,
        'message_body': messageBody,
      },
    );
  }

  // ==========================================================================
  // DONATION COMPLETED EMAIL
  // Used for BOTH fund and resource donations — same EmailJS template,
  // different message_body text. 'amount' is left empty for resource
  // donations since they have no monetary value.
  // ==========================================================================
  Future<bool> sendDonationCompletedEmail({
    required String toEmail,
    required String toName,
    required String amount,
    required bool isFund,
  }) async {
    final String subject =
    isFund ? 'Fund Donation Completed ✅' : 'Donation Completed ✅';

    final String messageBody = isFund
        ? 'Thank you for your generous fund donation. We are pleased to let '
        'you know that your contribution has successfully reached '
        'Little Smiles Orphan Home and has been recorded as completed. '
        'Your kindness and support are helping us meet the needs of '
        'children and make a meaningful difference.'
        : 'Thank you for your generous resource donation. We are pleased to '
        'let you know that your contribution has successfully reached '
        'Little Smiles Orphan Home and has been recorded as completed. '
        'Your kindness and support are helping us meet the needs of '
        'children and make a meaningful difference.';

    return _send(
      templateId: _donationTemplateId,
      params: {
        'to_email': toEmail,
        'to_name': toName.isNotEmpty ? toName : 'Donor',
        'subject': subject,
        'message_body': messageBody,
        'amount': amount,
      },
    );
  }

  // ==========================================================================
  // PRIVATE — Actual HTTP call to EmailJS
  // ==========================================================================
  Future<bool> _send({
    required String templateId,
    required Map<String, String> params,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': templateId,
          'user_id': _publicKey,
          'template_params': params,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Do not throw — email failure must never break the
        // underlying approval/completion business operation.
        print('EmailJS send failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('EmailJS send error: $e');
      return false;
    }
  }
}