// ============================================================
// FILE: lib/screens/donor/donate_funds_screen.dart
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/jazzcash_service.dart';
import '../../services/donation_service.dart';
import 'jazzcash_webview_screen.dart';

class DonateFundsScreen extends StatefulWidget {
  const DonateFundsScreen({super.key});

  @override
  State<DonateFundsScreen> createState() => _DonateFundsScreenState();
}

class _DonateFundsScreenState extends State<DonateFundsScreen> {
  // ── Services ─────────────────────────────────────────────────────────────
  final _jcService  = JazzCashService();
  final _donService = DonationService();
  final _picker     = ImagePicker();

  // ── Brand colors ──────────────────────────────────────────────────────────
  static const Color _green     = Color(0xFF1B6B3A);
  static const Color _greenDark = Color(0xFF145230);
  static const Color _teal      = Color(0xFF00BFA5);
  static const Color _bg        = Color(0xFFF2F4F8);

  // ── State ─────────────────────────────────────────────────────────────────
  String? _selectedCause;
  double? _selectedPreset;
  final _customCtrl  = TextEditingController();
  String _method     = 'jazzcash'; // 'jazzcash' | 'manual'
  final _txnIdCtrl   = TextEditingController();
  File?  _screenshot;
  bool   _processing = false;

  // ── Causes list ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _causes = [
    {
      'name': 'Educate a Child',
      'icon': Icons.school_rounded,
      'grad': [Color(0xFF1565C0), Color(0xFF42A5F5)],
    },
    {
      'name': 'Health Fund',
      'icon': Icons.favorite_rounded,
      'grad': [Color(0xFFC62828), Color(0xFFEF9A9A)],
    },
    {
      'name': 'Food Drive',
      'icon': Icons.restaurant_rounded,
      'grad': [Color(0xFFE65100), Color(0xFFFFCC80)],
    },
    {
      'name': 'Shelter Support',
      'icon': Icons.home_rounded,
      'grad': [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
    },
    {
      'name': 'Green Earth',
      'icon': Icons.eco_rounded,
      'grad': [Color(0xFF2E7D32), Color(0xFFA5D6A7)],
    },
    {
      'name': 'Others',
      'icon': Icons.volunteer_activism_rounded,
      'grad': [Color(0xFF37474F), Color(0xFFB0BEC5)],
    },
  ];

  // ── Preset amounts ────────────────────────────────────────────────────────
  final List<int> _presets = [500, 1000, 5000, 10000, 50000];

  @override
  void dispose() {
    _customCtrl.dispose();
    _txnIdCtrl.dispose();
    super.dispose();
  }

  // ── Active amount (custom overrides preset) ───────────────────────────────
  double? get _finalAmount {
    if (_customCtrl.text.trim().isNotEmpty) {
      return double.tryParse(_customCtrl.text.trim());
    }
    return _selectedPreset;
  }

  // ── Generate unique transaction ref ──────────────────────────────────────
  String _makeTxnRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'U000';
    final ts  = DateTime.now().millisecondsSinceEpoch.toString();
    final raw = 'T${uid.substring(0, uid.length.clamp(0, 4))}$ts';
    return raw.substring(0, raw.length.clamp(0, 20));
  }

  // ==========================================================================
  // VALIDATE FORM
  // ==========================================================================
  String? _validate() {
    if (_selectedCause == null) {
      return 'Please select a cause to donate to';
    }
    final amt = _finalAmount;
    if (amt == null || amt < 10) {
      return 'Minimum donation amount is PKR 10';
    }
    if (amt > 500000) {
      return 'Maximum single donation is PKR 500,000';
    }
    if (_method == 'manual' && _txnIdCtrl.text.trim().isEmpty) {
      return 'Please enter your Transaction ID';
    }
    return null; // valid
  }

  // ==========================================================================
  // SUBMIT — JazzCash or Manual
  // ==========================================================================
  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      _snack(err, isError: true);
      return;
    }

    setState(() => _processing = true);

    if (_method == 'jazzcash') {
      await _doJazzCash();
    } else {
      await _doManual();
    }

    if (mounted) setState(() => _processing = false);
  }

  // ── JazzCash flow ─────────────────────────────────────────────────────────
  Future<void> _doJazzCash() async {
    final url = JazzCashService.getPaymentUrl(
      amount: _finalAmount!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JazzCashWebViewScreen(url: url),
      ),
    );
  }

  // ── Manual payment flow ───────────────────────────────────────────────────
  Future<void> _doManual() async {
    String screenshotUrl = '';

    if (_screenshot != null) {
      _snack('Uploading screenshot...');
      final url = await _donService.uploadScreenshot(_screenshot!);
      screenshotUrl = url ?? '';
    }

    final ok = await _donService.saveManualDonation(
      cause:         _selectedCause!,
      amount:        _finalAmount!,
      transactionId: _txnIdCtrl.text.trim(),
      screenshotUrl: screenshotUrl,
    );

    if (!mounted) return;

    if (ok) {
      _showManualSuccessDialog();
    } else {
      _snack('Failed to save donation. Please try again.', isError: true);
    }
  }

  // ── SnackBar helper ────────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : _green,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 3 : 2),
    ));
  }

  // ── Manual donation success dialog ────────────────────────────────────────
  void _showManualSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
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
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 44, color: Color(0xFF00BFA5)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Donation Submitted!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your manual donation is pending\nadmin verification (within 24 hours).',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
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
          // ── Gradient SliverAppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            stretch: true,
            backgroundColor: _greenDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Donate Funds',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_greenDark, _teal],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'You are donating',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        // Live amount preview — updates as user selects
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(
                                  opacity: anim, child: child),
                          child: Text(
                            _finalAmount != null
                                ? 'PKR ${_finalAmount!.toStringAsFixed(0)}'
                                : 'Select Amount Below ↓',
                            key: ValueKey(_finalAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (_selectedCause != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'for $_selectedCause',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Causes
                  _sectionLabel('Select a Cause'),
                  const SizedBox(height: 12),
                  _buildCauseGrid(),

                  const SizedBox(height: 24),

                  // 2. Amount
                  _sectionLabel('Select an Amount'),
                  const SizedBox(height: 12),
                  _buildAmountChips(),
                  const SizedBox(height: 12),
                  _buildCustomAmountField(),

                  const SizedBox(height: 24),

                  // 3. Payment Method
                  _sectionLabel('Payment Method'),
                  const SizedBox(height: 12),
                  _buildPaymentCards(),

                  // 4. Manual fields (only when manual is selected)
                  if (_method == 'manual') ...[
                    const SizedBox(height: 20),
                    _buildManualFields(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating Donate Now button ────────────────────────────────────
      bottomNavigationBar: _buildDonateButton(),
    );
  }

  // ==========================================================================
  // UI WIDGETS
  // ==========================================================================

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A1A1A),
    ),
  );

  // ── Cause tiles 3-column grid ─────────────────────────────────────────────
  Widget _buildCauseGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: _causes.map((cause) {
        final isSelected = _selectedCause == cause['name'];
        final grads = cause['grad'] as List<Color>;

        return GestureDetector(
          onTap: () => setState(() => _selectedCause = cause['name'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isSelected
                  ? LinearGradient(
                colors: grads,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : Colors.white,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: grads[0].withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : grads[0].withOpacity(0.10),
                  ),
                  child: Icon(
                    cause['icon'] as IconData,
                    size: 22,
                    color: isSelected ? Colors.white : grads[0],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cause['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Amount preset chips ───────────────────────────────────────────────────
  Widget _buildAmountChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presets.map((amt) {
        final isSelected =
            _selectedPreset == amt.toDouble() &&
                _customCtrl.text.isEmpty;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedPreset = amt.toDouble();
            _customCtrl.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _green : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isSelected ? _green : Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: _green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                )
              ],
            ),
            child: Text(
              amt >= 1000
                  ? 'PKR ${(amt / 1000).toStringAsFixed(0)}K'
                  : 'PKR $amt',
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

  // ── Custom amount text field ──────────────────────────────────────────────
  Widget _buildCustomAmountField() {
    return TextField(
      controller: _customCtrl,
      keyboardType:
      const TextInputType.numberWithOptions(decimal: false),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      onChanged: (_) => setState(() => _selectedPreset = null),
      decoration: InputDecoration(
        hintText: 'Enter custom amount (e.g. 2500)',
        hintStyle:
        const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'PKR',
            style: TextStyle(
              color: Color(0xFF1B6B3A),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFF1B6B3A), width: 1.5),
        ),
      ),
    );
  }

  // ── Payment method cards ──────────────────────────────────────────────────
  Widget _buildPaymentCards() {
    return Column(
      children: [
        _payCard(
          value: 'jazzcash',
          title: 'JazzCash',
          subtitle: 'Pay securely via JazzCash gateway',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFFCC0000),
          badge: 'Sandbox',
        ),
        const SizedBox(height: 10),
        _payCard(
          value: 'manual',
          title: 'Manual Payment',
          subtitle: 'Bank transfer with receipt proof',
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF1565C0),
        ),
      ],
    );
  }

  Widget _payCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    String? badge,
  }) {
    final isSelected = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _green.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _green : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(isSelected ? 0.06 : 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected
                              ? _green
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? _green : Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Manual payment fields ─────────────────────────────────────────────────
  Widget _buildManualFields() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.orange[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transfer to:\nJazzCash: 0300-0000000\nAccount: DonateHub\nThen enter your Transaction ID below.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transaction ID
          const Text(
            'Transaction ID *',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _txnIdCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. JC20240001234',
              hintStyle: const TextStyle(
                  color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.tag_rounded,
                  color: Colors.grey, size: 18),
              filled: true,
              fillColor: const Color(0xFFF4F6F8),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1B6B3A), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Screenshot upload
          const Text(
            'Upload Screenshot (Optional)',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          _screenshot != null
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _screenshot!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _screenshot = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          )
              : GestureDetector(
            onTap: _pickScreenshot,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to upload screenshot',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating bottom donate button ─────────────────────────────────────────
  Widget _buildDonateButton() {
    final hasAll = _selectedCause != null &&
        _finalAmount != null &&
        _finalAmount! >= 10;

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
          onPressed: (_processing || !hasAll) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32)),
            elevation: 0,
          ),
          child: _processing
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _method == 'jazzcash'
                    ? Icons.account_balance_wallet_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _finalAmount != null
                    ? 'Donate PKR ${_finalAmount!.toStringAsFixed(0)}'
                    : 'Donate Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Screenshot picker bottom sheet ────────────────────────────────────────
  Future<void> _pickScreenshot() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Upload Screenshot',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _srcButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: _green,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final f = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80);
                      if (f != null) {
                        setState(
                                () => _screenshot = File(f.path));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _srcButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final f = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80);
                      if (f != null) {
                        setState(
                                () => _screenshot = File(f.path));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _srcButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}