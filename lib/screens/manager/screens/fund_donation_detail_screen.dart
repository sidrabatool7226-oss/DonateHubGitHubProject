// ============================================================
// FILE: lib/screens/manager/screens/fund_donation_detail_screen.dart
//
// CHANGE: Now shows OCR vs donor-entered comparison with mismatch
// warnings, and accepts optional color params so Admin (Phase 5)
// can reuse this exact screen instead of duplicating it.
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/manager_donations_controller.dart';

class FundDonationDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Color primaryColor;
  final Color secondaryColor;

  const FundDonationDetailScreen({
    super.key,
    required this.docId,
    required this.data,
    this.primaryColor = const Color(0xFF0F6E4F),
    this.secondaryColor = const Color(0xFF2FBF87),
  });

  static const Color _bg = Color(0xFFF4FAF7);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ManagerDonationsController>()
        ? Get.find<ManagerDonationsController>()
        : Get.put(ManagerDonationsController());

    final String proofUrl = data['paymentProofUrl'] ?? '';
    final String status = data['status'] ?? 'pending';
    final String method = data['paymentMethod'] ?? '';
    final String donorEmail = data['userEmail'] ?? data['donorEmail'] ?? '';
    final String campaign = data['campaignName'] ?? '';
    final double claimedAmount = (data['amount'] ?? 0).toDouble();
    final String enteredTxnId = data['transactionId'] ?? '';
    final double? ocrAmount = (data['ocrAmount'] as num?)?.toDouble();
    final String? ocrTxnId = data['ocrTransactionId'];
    final String? ocrMethod = data['ocrPaymentMethod'];
    final String? ocrDate = data['ocrPaymentDate'];
    final bool amountMismatch = ocrAmount != null && ocrAmount != claimedAmount;
    final bool txnMismatch = ocrTxnId != null && enteredTxnId.isNotEmpty && ocrTxnId != enteredTxnId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.ocrRan.value && proofUrl.isNotEmpty && status == 'pending') {
        controller.runOcr(proofUrl);
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Verify Fund Donation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFE6F5EE), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(donorEmail, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                if (campaign.isNotEmpty)
                  Text('Campaign: $campaign', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
              ])),
            ])),
            const SizedBox(height: 14),

            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Amount Comparison', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _compareBox('Donor Entered', 'Rs. ${claimedAmount.toStringAsFixed(0)}', primaryColor)),
                const SizedBox(width: 10),
                Expanded(child: _compareBox('OCR Detected',
                    ocrAmount != null ? 'Rs. ${ocrAmount.toStringAsFixed(0)}' : 'Not detected',
                    ocrAmount != null ? const Color(0xFF2563EB) : Colors.grey)),
              ]),
              if (amountMismatch) ...[
                const SizedBox(height: 10),
                _mismatchWarning('Receipt amount and entered amount do not match. Please verify.'),
              ],
            ])),
            const SizedBox(height: 14),

            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Transaction ID Comparison', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _compareBox('Donor Entered', enteredTxnId.isEmpty ? '-' : enteredTxnId, primaryColor)),
                const SizedBox(width: 10),
                Expanded(child: _compareBox('OCR Detected', ocrTxnId ?? 'Not detected',
                    ocrTxnId != null ? const Color(0xFF2563EB) : Colors.grey)),
              ]),
              if (txnMismatch) ...[
                const SizedBox(height: 10),
                _mismatchWarning('Receipt transaction ID and entered ID do not match. Please verify.'),
              ],
              if ((controller.duplicateWarning.value).isNotEmpty) ...[
                const SizedBox(height: 10),
                _mismatchWarning(controller.duplicateWarning.value),
              ],
            ])),
            const SizedBox(height: 14),

            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                _pill('Entered: ${method.isEmpty ? "-" : method}', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
                if (ocrMethod != null) ...[
                  const SizedBox(width: 8),
                  _pill('OCR: $ocrMethod', const Color(0xFFE6F5EE), primaryColor),
                ],
              ]),
              if (ocrDate != null) ...[
                const SizedBox(height: 10),
                Text('Receipt date detected: $ocrDate', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
              ],
            ])),
            const SizedBox(height: 14),

            _SectionTitle(icon: Icons.receipt_long_outlined, title: 'Payment Screenshot'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: proofUrl.isEmpty ? null : () => showDialog(
                context: context,
                builder: (_) => Dialog(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(proofUrl, fit: BoxFit.contain))),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: proofUrl.isEmpty
                    ? Container(height: 180, color: Colors.white, child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]))
                    : Image.network(proofUrl, height: 220, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.white, child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]))),
              ),
            ),
            const SizedBox(height: 6),
            Text('Tap image to view full size', style: TextStyle(fontSize: 10.5, color: Colors.grey[400])),
            const SizedBox(height: 14),

            if (status == 'pending') ...[
              Obx(() {
                if (controller.isProcessing.value) {
                  return _Card(child: Row(children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                    const SizedBox(width: 10),
                    Text('Reading receipt with OCR...', style: TextStyle(fontSize: 12.5, color: primaryColor)),
                  ]));
                }
                return Column(children: [
                  _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF14251E)),
                      const SizedBox(width: 6),
                      const Text('Confirm Verified Values', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 12),
                    _EditField(label: 'Verified Amount (Rs.) *', controller: controller.amountController, keyboardType: TextInputType.number, focusColor: primaryColor),
                    const SizedBox(height: 10),
                    _EditField(label: 'Transaction ID', controller: controller.txnIdController, focusColor: primaryColor),
                  ])),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => controller.runOcr(proofUrl),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Re-run OCR', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ]);
              }),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _showRejectSheet(context, controller),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC0392B), side: const BorderSide(color: Color(0xFFC0392B)),
                      padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
                const SizedBox(width: 10),
                Expanded(child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isSaving.value ? null : () async {
                    bool ok = await controller.approveFundDonation(docId);
                    if (ok) Get.back();
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ))),
              ]),
              const SizedBox(height: 10),
            ] else ...[
              _Card(child: Row(children: [
                Icon(status == 'approved' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: status == 'approved' ? primaryColor : Colors.red),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  status == 'approved' ? 'This donation has been approved.' : 'This donation was rejected: ${data['rejectionReason'] ?? ''}',
                  style: const TextStyle(fontSize: 12.5),
                )),
              ])),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context, controller),
                icon: const Icon(Icons.delete_forever_outlined, size: 18, color: Color(0xFFC0392B)),
                label: const Text('Delete as Illegal / Fraud', style: TextStyle(color: Color(0xFFC0392B), fontSize: 12.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _mismatchWarning(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFCEBEA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC0392B).withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFFC0392B)))),
      ]),
    );
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
  );

  void _showRejectSheet(BuildContext context, ManagerDonationsController controller) {
    controller.rejectReasonController.clear();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reject Donation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _EditField(label: 'Reason *', controller: controller.rejectReasonController, maxLines: 3, focusColor: primaryColor),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () async {
              bool ok = await controller.rejectDonation(docId);
              if (ok && context.mounted) { Navigator.pop(context); Get.back(); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Confirm Rejection'),
          )),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ManagerDonationsController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Donation'),
        content: const Text('This will permanently remove this donation record. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            bool ok = await controller.deleteDonation(docId);
            if (ok) Get.back();
          }, child: const Text('Delete', style: TextStyle(color: Color(0xFFC0392B)))),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: const Color(0xFF0F6E4F)),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF14251E))),
  ]);
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final Color focusColor;
  const _EditField({required this.label, required this.controller, this.maxLines = 1, this.keyboardType = TextInputType.text, required this.focusColor});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF4FAF7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusColor)),
        ),
      ),
    ]);
  }
}