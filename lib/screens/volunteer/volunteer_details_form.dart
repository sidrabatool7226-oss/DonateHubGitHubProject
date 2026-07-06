import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class VolunteerDetailsForm extends StatefulWidget {
  const VolunteerDetailsForm({super.key});

  @override
  State<VolunteerDetailsForm> createState() => _VolunteerDetailsFormState();
}

class _VolunteerDetailsFormState extends State<VolunteerDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _organizationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _degreeController = TextEditingController();
  final _facebookController = TextEditingController();

  String _selectedCity = 'Islamabad';
  String _selectedBloodGroup = 'A+';
  DateTime? _selectedDOB;
  File? _profileImage;
  File? _cnicImage;

  final List<String> _selectedRoles = [];
  final List<String> _allRoles = [
    'Pickup & Delivery',
    'Teaching & Education',
    'Event Support',
    'Medical',
  ];

  final List<String> _cities = [
    'Islamabad', 'Rawalpindi', 'Lahore', 'Karachi', 'Peshawar'
  ];
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(picked.path);
        } else {
          _cnicImage = File(picked.path);
        }
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file, String folder) async {
    try {
      final cloudinary = CloudinaryPublic('your_cloud_name', 'your_upload_preset', cache: false);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: folder),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one role')),
      );
      return;
    }
    if (_profileImage == null || _cnicImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Profile Picture and CNIC')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final profileUrl = await _uploadToCloudinary(_profileImage!, 'volunteer_profiles');
      final cnicUrl = await _uploadToCloudinary(_cnicImage!, 'volunteer_cnics');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'city': _selectedCity,
        'dob': _selectedDOB?.toIso8601String(),
        'degree': _degreeController.text.trim(),
        'organization': _organizationController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'cnic': _cnicController.text.trim(),
        'roles': _selectedRoles,
        'experience': _experienceController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'profileImage': profileUrl,
        'cnicImage': cnicUrl,
        'status': 'pending',
        'isProfileComplete': true,
        'formSubmitted': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D6B), size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Form Submitted!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your application is under review. You will be notified once verified by the Manager.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D6B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/pending'),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D6B),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D6B), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildImagePicker(String label, File? file, bool isProfile) {
    return GestureDetector(
      onTap: () => _pickImage(isProfile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(
            color: file != null ? const Color(0xFF2E7D6B) : Colors.grey.shade300,
            width: file != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: file != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, height: 100, fit: BoxFit.cover),
        )
            : Column(
          children: [
            Icon(isProfile ? Icons.person : Icons.credit_card,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6B),
        title: const Text('Volunteer Registration',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D6B), Color(0xFF4CAF93)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.volunteer_activism, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    Text('Join Our Volunteer Team',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Fill in your details to get started',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Personal Info
              _sectionTitle('Personal Information'),
              _buildTextField('Full Name', _nameController),
              _buildTextField('Email', _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('Phone Number', _phoneController,
                  keyboardType: TextInputType.phone, hint: '03001234567'),
              _buildTextField('Father Name', _fatherNameController),
              _buildTextField('Permanent Address', _addressController),

              // City dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'City',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E7D6B), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: _cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
              ),

              // DOB
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDOB = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF2E7D6B), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDOB == null
                              ? 'Date of Birth'
                              : '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}',
                          style: TextStyle(
                            color: _selectedDOB == null
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Academic Info
              _sectionTitle('Academic & Professional Info'),
              _buildTextField('Degree / Designation', _degreeController),
              _buildTextField('University / Organization', _organizationController),

              // Blood group
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E7D6B), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: _bloodGroups
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                ),
              ),

              _buildTextField('CNIC Number', _cnicController,
                  hint: '37658657543223',
                  keyboardType: TextInputType.number),
              _buildTextField('Past Working Experience', _experienceController),
              _buildTextField('Facebook Profile Link', _facebookController),

              // Roles
              _sectionTitle('Select Your Role(s)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allRoles.map((role) {
                  final selected = _selectedRoles.contains(role);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected
                          ? _selectedRoles.remove(role)
                          : _selectedRoles.add(role);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2E7D6B)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2E7D6B)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 16),
                            ),
                          Text(
                            role,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Images
              _sectionTitle('Upload Documents'),
              const Text('Profile Picture',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildImagePicker('Tap to upload profile picture', _profileImage, true),
              const SizedBox(height: 12),
              const Text('CNIC Image',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildImagePicker('Tap to upload CNIC image', _cnicImage, false),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D6B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Application',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}