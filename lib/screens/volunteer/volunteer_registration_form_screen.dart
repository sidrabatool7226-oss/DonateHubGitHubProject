import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

// ==========================================================================
// CNIC FORMATTER — Auto adds dashes: XXXXX-XXXXXXX-X
// ==========================================================================
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) formatted += '-';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class VolunteerRegistrationFormScreen extends StatefulWidget {
  const VolunteerRegistrationFormScreen({super.key});

  @override
  State<VolunteerRegistrationFormScreen> createState() =>
      _VolunteerRegistrationFormScreenState();
}

class _VolunteerRegistrationFormScreenState
    extends State<VolunteerRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  static const Color _green = Color(0xFF1B6B3A);
  static const Color _lightGreen = Color(0xFF2D8A52);
  static const Color _bg = Color(0xFFF4F6F8);

  // ── Controllers ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _permCityCtrl = TextEditingController();
  final _permStateCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────
  File? _profileImage;
  File? _cnicFrontImage; // NEW
  File? _cnicBackImage; // NEW
  bool _isUploading = false;
  bool _isSubmitting = false;

  String? _selectedWorkCity;
  String? _selectedBloodGroup;
  DateTime? _selectedDob;
  final List<String> _selectedRoles = [];

  // ── Dropdown Data ────────────────────────────────────────────────────
  final List<String> _workCities = const [
    'Islamabad', 'Rawalpindi', 'Lahore', 'Bahawalpur', 'Sargodha',
    'Multan', 'Wah Cantt', 'Taxila', 'Faisalabad', 'Okara',
    'Karachi', 'Peshawar', 'Skardu',
  ];

  final List<String> _bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // CHANGED: New role list per supervisor's requirement — replaces the
  // old marketing/content-oriented roles entirely.
  final List<String> _availableRoles = const [
    'Volunteering & Management',
    'Emergency Response',
    'Blood Donation',
    'Relief Distribution',
    'Medical Camps',
    'Ration Drive',
    'Teaching',
    'Event Management',
    'Resource Pickup',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _permCityCtrl.dispose();
    _permStateCtrl.dispose();
    _fatherNameCtrl.dispose();
    _dobCtrl.dispose();
    _degreeCtrl.dispose();
    _universityCtrl.dispose();
    _cnicCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  // ==========================================================================
  // PICK PROFILE PICTURE
  // ==========================================================================
  Future<void> _pickProfileImage() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // ==========================================================================
  // NEW — PICK CNIC FRONT/BACK IMAGES
  // ==========================================================================
  Future<void> _pickCnicImage({required bool isFront}) async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _cnicFrontImage = File(picked.path);
        } else {
          _cnicBackImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _pickCnicImageFromGallery({required bool isFront}) async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _cnicFrontImage = File(picked.path);
        } else {
          _cnicBackImage = File(picked.path);
        }
      });
    }
  }

  void _showCnicSourceSheet({required bool isFront}) {
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(isFront ? 'Upload CNIC Front' : 'Upload CNIC Back',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(ctx); _pickCnicImage(isFront: isFront); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: _green.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _green.withOpacity(0.3))),
                      child: Column(children: [
                        const Icon(Icons.camera_alt_rounded, color: _green, size: 30),
                        const SizedBox(height: 8),
                        const Text('Camera', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(ctx); _pickCnicImageFromGallery(isFront: isFront); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3))),
                      child: Column(children: [
                        const Icon(Icons.photo_library_rounded, color: Color(0xFF1565C0), size: 30),
                        const SizedBox(height: 8),
                        const Text('Gallery', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                      ]),
                    ),
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

  // ==========================================================================
  // PICK DATE OF BIRTH
  // ==========================================================================
  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  // ==========================================================================
  // TOGGLE ROLE SELECTION
  // ==========================================================================
  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
    });
  }

  // ==========================================================================
  // SUBMIT FORM
  // ==========================================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImage == null) {
      _showSnack('Please add a profile picture', isError: true);
      return;
    }
    if (_selectedWorkCity == null) {
      _showSnack('Please select preferred work city', isError: true);
      return;
    }
    if (_selectedBloodGroup == null) {
      _showSnack('Please select blood group', isError: true);
      return;
    }
    if (_selectedDob == null) {
      _showSnack('Please select date of birth', isError: true);
      return;
    }
    if (_selectedRoles.isEmpty) {
      _showSnack('Please select at least one role', isError: true);
      return;
    }
    // NEW — CNIC images required
    if (_cnicFrontImage == null || _cnicBackImage == null) {
      _showSnack('Please upload both sides of your CNIC', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      setState(() => _isUploading = true);
      String? profilePicUrl = await _cloudinary.uploadImage(_profileImage!);
      String? cnicFrontUrl = await _cloudinary.uploadImage(_cnicFrontImage!); // NEW
      String? cnicBackUrl = await _cloudinary.uploadImage(_cnicBackImage!); // NEW
      setState(() => _isUploading = false);

      if (cnicFrontUrl == null || cnicBackUrl == null) {
        setState(() => _isSubmitting = false);
        _showSnack('CNIC upload failed. Please check your connection and try again.', isError: true);
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email ?? _emailCtrl.text.trim();

      if (uid == null) {
        _showSnack('You must be logged in to submit this form.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'role': 'volunteer',
        'name': _nameCtrl.text.trim(),
        'email': email,
        'phone': _phoneCtrl.text.trim(),
        'fatherName': _fatherNameCtrl.text.trim(),
        'permanentCity': _permCityCtrl.text.trim(),
        'permanentState': _permStateCtrl.text.trim(),
        'workCity': _selectedWorkCity,
        'dob': _dobCtrl.text.trim(),
        'degree': _degreeCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'cnic': _cnicCtrl.text.trim(),
        'cnicFrontUrl': cnicFrontUrl, // NEW — matches existing field name already expected by Manager UI
        'cnicBackUrl': cnicBackUrl, // NEW
        'categories': _selectedRoles,
        'pastExperience': _experienceCtrl.text.trim(), // stays optional — empty string allowed
        'profilePicUrl': profilePicUrl ?? '',
        'verificationStage': 'Pending',
        'status': 'pending',
        'isProfileComplete': true,
        'isOnline': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isUploading = false;
      });
      _showSnack('Submission failed. Please try again.', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _green, size: 42),
              ),
              const SizedBox(height: 16),
              const Text(
                'Form Submitted Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application is under review. A manager will schedule your interview soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/verification_status', (r) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==========================================================================
  // BUILD UI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _green,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, _lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism_rounded,
                            color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Volunteer Registration',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fill in your details to join our volunteer team',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Form Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Picture ────────────────────────────
                    Center(child: _buildProfilePicPicker()),
                    const SizedBox(height: 20),

                    // ── Personal Info Card ──────────────────────────
                    _SectionCard(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _field(
                          label: 'Full Name *',
                          controller: _nameCtrl,
                          hint: 'Enter your full name',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          label: "Father's Name *",
                          controller: _fatherNameCtrl,
                          hint: "Enter father's name",
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Father's name is required"
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDob,
                                child: AbsorbPointer(
                                  child: _field(
                                    label: 'Date of Birth *',
                                    controller: _dobCtrl,
                                    hint: 'MM/DD/YYYY',
                                    suffixIcon: Icons.calendar_today_outlined,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dropdown(
                                label: 'Blood Group *',
                                value: _selectedBloodGroup,
                                items: _bloodGroups,
                                hint: 'Select',
                                onChanged: (v) =>
                                    setState(() => _selectedBloodGroup = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Contact Info Card ────────────────────────────
                    _SectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      children: [
                        _field(
                          label: 'Email Address *',
                          controller: _emailCtrl,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final regex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!regex.hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          label: 'Phone Number *',
                          controller: _phoneCtrl,
                          hint: '03001234567',
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (v.trim().length < 10) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                label: 'Permanent City *',
                                controller: _permCityCtrl,
                                hint: 'City',
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                label: 'State / Province *',
                                controller: _permStateCtrl,
                                hint: 'State/Region',
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Work Preference Card ─────────────────────────
                    _SectionCard(
                      title: 'Work Preference',
                      icon: Icons.location_city_outlined,
                      children: [
                        _dropdown(
                          label: 'Preferred City to Work In *',
                          value: _selectedWorkCity,
                          items: _workCities,
                          hint: 'Select a city',
                          onChanged: (v) =>
                              setState(() => _selectedWorkCity = v),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Volunteer Roles * (Select all that apply)',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableRoles.map((role) {
                            final isSel = _selectedRoles.contains(role);
                            return GestureDetector(
                              onTap: () => _toggleRole(role),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? _green
                                      : const Color(0xFFF4F6F8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel
                                        ? _green
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSel
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Education & Identity Card ─────────────────────
                    _SectionCard(
                      title: 'Education & Identity',
                      icon: Icons.badge_outlined,
                      children: [
                        _field(
                          label: 'Degree / Designation *',
                          controller: _degreeCtrl,
                          hint: 'e.g. BSCS, Student',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          label: 'University / Organization *',
                          controller: _universityCtrl,
                          hint: 'Enter institute name',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          label: 'CNIC Number *',
                          controller: _cnicCtrl,
                          hint: '00000-0000000-0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_CnicFormatter()],
                          maxLength: 15,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'CNIC is required';
                            }
                            if (v.trim().length != 15) {
                              return 'Enter complete CNIC (13 digits)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // NEW — CNIC image upload
                        const Text(
                          'CNIC Photo Verification *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take clear photos of both sides of your CNIC',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _cnicImageTile(image: _cnicFrontImage, label: 'Front Side', isFront: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _cnicImageTile(image: _cnicBackImage, label: 'Back Side', isFront: false)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Experience Card ────────────────────────────
                    _SectionCard(
                      title: 'Experience',
                      icon: Icons.work_history_outlined,
                      children: [
                        _field(
                          label: 'Past Working Experience (optional)',
                          controller: _experienceCtrl,
                          hint: 'Mention any organizations you worked with',
                          maxLines: 3,
                          // No validator — remains fully optional
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Submit Button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploading
                                  ? 'Uploading documents...'
                                  : 'Submitting...',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                            : const Text(
                          'Submit Application',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PROFILE PICTURE PICKER
  // ==========================================================================
  Widget _buildProfilePicPicker() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F5E9),
              border: Border.all(color: _green, width: 2.5),
            ),
            child: _profileImage != null
                ? ClipOval(
              child: Image.file(_profileImage!,
                  width: 100, height: 100, fit: BoxFit.cover),
            )
                : const Icon(Icons.person_add_alt_1_rounded,
                color: _green, size: 40),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // NEW — CNIC IMAGE TILE
  // ==========================================================================
  Widget _cnicImageTile({required File? image, required String label, required bool isFront}) {
    return GestureDetector(
      onTap: () => _showCnicSourceSheet(isFront: isFront),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: image != null ? _green : Colors.grey.shade300, width: image != null ? 1.5 : 1),
        ),
        child: image != null
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(image, width: double.infinity, height: 110, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 4, left: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_rounded, color: Colors.grey[400], size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 2),
            Text('Tap to capture', style: TextStyle(color: Colors.grey[400], fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // REUSABLE FIELD WIDGET
  // ==========================================================================
  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    IconData? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 18, color: Colors.grey[400])
                : null,
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF4F6F8),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // REUSABLE DROPDOWN WIDGET
  // ==========================================================================
  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey[500]),
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1A1A)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: items
                  .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// SECTION CARD WRAPPER
// ==========================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  static const Color _green = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: _green),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}