// ============================================================
// FILE: lib/screens/donor/donate_funds_screen.dart
//
// FIX:
// - Receipt selection no longer crashes/restarts the app.
// - Removed ImageCropper from the receipt selection flow.
// - Selected gallery image is used directly.
// - OCR still runs immediately after image selection.
// - Cloudinary upload + Firestore donation flow unchanged.
// - UI unchanged.
// ============================================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/donor_campaign_controller.dart';
import '../../models/payment_account.dart';
import '../../services/cloudinary_service.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../../widgets/payment_account_card.dart';

class DonateFundsScreen extends StatefulWidget {
  const DonateFundsScreen({super.key});

  @override
  State<DonateFundsScreen> createState() => _DonateFundsScreenState();
}

class _DonateFundsScreenState extends State<DonateFundsScreen> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _greenDark = Color(0xFF145230);
  static const Color _teal = Color(0xFF00BFA5);
  static const Color _bg = Color(0xFFF2F4F8);

  late final DonorCampaignController _controller;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final OcrService _ocr = OcrService();

  final _customCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _txnIdCtrl = TextEditingController();

  String? _selectedCampaignId;
  String? _selectedCampaignName;
  double? _selectedPreset;
  String? _selectedPaymentMethod;

  File? _receiptFile;

  bool _isScanning = false;
  bool _isSubmitting = false;

  ReceiptParseResult? _ocrResult;
  bool _ocrRan = false;

  final List<int> _presets = [500, 1000, 5000, 10000, 50000];

  @override
  void initState() {
    super.initState();

    _controller = Get.isRegistered<DonorCampaignController>()
        ? Get.find<DonorCampaignController>()
        : Get.put(DonorCampaignController());
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _txnIdCtrl.dispose();
    _ocr.dispose();

    super.dispose();
  }

  // ==========================================================================
  // FINAL AMOUNT
  // ==========================================================================

  double? get _finalAmount {
    if (_customCtrl.text.trim().isNotEmpty) {
      return double.tryParse(_customCtrl.text.trim());
    }

    return _selectedPreset;
  }

  // ==========================================================================
  // PICK RECEIPT
  //
  // IMPORTANT:
  // ImageCropper was removed from this flow because it can cause an Android
  // Activity/process restart if its native configuration is not correct.
  //
  // The selected image is now used directly.
  // ==========================================================================

  Future<void> _pickReceipt() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) {
        return;
      }

      final File file = File(picked.path);

      if (!await file.exists()) {
        _snack(
          'Selected image could not be accessed. Please try again.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _receiptFile = file;
        _ocrRan = false;
        _ocrResult = null;
      });

      // Run OCR after image has been successfully selected.
      await _runOcr(file);
    } catch (e) {
      debugPrint('Receipt selection error: $e');

      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      _snack(
        'Could not select the receipt. Please try again.',
        isError: true,
      );
    }
  }

  // ==========================================================================
  // OCR
  // ==========================================================================

  Future<void> _runOcr(File file) async {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _ocrRan = false;
      _ocrResult = null;
    });

    try {
      final String? text = await _ocr.extractTextFromFile(file);

      if (!mounted) return;

      if (text != null && text.trim().isNotEmpty) {
        final ReceiptParseResult result = ReceiptParser.parse(text);

        setState(() {
          _ocrResult = result;
          _ocrRan = true;

          // If OCR found an amount and user has not manually entered one,
          // put the detected amount into the editable amount field.
          if (result.amount != null &&
              _customCtrl.text.trim().isEmpty) {
            _customCtrl.text = result.amount!.toStringAsFixed(0);
            _selectedPreset = null;
          }

          // OCR detected transaction ID.
          if (result.transactionId != null &&
              result.transactionId!.trim().isNotEmpty) {
            _txnIdCtrl.text = result.transactionId!;
          }

          // OCR detected payment method.
          if (result.paymentMethod != null &&
              _selectedPaymentMethod == null) {
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
      debugPrint('Receipt OCR error: $e');

      if (!mounted) return;

      setState(() {
        _ocrRan = true;
        _ocrResult = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  String? _validate() {
    final double? amt = _finalAmount;

    if (amt == null || amt < 10) {
      return 'Minimum donation amount is Rs. 10';
    }

    if (amt > 500000) {
      return 'Maximum single donation is Rs. 500,000';
    }

    if (_selectedPaymentMethod == null) {
      return 'Please select a payment method';
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    if (_cnicCtrl.text.trim().isEmpty) {
      return 'Please enter your CNIC number';
    }

    if (_receiptFile == null) {
      return 'Please upload your payment receipt';
    }

    return null;
  }

  // ==========================================================================
  // SUBMIT DONATION
  // ==========================================================================

  Future<void> _submit() async {
    final String? error = _validate();

    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    if (_receiptFile == null) {
      _snack(
        'Please upload your payment receipt',
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ------------------------------------------------------------
      // Upload receipt to Cloudinary
      // ------------------------------------------------------------

      final String? proofUrl =
      await _cloudinary.uploadImage(_receiptFile!);

      if (proofUrl == null || proofUrl.trim().isEmpty) {
        if (mounted) {
          _snack(
            'Screenshot upload failed. Please check your connection and try again.',
            isError: true,
          );

          setState(() {
            _isSubmitting = false;
          });
        }

        return;
      }

      // ------------------------------------------------------------
      // Pass confirmed amount/payment method to controller
      // ------------------------------------------------------------

      _controller.amountController.text =
          _finalAmount!.toStringAsFixed(0);

      _controller.selectedPaymentMethod.value =
      _selectedPaymentMethod!;

      // ------------------------------------------------------------
      // Submit donation
      // ------------------------------------------------------------

      final bool ok = await _controller.donateToCampaign(
        campaignId: _selectedCampaignId,
        campaignName: _selectedCampaignName,
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

      if (ok) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Donation submission error: $e');

      if (mounted) {
        _snack(
          'Something went wrong. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================

  void _snack(
      String msg, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==========================================================================
  // SUCCESS DIALOG
  // ==========================================================================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: _teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Donation Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your donation is pending review.\n'
                    'You will be notified once verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

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
            backgroundColor: _greenDark,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Donate Funds',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _greenDark,
                      _teal,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      56,
                      20,
                      16,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        _finalAmount != null
                            ? 'Rs. ${_finalAmount!.toStringAsFixed(0)}'
                            : 'Select Amount Below ↓',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Select Campaign (Optional)'),
                  const SizedBox(height: 12),
                  _buildCampaignSelector(),

                  const SizedBox(height: 24),

                  _sectionLabel('Select an Amount'),
                  const SizedBox(height: 12),
                  _buildAmountChips(),

                  const SizedBox(height: 12),
                  _buildCustomAmountField(),

                  const SizedBox(height: 24),

                  _sectionLabel('Your Details'),
                  const SizedBox(height: 12),
                  _buildDonorDetailsFields(),

                  const SizedBox(height: 24),

                  _sectionLabel('Payment Method'),
                  const SizedBox(height: 12),

                  PaymentMethodSelector(
                    selectedMethod: _selectedPaymentMethod,
                    onSelect: (method) {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                    },
                  ),

                  if (_selectedPaymentMethod != null) ...[
                    const SizedBox(height: 8),
                    PaymentAccountDetailsCard(
                      account: PaymentAccounts.byMethod(
                        _selectedPaymentMethod!,
                      )!,
                    ),
                  ],

                  const SizedBox(height: 24),

                  _sectionLabel('Upload Payment Receipt'),
                  const SizedBox(height: 12),
                  _buildReceiptSection(),

                  if (_ocrRan) ...[
                    const SizedBox(height: 16),
                    _buildOcrResultCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildDonateButton(),
    );
  }

  // ==========================================================================
  // SECTION LABEL
  // ==========================================================================

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  // ==========================================================================
  // CAMPAIGN SELECTOR
  // ==========================================================================

  Widget _buildCampaignSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.campaignsStream,
      builder: (context, snapshot) {
        final campaigns = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedCampaignId,
              isExpanded: true,
              hint: const Text(
                'General Fund (No specific campaign)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'General Fund (No specific campaign)',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ...campaigns.map((doc) {
                  final data =
                  doc.data() as Map<String, dynamic>;

                  return DropdownMenuItem<String?>(
                    value: doc.id,
                    child: Text(
                      data['title'] ?? 'Untitled Campaign',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCampaignId = value;

                  if (value == null) {
                    _selectedCampaignName = null;
                  } else {
                    final doc = campaigns.firstWhere(
                          (d) => d.id == value,
                    );

                    final data =
                    doc.data() as Map<String, dynamic>;

                    _selectedCampaignName =
                        data['title'] ??
                            'Untitled Campaign';
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // AMOUNT CHIPS
  // ==========================================================================

  Widget _buildAmountChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presets.map((amt) {
        final bool isSelected =
            _selectedPreset == amt.toDouble() &&
                _customCtrl.text.isEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPreset = amt.toDouble();
              _customCtrl.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? _green
                  : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isSelected
                    ? _green
                    : Colors.grey[300]!,
              ),
            ),
            child: Text(
              amt >= 1000
                  ? 'Rs. ${(amt / 1000).toStringAsFixed(0)}K'
                  : 'Rs. $amt',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF333333),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================================================
  // CUSTOM AMOUNT
  // ==========================================================================

  Widget _buildCustomAmountField() {
    return TextField(
      controller: _customCtrl,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
      ),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      onChanged: (_) {
        setState(() {
          _selectedPreset = null;
        });
      },
      decoration: InputDecoration(
        hintText: 'Enter custom amount',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _green,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DONOR DETAILS
  // ==========================================================================

  Widget _buildDonorDetailsFields() {
    return Column(
      children: [
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Phone Number *',
            prefixIcon: const Icon(
              Icons.phone_outlined,
              size: 18,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _cnicCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'CNIC Number *',
            prefixIcon: const Icon(
              Icons.badge_outlined,
              size: 18,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // RECEIPT SECTION
  // ==========================================================================

  Widget _buildReceiptSection() {
    if (_isScanning) {
      return _loadingCard(
        'Scanning your payment receipt...',
      );
    }

    if (_receiptFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _receiptFile!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFE8F5E9),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: _green,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),

          // Remove receipt
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _receiptFile = null;
                  _ocrRan = false;
                  _ocrResult = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // Change receipt
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _green.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: _green,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload Payment Receipt',
              style: TextStyle(
                color: _green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // LOADING CARD
  // ==========================================================================

  Widget _loadingCard(String message) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: _green,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // OCR RESULT CARD
  // ==========================================================================

  Widget _buildOcrResultCard() {
    final bool hasData =
        _ocrResult?.hasAnyData ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasData
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFFF3E4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? const Color(0xFF2563EB)
              .withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasData
                    ? Icons.auto_awesome_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: hasData
                    ? const Color(0xFF2563EB)
                    : Colors.orange[700],
              ),
              const SizedBox(width: 6),
              Text(
                hasData
                    ? 'OCR Detected — Please Confirm'
                    : 'Could not read receipt automatically',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: hasData
                      ? const Color(0xFF2563EB)
                      : Colors.orange[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'This is only text extracted from your image — '
                'it does not confirm the payment was received. '
                'You can correct any field below.',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 12),

          _editableRow(
            'Amount',
            _customCtrl,
            prefixText: 'Rs. ',
          ),

          const SizedBox(height: 10),

          _editableRow(
            'Transaction ID',
            _txnIdCtrl,
          ),

          if (_ocrResult?.paymentDate != null) ...[
            const SizedBox(height: 10),
            Text(
              'Detected date: ${_ocrResult!.paymentDate}',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // EDITABLE OCR FIELD
  // ==========================================================================

  Widget _editableRow(
      String label,
      TextEditingController ctrl, {
        String? prefixText,
      }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        TextField(
          controller: ctrl,
          style: const TextStyle(
            fontSize: 13,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DONATE BUTTON
  // ==========================================================================

  Widget _buildDonateButton() {
    final bool hasAll =
        _finalAmount != null &&
            _finalAmount! >= 10 &&
            _selectedPaymentMethod != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed:
          (_isSubmitting || !hasAll)
              ? null
              : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            disabledBackgroundColor:
            Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(32),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Text(
            _finalAmount != null
                ? 'Donate Rs. ${_finalAmount!.toStringAsFixed(0)}'
                : 'Donate Now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}