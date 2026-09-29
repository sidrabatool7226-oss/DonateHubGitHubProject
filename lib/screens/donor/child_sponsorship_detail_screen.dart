// ============================================================
// FILE: lib/screens/donor/child_sponsorship_detail_screen.dart (NEW)
//
// PURPOSE
// Full/Partial sponsorship category picker for one child, plus
// payment submission. Reuses the EXACT same verification pipeline
// as donate_funds_screen.dart (OcrService, ReceiptParser,
// CloudinaryService, PaymentMethodSelector) — deliberately WITHOUT
// ImageCropper, matching donate_funds_screen.dart's fix (cropper
// caused an Android Activity/process restart there), not
// campaign_donation_sheet.dart's older pattern which still has it.
//
// On submit, SponsorshipController writes BOTH a 'sponsorships'
// record (the ongoing commitment) and a 'donations' record (this
// payment) — see that controller's file header for the full
// reasoning.
// ============================================================

import 'dart:io';
import 'dart:convert'; // NEW — for image hash
import 'package:crypto/crypto.dart'; // NEW — for image hash
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/sponsorship_controller.dart';
import '../../models/payment_account.dart';
import '../../models/sponsorship_categories.dart';
import '../../services/cloudinary_service.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../../widgets/payment_account_card.dart';

class ChildSponsorshipDetailScreen extends StatefulWidget {
  final String childId;
  final Map<String, dynamic> childData;

  const ChildSponsorshipDetailScreen({
    super.key,
    required this.childId,
    required this.childData,
  });

  @override
  State<ChildSponsorshipDetailScreen> createState() => _ChildSponsorshipDetailScreenState();
}

class _ChildSponsorshipDetailScreenState extends State<ChildSponsorshipDetailScreen> {
  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bg = Color(0xFFF4F6F8);

  late final SponsorshipController _controller;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final OcrService _ocr = OcrService();

  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _txnIdCtrl = TextEditingController();

  String _sponsorshipType = 'full'; // 'full' | 'partial'
  final Set<String> _selectedCategories = {};

  String? _selectedPaymentMethod;
  File? _receiptFile;
  bool _isScanning = false;
  bool _isSubmitting = false;

  ReceiptParseResult? _ocrResult;
  bool _ocrRan = false;

  bool _loadingProfile = true; // NEW

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SponsorshipController>()
        ? Get.find<SponsorshipController>()
        : Get.put(SponsorshipController());
    _loadDonorProfile(); // NEW
  }

  // NEW — same fix as donate_funds_screen.dart: phone/CNIC always come
  // from the donor's own profile, never retyped here.
  Future<void> _loadDonorProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null && mounted) {
          _phoneCtrl.text = (data['mobileNumber'] ?? '').toString();
          _cnicCtrl.text = (data['cnic'] ?? data['passportNumber'] ?? '').toString();
        }
      }
    } catch (_) {
      // Fields stay empty; _validate() below asks the donor to complete
      // their profile rather than letting an incomplete submission through.
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _txnIdCtrl.dispose();
    _ocr.dispose();
    super.dispose();
  }

  // ==========================================================================
  // DERIVED VALUES
  // ==========================================================================

  int get _monthlyAmount {
    if (_sponsorshipType == 'full') {
      return SponsorshipCategories.fullMonthlyAmount;
    }
    int total = 0;
    for (final cat in SponsorshipCategories.all) {
      if (_selectedCategories.contains(cat.name)) total += cat.monthlyAmount;
    }
    return total;
  }

  String get _childName => (widget.childData['title'] ?? 'this child').toString();

  // ==========================================================================
  // RECEIPT + OCR (mirrors donate_funds_screen.dart — no ImageCropper)
  // ==========================================================================

  Future<void> _pickReceipt() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;

      final File file = File(picked.path);
      if (!await file.exists()) {
        _snack('Selected image could not be accessed. Please try again.', isError: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _receiptFile = file;
        _ocrRan = false;
        _ocrResult = null;
      });

      await _runOcr(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      _snack('Could not select the receipt. Please try again.', isError: true);
    }
  }

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
        final result = ReceiptParser.parse(text);
        setState(() {
          _ocrResult = result;
          _ocrRan = true;
          if (result.transactionId != null && result.transactionId!.trim().isNotEmpty) {
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
      if (!mounted) return;
      setState(() {
        _ocrRan = true;
        _ocrResult = null;
      });
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ==========================================================================
  // VALIDATION + SUBMIT
  // ==========================================================================

  String? _validate() {
    if (_sponsorshipType == 'partial' && _selectedCategories.isEmpty) {
      return 'Please select at least one category to sponsor';
    }
    if (_selectedPaymentMethod == null) {
      return 'Please select a payment method';
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      return 'Please add your phone number in Profile before donating';
    }
    if (_cnicCtrl.text.trim().isEmpty) {
      return 'Please add your CNIC in Profile before donating';
    }
    if (_receiptFile == null) {
      return 'Please upload your payment receipt';
    }
    return null;
  }

  Future<void> _submit() async {
    final String? error = _validate();
    if (error != null) {
      _snack(error, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String? proofUrl = await _cloudinary.uploadImage(_receiptFile!);
      if (proofUrl == null || proofUrl.trim().isEmpty) {
        _snack('Screenshot upload failed. Please check your connection and try again.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // NEW — hash of the raw file bytes, for duplicate-screenshot detection.
      final String imageHash =
      sha256.convert(await _receiptFile!.readAsBytes()).toString();

      final List<String> categories = _sponsorshipType == 'full'
          ? SponsorshipCategories.all.map((c) => c.name).toList()
          : _selectedCategories.toList();

      final Map<String, int> categoryAmounts = {
        for (final name in categories) name: SponsorshipCategories.byName(name)?.monthlyAmount ?? 0,
      };

      final bool ok = await _controller.submitSponsorship(
        childId: widget.childId,
        childName: _childName,
        sponsorshipType: _sponsorshipType,
        selectedCategories: categories,
        categoryAmounts: categoryAmounts,
        monthlyAmount: _monthlyAmount,
        paymentMethod: _selectedPaymentMethod!,
        paymentProofUrl: proofUrl,
        transactionId: _txnIdCtrl.text.trim(),
        imageHash: imageHash, // NEW
        ocrAmount: _ocrResult?.amount,
        ocrTransactionId: _ocrResult?.transactionId,
        ocrPaymentMethod: _ocrResult?.paymentMethod,
        ocrPaymentDate: _ocrResult?.paymentDate,
        ocrProcessed: _ocrRan,
        donorPhone: _phoneCtrl.text.trim(),
        donorCnic: _cnicCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) _showSuccessDialog();
    } catch (e) {
      // TEMPORARY — was the generic message, hiding the real reason.
      _snack('Error: $e', isError: true);
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: _green, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sponsorship Submitted!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Rs. $_monthlyAmount/month sponsorship for $_childName is now awaiting verification.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close detail screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
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
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Sponsor $_childName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChildHeader(),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Your Details',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _textField(_phoneCtrl, 'Phone Number *', TextInputType.phone, readOnly: true),
                  const SizedBox(height: 10),
                  _textField(_cnicCtrl, 'CNIC Number *', TextInputType.number, readOnly: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Payment Method',
              icon: Icons.account_balance_wallet_outlined,
              child: Column(
                children: [
                  PaymentMethodSelector(
                    selectedMethod: _selectedPaymentMethod,
                    onSelect: (m) => setState(() => _selectedPaymentMethod = m),
                  ),
                  if (_selectedPaymentMethod != null) ...[
                    const SizedBox(height: 4),
                    PaymentAccountDetailsCard(account: PaymentAccounts.byMethod(_selectedPaymentMethod!)!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionCard(
              title: 'Payment Receipt (This Month)',
              icon: Icons.receipt_long_outlined,
              child: Column(
                children: [
                  _buildReceiptSection(),
                  if (_ocrRan) ...[
                    const SizedBox(height: 12),
                    _buildOcrResultCard(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // CHILD HEADER
  // ==========================================================================

  Widget _buildChildHeader() {
    final String imageUrl = (widget.childData['image'] ?? '').toString();
    final String age = (widget.childData['age'] ?? '').toString();
    final String bio = (widget.childData['description'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _green.withOpacity(0.25), width: 2),
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _headerPlaceholder(),
              )
                  : _headerPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_childName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (age.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('· $age', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.child_care_rounded, size: 40, color: _green),
    );
  }

  // ==========================================================================
  // FULL / PARTIAL TYPE SELECTOR
  // ==========================================================================

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            title: 'Full Sponsorship',
            subtitle: 'Rs. ${SponsorshipCategories.fullMonthlyAmount}/mo',
            icon: Icons.favorite_rounded,
            selected: _sponsorshipType == 'full',
            onTap: () => setState(() => _sponsorshipType = 'full'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            title: 'Partial Sponsorship',
            subtitle: 'Choose categories',
            icon: Icons.category_rounded,
            selected: _sponsorshipType == 'partial',
            onTap: () => setState(() => _sponsorshipType = 'partial'),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CATEGORY SECTION — Full summary OR Partial checkbox picker
  // ==========================================================================

  Widget _buildCategorySection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.activeSponsorshipsForChild(widget.childId),
      builder: (context, snapshot) {
        final activeDocs = snapshot.data?.docs ?? [];
        final allNames = SponsorshipCategories.all.map((c) => c.name).toList();
        final covered = SponsorshipController.coveredCategories(activeDocs, allNames);
        final currentCoverage = SponsorshipController.currentMonthlyCoverage(activeDocs);
        final int remaining =
        (SponsorshipCategories.fullMonthlyAmount - currentCoverage).clamp(0, SponsorshipCategories.fullMonthlyAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverageBar(currentCoverage, remaining),
            const SizedBox(height: 14),
            if (_sponsorshipType == 'full')
              _buildFullSummary(covered)
            else
              _buildPartialPicker(covered),
          ],
        );
      },
    );
  }

  Widget _buildCoverageBar(int currentCoverage, int remaining) {
    final double progress =
    (currentCoverage / SponsorshipCategories.fullMonthlyAmount).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rs. $currentCoverage',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _green),
              ),
              Text(' / Rs. ${SponsorshipCategories.fullMonthlyAmount} covered so far',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF4F6F8),
              valueColor: const AlwaysStoppedAnimation(_green),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0 ? 'Rs. $remaining/month still needed' : 'Fully sponsored — thank you!',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSummary(Set<String> covered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Full Sponsorship covers all 6 categories:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...SponsorshipCategories.all.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(_iconFor(cat.icon), size: 16, color: _green),
                const SizedBox(width: 8),
                Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 12.5))),
                Text('Rs. ${cat.monthlyAmount}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPartialPicker(Set<String> covered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ...SponsorshipCategories.all.map((cat) {
            final bool isCovered = covered.contains(cat.name);
            final bool isSelected = _selectedCategories.contains(cat.name);

            return GestureDetector(
              onTap: isCovered
                  ? null
                  : () => setState(() {
                if (isSelected) {
                  _selectedCategories.remove(cat.name);
                } else {
                  _selectedCategories.add(cat.name);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isCovered
                      ? const Color(0xFFF4F6F8)
                      : isSelected
                      ? _green.withOpacity(0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCovered
                        ? Colors.grey.shade200
                        : isSelected
                        ? _green
                        : Colors.grey.shade200,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCovered
                          ? Icons.check_circle_rounded
                          : isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: isCovered ? Colors.grey[400] : (isSelected ? _green : Colors.grey[400]),
                    ),
                    const SizedBox(width: 10),
                    Icon(_iconFor(cat.icon), size: 17, color: isCovered ? Colors.grey[400] : _green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isCovered ? Colors.grey[400] : const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (isCovered)
                            Text('Already sponsored by another donor',
                                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${cat.monthlyAmount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCovered ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 20),
          Row(
            children: [
              const Text('Your Monthly Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                'Rs. $_monthlyAmount',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'medical_services_rounded':
        return Icons.medical_services_rounded;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      case 'volunteer_activism_rounded':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.circle;
    }
  }

  // ==========================================================================
  // SHARED SECTION CARD / FIELD HELPERS
  // ==========================================================================

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: _green),
              const SizedBox(width: 7),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, TextInputType type, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      readOnly: readOnly,
      style: TextStyle(fontSize: 13, color: readOnly ? Colors.grey[600] : const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : const Color(0xFFF4F6F8),
        suffixIcon: readOnly ? Icon(Icons.lock_outline_rounded, size: 15, color: Colors.grey[400]) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildReceiptSection() {
    if (_isScanning) return _loadingBox('Scanning your payment receipt...');
    if (_receiptFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_receiptFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => setState(() {
                _receiptFile = null;
                _ocrRan = false;
                _ocrResult = null;
              }),
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
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(12),
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
    final bool hasData = _ocrResult?.hasAnyData ?? false;
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
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: hasData ? const Color(0xFF2563EB) : Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _txnIdCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Transaction ID',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
          'Submit Sponsorship — Rs. $_monthlyAmount/mo',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _green : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(selected ? 0.08 : 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : _green, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: selected ? Colors.white70 : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}