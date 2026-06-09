// ============================================================
// FILE: lib/services/donation_service.dart
// ============================================================

import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DonationService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Cloudinary config (reuse your existing preset) ──────────────────────
  static const String _cloudName    = 'dhx53e3id';
  static const String _uploadPreset = 'cloudinary_donatehub_preset';
  // ==========================================================================
  // SAVE JAZZCASH DONATION (completed or failed)
  // ==========================================================================
  Future<bool> saveJazzCashDonation({
    required String cause,
    required double amount,
    required String txnRef,
    required String status, // 'completed' | 'failed'
  }) async {
    try {
      final user = _auth.currentUser;
      await _db.collection('donations').add({
        'userId':         user?.uid ?? 'guest',
        'userEmail':      user?.email ?? '',
        'cause':          cause,
        'amount':         amount,
        'paymentMethod':  'jazzcash',
        'status':         status,
        'transactionRef': txnRef,
        'timestamp':      FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // UPLOAD SCREENSHOT TO CLOUDINARY
  // ==========================================================================
  Future<String?> uploadScreenshot(File file) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      req.fields['upload_preset'] = _uploadPreset;
      req.files.add(await http.MultipartFile.fromPath('file', file.path));

      final res  = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) {
        return jsonDecode(body)['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // SAVE MANUAL DONATION
  // ==========================================================================
  Future<bool> saveManualDonation({
    required String cause,
    required double amount,
    required String transactionId,
    required String screenshotUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      await _db.collection('donations').add({
        'userId':        user?.uid ?? 'guest',
        'userEmail':     user?.email ?? '',
        'cause':         cause,
        'amount':        amount,
        'paymentMethod': 'manual',
        'status':        'pending',
        'transactionId': transactionId,
        'screenshotUrl': screenshotUrl,
        'timestamp':     FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}