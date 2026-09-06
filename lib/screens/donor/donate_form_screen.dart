// ============================================================
// FILE: lib/screens/donor/donate_form_screen.dart
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

class DonationFormScreen extends StatefulWidget {
  final String selectedCategory;
  const DonationFormScreen({
    super.key,
    required this.selectedCategory,
  });

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _itemNameCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cnicCtrl = TextEditingController();

  List<File> _pickedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImage = false;

  String _selectedCondition = 'Good';
  String _selectedLogistics = 'pickup';
  String? _selectedCampaign;
  List<String> _campaignNames = [];
  bool _isLoadingCampaigns = true;
  bool _isPosting = false;

  File? _receiptImage;
  String? _receiptImageUrl;
  bool _isUploadingReceipt = false;

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _bgGray = Color(0xFFF4F6F8);

  final List<String> _conditions = ['New', 'Fair', 'Unused', 'Good'];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    final names = await _firestoreService.getCampaignNames();
    final requestedCampaigns = [
      'School Uniforms & Tracksuits',
      '🛏️ Comfortable Bedding for Children',
      '🥫 Monthly Grocery & Food Support',
      '❄️ Winter Ration & Essentials Drive',
      '👕 Eid Clothes & Shoes Drive',
      '🎁 Eid Gifts & Eidi for Children',
      '🍽️ Eid Meals & Sweet Treats',
      '🧴 Daily Essentials & Care Packages',
      '📚 Education Support for Orphans',
      'Others',
    ];

    final allCampaigns = [...names];
    for (final campaign in requestedCampaigns) {
      if (!allCampaigns.contains(campaign)) {
        allCampaigns.add(campaign);
      }
    }

    setState(() {
      _campaignNames = allCampaigns;
      _selectedCampaign = allCampaigns.isNotEmpty ? allCampaigns.first : null;
      _isLoadingCampaigns = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _pickedImages.add(file);
        _isUploadingImage = true;
      });

      final url = await _cloudinaryService.uploadImage(file);

      setState(() {
        _isUploadingImage = false;
        if (url != null) {
          _uploadedImageUrls.add(url);
        }
      });

      if (url == null && mounted) {
        _showSnack('Image upload failed. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnack('Could not pick image. Check permissions.', isError: true);
    }
  }

  void _showImageSourceSheet() {
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
            const SizedBox(height: 16),
            const Text(
              'Select Photo Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _sourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: _green,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption({
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
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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

  Future<void> _pickReceiptImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _receiptImage = file;
        _isUploadingReceipt = true;
      });

      final url = await _cloudinaryService.uploadImage(file);

      setState(() {
        _isUploadingReceipt = false;
        _receiptImageUrl = url;
      });

      if (url == null && mounted) {
        _showSnack('Receipt upload failed. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _isUploadingReceipt = false);
      _showSnack('Could not pick receipt image.', isError: true);
    }
  }

  Future<void> _postDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrls.isEmpty && _pickedImages.isEmpty) {
      _showSnack('Please add at least one photo.', isError: true);
      return;
    }

    if (_isUploadingImage) {
      _showSnack('Please wait for image upload to finish.', isError: true);
      return;
    }

    setState(() => _isPosting = true);

    final result = await _firestoreService.saveDonation(
      itemName: _itemNameCtrl.text,
      category: widget.selectedCategory,
      quantity: _quantityCtrl.text.isEmpty ? '1' : _quantityCtrl.text,
      description: _descriptionCtrl.text,
      campaignName: _selectedCampaign ?? 'No specific campaign',
      logisticsType: _selectedLogistics,
      address: _addressCtrl.text,
      imageUrls: _uploadedImageUrls,
      donorPhone: _phoneCtrl.text.trim(),
      donorCnic: _cnicCtrl.text.trim(),
      receiptImageUrl: _receiptImageUrl ?? '',
    );

    setState(() => _isPosting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSnack('Donation posted successfully! 🎉');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      _showSnack(result['message'], isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
            ),
          ),
        ),
        title: const Text(
          'New Donation',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 14),
              _buildPhotoSection(),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'What are you donating?',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    _buildFormField(
                      controller: _itemNameCtrl,
                      hint: 'e.g., winter jacket, canned food',
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Item name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Quantity'),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _quantityCtrl,
                      hint: 'e.g., 3 bags, 2 boxes',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Category'),
                    const SizedBox(height: 10),
                    _buildCategoryChips(),
                    const SizedBox(height: 16),

                    _fieldLabel('Campaign'),
                    const SizedBox(height: 8),
                    _buildCampaignDropdown(),
                    const SizedBox(height: 16),

                    _fieldLabel('Description'),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _descriptionCtrl,
                      hint:
                      "Tell us about the item's history, size, or expiration date",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Conditions'),
                    const SizedBox(height: 10),
                    _buildConditionChips(),
                    const SizedBox(height: 16),

                    // ── NEW: Donor Phone Number (mandatory) ────────────
                    _fieldLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _phoneCtrl,
                      hint: 'e.g., 03XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Phone number is required';
                        if (!RegExp(r'^03\d{9}$').hasMatch(value)) {
                          return 'Enter a valid 11-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── NEW: Donor CNIC (mandatory) ────────────────────
                    _fieldLabel('CNIC Number'),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _cnicCtrl,
                      hint: 'e.g., 1234512345671',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'CNIC is required';
                        if (!RegExp(r'^\d{13}$').hasMatch(value)) {
                          return 'Enter a valid 13-digit CNIC';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel('Delivery Method'),
                    const SizedBox(height: 8),
                    _buildLogisticsOptions(),

                    // ── CHANGED: Address only for Pickup, Receipt only
                    // for Online (Courier), nothing for Desk-based ──────
                    if (_selectedLogistics == 'pickup') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: _green, size: 20),
                          const SizedBox(width: 6),
                          _fieldLabel('Address'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildFormField(
                        controller: _addressCtrl,
                        hint: 'Enter your address or pickup location',
                        validator: (v) =>
                        (_selectedLogistics == 'pickup' &&
                            (v == null || v.trim().isEmpty))
                            ? 'Address is required'
                            : null,
                      ),
                    ] else if (_selectedLogistics == 'online') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: _green, size: 20),
                          const SizedBox(width: 6),
                          _fieldLabel('Upload Receipt'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildReceiptUpload(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _postDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 4,
                  ),
                  child: _isPosting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Post Donations',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _green,
                  width: 2,
                ),
              ),
              child: _isUploadingImage
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1B6B3A),
                  strokeWidth: 2.5,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: _green, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Upload\nPhotos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._pickedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            final bool uploaded = index < _uploadedImageUrls.length;

            return Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: uploaded
                          ? _green
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!uploaded)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _pickedImages.removeAt(index);
                        if (index < _uploadedImageUrls.length) {
                          _uploadedImageUrls.removeAt(index);
                        }
                      });
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceiptUpload() {
    return GestureDetector(
      onTap: _pickReceiptImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _receiptImageUrl != null
                ? _green
                : Colors.grey.shade300,
          ),
        ),
        child: _isUploadingReceipt
            ? const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Color(0xFF1B6B3A),
              strokeWidth: 2,
            ),
          ),
        )
            : Row(
          children: [
            Icon(
              _receiptImage != null
                  ? Icons.check_circle_rounded
                  : Icons.receipt_long_outlined,
              color: _green,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _receiptImage != null
                    ? 'Receipt selected — tap to change'
                    : 'Upload courier receipt',
                style: TextStyle(
                  color: _receiptImage != null
                      ? _green
                      : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: _receiptImage != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final List<String> allCategories = [
      'Food', 'Clothes', 'Books', 'Toys', 'Furniture', 'Others'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allCategories.map((cat) {
        final bool isSelected = cat == widget.selectedCategory;
        return Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? _green : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _green : Colors.grey[300]!,
            ),
          ),
          child: Text(
            cat,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 13,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampaignDropdown() {
    if (_isLoadingCampaigns) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Color(0xFF1B6B3A),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withOpacity(0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCampaign,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey),
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
          dropdownColor: Colors.white,
          items: _campaignNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCampaign = val),
        ),
      ),
    );
  }

  Widget _buildConditionChips() {
    return Row(
      children: _conditions.map((condition) {
        final bool isSelected = _selectedCondition == condition;
        return GestureDetector(
          onTap: () => setState(() => _selectedCondition = condition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _green : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _green : Colors.grey[300]!,
              ),
            ),
            child: Text(
              condition,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogisticsOptions() {
    final options = [
      {
        'value': 'online',
        'label': 'Online (Courier)',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'value': 'desk',
        'label': 'Desk-based (Drop-off)',
        'icon': Icons.store_outlined,
      },
      {
        'value': 'pickup',
        'label': 'Pickup by Volunteer',
        'icon': Icons.directions_bike_outlined,
      },
    ];

    return Column(
      children: options.map((opt) {
        final bool isSelected = _selectedLogistics == opt['value'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedLogistics = opt['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _green.withOpacity(0.08)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _green : Colors.grey[200]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  opt['icon'] as IconData,
                  color: isSelected ? _green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? _green
                          : const Color(0xFF1A1A1A),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? _green : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF1B6B3A), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
