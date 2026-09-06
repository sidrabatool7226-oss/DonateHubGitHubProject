// ============================================================
// FILE: lib/screens/donor/widgets/campaign_donation_sheet.dart (NEW)
// Reuses Phase 1's OcrService/ReceiptParser/PaymentMethodSelector
// so the Campaign flow shares the exact same verification
// pipeline as the Direct Donate Funds screen (Phase 2).
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/donor_campaign_controller.dart';
import '../../../models/payment_account.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/receipt_parser.dart';
import '../../../widgets/payment_account_card.dart';

class CampaignDonationSheet extends StatefulWidget {
  final String campaignId;
  final String campaignName;

  const CampaignDonationSheet({
    super.key,
    required this.campaignId,
    required this.campaignName,
  });

  @override
  State<CampaignDonationSheet> createState() => _CampaignDonationSheetState();
}

class _CampaignDonationSheetState extends State<CampaignDonationSheet> {
  static const Color _green = Color(0xFF1B6B3A);

  late final DonorCampaignController _controller;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final OcrService _ocr = OcrService();

  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _txnIdCtrl = TextEditingController();

  String? _selectedPaymentMethod;
  File? _receiptFile;
  bool _isCropping = false;
  bool _isScanning = false;
  bool _isSubmitting = false;

  ReceiptParseResult? _ocrResult;
  bool _ocrRan = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<DonorCampaignController>()
        ? Get.find<DonorCampaignController>()
        : Get.put(DonorCampaignController());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _txnIdCtrl.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    setState(() => _isCropping = true);
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: _green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (cropped == null) {
        setState(() => _isCropping = false);
        return;
      }

      final file = File(cropped.path);
      setState(() {
        _receiptFile = file;
        _isCropping = false;
        _ocrRan = false;
        _ocrResult = null;
      });

      await _runOcr(file);
    } catch (e) {
      setState(() => _isCropping = false);
      _snack('Could not process image. Please try again.', isError: true);
    }
  }

  Future<void> _runOcr(File file) async {
    setState(() => _isScanning = true);
    try {
      final text = await _ocr.extractTextFromFile(file);
      if (text != null && text.isNotEmpty) {
        final result = ReceiptParser.parse(text);
        setState(() {
          _ocrResult = result;
          _ocrRan = true;
          if (result.amount != null && _amountCtrl.text.trim().isEmpty) {
            _amountCtrl.text = result.amount!.toStringAsFixed(0);
          }
          if (result.transactionId != null) {
            _txnIdCtrl.text = result.transactionId!;
          }
          if (result.paymentMethod != null && _selectedPaymentMethod == null) {
            _selectedPaymentMethod = result.paymentMethod;
          }
        });
      } else {
        setState(() {
          _ocrRan = true;
          _ocrResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _ocrRan = true;
        _ocrResult = null;
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  String? _validate() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt < 10) return 'Please enter a valid amount (min Rs. 10)';
    if (_selectedPaymentMethod == null) return 'Please select a payment method';
    if (_phoneCtrl.text.trim().isEmpty) return 'Please enter your phone number';
    if (_cnicCtrl.text.trim().isEmpty) return 'Please enter your CNIC number';
    if (_receiptFile == null) return 'Please upload your payment receipt';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      _snack(err, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final proofUrl = await _cloudinary.uploadImage(_receiptFile!);
      if (proofUrl == null) {
        _snack('Screenshot upload failed. Please try again.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      _controller.amountController.text = _amountCtrl.text.trim();
      _controller.selectedPaymentMethod.value = _selectedPaymentMethod!;

      final ok = await _controller.donateToCampaign(
        campaignId: widget.campaignId,
        campaignName: widget.campaignName,
        paymentProofUrl: proofUrl,
        transactionId: _txnIdCtrl.text.trim(),
        ocrAmount: _ocrResult?.amount,
        ocrTransactionId: _ocrResult?.transactionId,
        ocrPaymentMethod: _ocrResult?.paymentMethod,
        ocrPaymentDate: _ocrResult?.paymentDate,
        ocrProcessed: _ocrRan,
        donorPhone: _phoneCtrl.text.trim(),
        donorCnic: _cnicCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) Navigator.pop(context);
    } catch (e) {
      _snack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.volunteer_activism_rounded, color: _green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Donate to Campaign', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(widget.campaignName, style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                filled: true, fillColor: const Color(0xFFF4F6F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Your Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone Number *',
                filled: true, fillColor: const Color(0xFFF4F6F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cnicCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'CNIC Number *',
                filled: true, fillColor: const Color(0xFFF4F6F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              onSelect: (m) => setState(() => _selectedPaymentMethod = m),
            ),

            if (_selectedPaymentMethod != null) ...[
              const SizedBox(height: 4),
              PaymentAccountDetailsCard(account: PaymentAccounts.byMethod(_selectedPaymentMethod!)!),
            ],
            const SizedBox(height: 16),

            const Text('Payment Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildReceiptSection(),

            if (_ocrRan) ...[
              const SizedBox(height: 12),
              _buildOcrResultCard(),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Donation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    if (_isCropping) return _loadingBox('Opening crop tool...');
    if (_isScanning) return _loadingBox('Scanning your payment receipt...');
    if (_receiptFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_receiptFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => setState(() { _receiptFile = null; _ocrRan = false; _ocrResult = null; }),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: _green, size: 24),
            const SizedBox(height: 6),
            Text('Upload Payment Receipt', style: TextStyle(color: _green, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _loadingBox(String message) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _green, strokeWidth: 2)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOcrResultCard() {
    final hasData = _ocrResult?.hasAnyData ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasData ? const Color(0xFFEFF6FF) : const Color(0xFFFFF3E4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasData ? 'OCR Detected — Confirm Below' : 'Could not read receipt — enter manually',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold,
                color: hasData ? const Color(0xFF2563EB) : Colors.orange[700]),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _txnIdCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Transaction ID',
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}