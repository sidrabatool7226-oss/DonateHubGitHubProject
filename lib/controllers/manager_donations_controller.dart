import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../services/email_service.dart';
import 'donor_campaign_controller.dart';

class ManagerDonationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OcrService _ocr = OcrService();
  final EmailService _emailService = EmailService();

  var selectedType = 'fund'.obs;
  var selectedStatus = 'pending'.obs;

  var isProcessing = false.obs;
  var isSaving = false.obs;

  var ocrRan = false.obs;
  var ocrResult = Rxn<ReceiptParseResult>();
  var duplicateWarning = ''.obs;

  final amountController = TextEditingController();
  final txnIdController = TextEditingController();
  final rejectReasonController = TextEditingController();

  final List<String> statusTabs = const ['pending', 'approved', 'rejected'];

  @override
  void onClose() {
    amountController.dispose();
    txnIdController.dispose();
    rejectReasonController.dispose();
    _ocr.dispose();
    super.onClose();
  }

  Stream<QuerySnapshot> get donationsStream =>
      _db.collection('donations').orderBy('createdAt', descending: true).snapshots();

  Future<void> runOcr(String imageUrl) async {
    isProcessing.value = true;
    ocrRan.value = false;
    ocrResult.value = null;
    duplicateWarning.value = '';

    try {
      final text = await _ocr.extractTextFromUrl(imageUrl);
      if (text != null && text.isNotEmpty) {
        final result = ReceiptParser.parse(text);
        ocrResult.value = result;
        if (result.amount != null) {
          amountController.text = result.amount!.toStringAsFixed(0);
        }
        if (result.transactionId != null) {
          txnIdController.text = result.transactionId!;
          await _checkDuplicate(result.transactionId!);
        }
      }
      ocrRan.value = true;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _checkDuplicate(String txnId) async {
    if (txnId.trim().isEmpty) return;
    final campaignController = Get.isRegistered<DonorCampaignController>()
        ? Get.find<DonorCampaignController>()
        : Get.put(DonorCampaignController());
    final isDupe = await campaignController.isDuplicateTransaction(txnId);
    if (isDupe) {
      duplicateWarning.value =
      'Warning: This transaction ID has already been used in another donation.';
    }
  }

  // ── Approve Fund Donation ────────────────────────────────────────────
  // FIXED: reward points now correctly increment here (this was missing
  // in the previous version — email/notification were firing but the
  // 'donors/{uid}.rewardPoints' write was not, which is why the Donor's
  // profile badge never updated after fund approval).
  Future<bool> approveFundDonation(String donationId) async {
    if (amountController.text.trim().isEmpty) {
      Get.snackbar('Missing', 'Please confirm the amount',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    }

    isSaving.value = true;
    try {
      final doc = await _db.collection('donations').doc(donationId).get();
      final donationData = doc.data() ?? {};

      final String currentStatus = donationData['status'] ?? 'pending';
      if (currentStatus != 'pending') {
        Get.snackbar('Already Reviewed',
            'This donation was already $currentStatus by another reviewer.',
            backgroundColor: Colors.orange[50], colorText: Colors.orange[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return false;
      }

      final donorId = donationData['donorId'] ?? '';
      final campaignId = donationData['campaignId'];
      final double approvedAmount = double.tryParse(amountController.text.trim()) ?? 0;

      // Batch: donation status + campaign amount + donor reward points
      // all commit together — avoids a partial-success state.
      WriteBatch batch = _db.batch();

      batch.update(_db.collection('donations').doc(donationId), {
        'status': 'approved',
        'verifiedAmount': approvedAmount,
        'transactionId': txnIdController.text.trim(),
        'verifiedBy': _auth.currentUser?.uid ?? '',
        'verifiedAt': FieldValue.serverTimestamp(),
        'fundsAdded': true,
      });

      if (campaignId != null && campaignId.toString().isNotEmpty) {
        batch.update(_db.collection('campaigns').doc(campaignId), {
          'collectedAmount': FieldValue.increment(approvedAmount),
        });
      }

      // NEW/RESTORED — reward points, Rs. 100 = 1 point (matches Donor
      // Rewards screen's existing point scale)
      if (donorId.toString().isNotEmpty) {
        batch.set(
          _db.collection('donors').doc(donorId),
          {
            'rewardPoints': FieldValue.increment((approvedAmount / 100).floor()),
            'totalDonations': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _db.collection('notifications').add({
        'toUserId': donorId,
        'title': 'Donation Verified! ✅',
        'message':
        'Your fund donation of Rs. ${approvedAmount.toStringAsFixed(0)} has been verified. Thank you for your generosity!',
        'type': 'donation_approved',
        'entityId': donationId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final bool alreadyEmailed = donationData['completionEmailSent'] == true;
      if (!alreadyEmailed && donorId.toString().isNotEmpty) {
        final userDoc = await _db.collection('users').doc(donorId).get();
        final userData = userDoc.data() ?? {};
        final String donorEmail = userData['email'] ?? donationData['userEmail'] ?? '';
        final String donorName = userData['name'] ?? 'Donor';

        if (donorEmail.isNotEmpty) {
          final bool emailSent = await _emailService.sendDonationCompletedEmail(
            toEmail: donorEmail,
            toName: donorName,
            amount: approvedAmount.toStringAsFixed(0),
            isFund: true,
          );
          if (emailSent) {
            await _db.collection('donations').doc(donationId).update({'completionEmailSent': true});
          }
        }
      }

      _clearForm();
      Get.snackbar('Approved', 'Donation verified — funds and reward points updated!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve. Try again.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> approveResourceDonation(String donationId) async {
    isSaving.value = true;
    try {
      final doc = await _db.collection('donations').doc(donationId).get();
      final donationData = doc.data() ?? {};
      final String currentStatus = donationData['status'] ?? 'pending';
      if (currentStatus != 'pending') {
        Get.snackbar('Already Reviewed', 'This donation was already $currentStatus.',
            backgroundColor: Colors.orange[50], colorText: Colors.orange[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return false;
      }

      final donorId = donationData['donorId'] ?? '';
      final itemName = donationData['itemName'] ?? 'item';

      await _db.collection('donations').doc(donationId).update({
        'status': 'approved',
        'verifiedBy': _auth.currentUser?.uid ?? '',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('notifications').add({
        'toUserId': donorId,
        'title': 'Donation Approved! ✅',
        'message': 'Your donation of "$itemName" has been approved. A volunteer will be assigned for pickup soon.',
        'type': 'donation_approved',
        'entityId': donationId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Approved', 'Resource donation approved!',
          backgroundColor: Colors.green[50], colorText: Colors.green[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve. Try again.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> rejectDonation(String donationId) async {
    if (rejectReasonController.text.trim().isEmpty) {
      Get.snackbar('Missing Reason', 'Please provide a rejection reason',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    }

    isSaving.value = true;
    try {
      final doc = await _db.collection('donations').doc(donationId).get();
      final donationData = doc.data() ?? {};
      final String currentStatus = donationData['status'] ?? 'pending';
      if (currentStatus != 'pending') {
        Get.snackbar('Already Reviewed', 'This donation was already $currentStatus.',
            backgroundColor: Colors.orange[50], colorText: Colors.orange[700],
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
        return false;
      }

      final donorId = donationData['donorId'] ?? '';

      await _db.collection('donations').doc(donationId).update({
        'status': 'rejected',
        'rejectionReason': rejectReasonController.text.trim(),
        'rejectedBy': _auth.currentUser?.uid ?? '',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('notifications').add({
        'toUserId': donorId,
        'title': 'Donation Not Approved',
        'message': 'Your donation could not be verified. Reason: ${rejectReasonController.text.trim()}',
        'type': 'donation_rejected',
        'entityId': donationId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      rejectReasonController.clear();
      Get.snackbar('Rejected', 'Donation rejected and donor notified.',
          backgroundColor: Colors.orange[50], colorText: Colors.orange[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject. Try again.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteDonation(String donationId) async {
    isSaving.value = true;
    try {
      await _db.collection('donations').doc(donationId).delete();
      Get.snackbar('Deleted', 'Donation record permanently removed.',
          backgroundColor: Colors.red[50], colorText: Colors.red[700],
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _clearForm() {
    amountController.clear();
    txnIdController.clear();
    duplicateWarning.value = '';
    ocrRan.value = false;
    ocrResult.value = null;
  }

  void prefillForApproval(Map<String, dynamic> data) {
    amountController.text = (data['amount'] ?? '').toString();
    txnIdController.text = (data['transactionId'] ?? '').toString();
    duplicateWarning.value = '';
    ocrRan.value = false;
    ocrResult.value = null;
  }

  String timeAgo(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}