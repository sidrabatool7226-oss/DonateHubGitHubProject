// ============================================================
// FILE: lib/screens/auth/signup_screen.dart
//
// PREVIOUS FIXES (kept as-is):
//  FIX 1: Background white gap → scaffold bg + container wrap on image
//  FIX 2: Logo top spacing → 70
//  FIX 4: "Already have an account? login" link → bold vibrant green
//
// NEW CHANGES (this update):
//  - Username field added
//  - Country dropdown (Pakistan default) added
//  - Mobile Number field with auto country code prefix added
//  - Country-specific mobile validation added
//  - CNIC (Pakistan) / Passport Number (non-Pakistan) conditional field
//  - Confirm Password field + password strength hint added
//  - Password minimum length raised to 8
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

// ── Country data model (local to this file — no new files created) ───────
class _CountryOption {
  final String name;
  final String dialCode;
  final int minDigits;
  final int maxDigits;
  const _CountryOption(this.name, this.dialCode, this.minDigits, this.maxDigits);
}

const List<_CountryOption> _countries = [
  _CountryOption('Pakistan', '+92', 10, 10),
  _CountryOption('Afghanistan', '+93', 9, 9),
  _CountryOption('Australia', '+61', 9, 9),
  _CountryOption('Austria', '+43', 10, 11),
  _CountryOption('Bahrain', '+973', 8, 8),
  _CountryOption('Bangladesh', '+880', 10, 10),
  _CountryOption('Belgium', '+32', 9, 9),
  _CountryOption('Brazil', '+55', 10, 11),
  _CountryOption('Canada', '+1', 10, 10),
  _CountryOption('China', '+86', 11, 11),
  _CountryOption('Egypt', '+20', 10, 10),
  _CountryOption('France', '+33', 9, 9),
  _CountryOption('Germany', '+49', 10, 11),
  _CountryOption('India', '+91', 10, 10),
  _CountryOption('Indonesia', '+62', 10, 12),
  _CountryOption('Iran', '+98', 10, 10),
  _CountryOption('Iraq', '+964', 10, 10),
  _CountryOption('Ireland', '+353', 9, 9),
  _CountryOption('Italy', '+39', 9, 10),
  _CountryOption('Japan', '+81', 10, 10),
  _CountryOption('Jordan', '+962', 9, 9),
  _CountryOption('Kenya', '+254', 9, 9),
  _CountryOption('Kuwait', '+965', 8, 8),
  _CountryOption('Lebanon', '+961', 8, 8),
  _CountryOption('Malaysia', '+60', 9, 10),
  _CountryOption('Morocco', '+212', 9, 9),
  _CountryOption('Nepal', '+977', 10, 10),
  _CountryOption('Netherlands', '+31', 9, 9),
  _CountryOption('New Zealand', '+64', 8, 9),
  _CountryOption('Nigeria', '+234', 10, 10),
  _CountryOption('Norway', '+47', 8, 8),
  _CountryOption('Oman', '+968', 8, 8),
  _CountryOption('Philippines', '+63', 10, 10),
  _CountryOption('Poland', '+48', 9, 9),
  _CountryOption('Qatar', '+974', 8, 8),
  _CountryOption('Russia', '+7', 10, 10),
  _CountryOption('Saudi Arabia', '+966', 9, 9),
  _CountryOption('Singapore', '+65', 8, 8),
  _CountryOption('South Africa', '+27', 9, 9),
  _CountryOption('South Korea', '+82', 9, 10),
  _CountryOption('Spain', '+34', 9, 9),
  _CountryOption('Sri Lanka', '+94', 9, 9),
  _CountryOption('Sweden', '+46', 7, 9),
  _CountryOption('Switzerland', '+41', 9, 9),
  _CountryOption('Thailand', '+66', 9, 9),
  _CountryOption('Turkey', '+90', 10, 10),
  _CountryOption('UAE', '+971', 9, 9),
  _CountryOption('United Kingdom', '+44', 10, 10),
  _CountryOption('United States', '+1', 10, 10),
  _CountryOption('Yemen', '+967', 9, 9),
];

// ── CNIC formatter — auto adds dashes: XXXXX-XXXXXXX-X ─────────────────────
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController(); // NEW
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController(); // NEW
  final TextEditingController _cnicController = TextEditingController(); // NEW
  final TextEditingController _passportController = TextEditingController(); // NEW
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // NEW

  String _selectedRole = 'donor';
  _CountryOption _selectedCountry = _countries.first; // Pakistan default — NEW
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true; // NEW
  bool _isSigningUp = false;
  bool _isGoogleLoading = false;

  // NEW — password strength
  String _strengthText = '';
  Color _strengthColor = Colors.white70;

  final AuthService _authService = AuthService();

  bool get _isPakistan => _selectedCountry.name == 'Pakistan';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _cnicController.dispose();
    _passportController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // NEW — password strength calculator
  void _updateStrength(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) score++;

    setState(() {
      if (value.isEmpty) {
        _strengthText = '';
      } else if (score <= 1) {
        _strengthText = 'Weak — try adding numbers & symbols';
        _strengthColor = const Color(0xFFFFCDD2);
      } else if (score == 2 || score == 3) {
        _strengthText = 'Medium — add uppercase & symbols for stronger';
        _strengthColor = const Color(0xFFFFF3C4);
      } else {
        _strengthText = 'Strong password ✓';
        _strengthColor = const Color(0xFFC8F7D6);
      }
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSigningUp = true);

    try {
      final String fullMobile = '${_selectedCountry.dialCode}${_mobileController.text.trim()}';

      final result = await _authService.signUpUser(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        country: _selectedCountry.name,
        mobileNumber: fullMobile,
        cnic: _isPakistan ? _cnicController.text.trim() : null,
        passportNumber: !_isPakistan ? _passportController.text.trim() : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _navigateAfterAuth(
          role: result['role'],
          isProfileComplete: result['isProfileComplete'],
        );
      } else {
        _showErrorSnackbar(
          result['message'] ?? 'Unable to create account.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackbar(
        'Unable to create account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningUp = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _authService.signInWithGoogle(
        role: _selectedRole,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _navigateAfterAuth(
          role: result['role'],
          isProfileComplete: result['isProfileComplete'],
        );
      } else {
        _showErrorSnackbar(
          result['message'] ?? 'Unable to continue with Google.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackbar(
        'Google sign-in failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _navigateAfterAuth({
    required String role,
    required bool isProfileComplete,
  }) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (role == 'donor') {
      Navigator.pushReplacementNamed(context, '/donor_dashboard');
    } else if (role == 'volunteer') {
      if (!isProfileComplete) {
        Navigator.pushReplacementNamed(context, '/volunteer_form');
      } else {
        Navigator.pushReplacementNamed(context, '/volunteer_dashboard');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5BA8A0),
      body: Stack(
        children: [
          // ── Background Image (UNCHANGED — already fixed) ────────────
          Positioned.fill(
            child: Container(
              color: const Color(0xFF5BA8A0),
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5BA8A0),
                        Color(0xFF4A9E95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Teal overlay (UNCHANGED) ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xDD5BA8A0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ──────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 70),

                    // ── Circular Logo (UNCHANGED) ────────────────────
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3A8A6E),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.volunteer_activism,
                            size: 44,
                            color: Color(0xFF3A8A6E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── "SIGN UP" Title (UNCHANGED) ──────────────────
                    const Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Role Selector (UNCHANGED) ────────────────────
                    _buildRoleSelector(),
                    const SizedBox(height: 16),

                    // ── Full Name field (UNCHANGED) ──────────────────
                    _buildInputField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── NEW: Username field ──────────────────────────
                    _buildInputField(
                      controller: _usernameController,
                      hint: 'Username',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please choose a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                          return 'Only letters, numbers, underscore allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Email field (UNCHANGED) ──────────────────────
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── NEW: Country dropdown ────────────────────────
                    _buildCountryDropdown(),
                    const SizedBox(height: 12),

                    // ── NEW: Mobile Number with auto country code ────
                    _buildMobileField(),
                    const SizedBox(height: 12),

                    // ── NEW: CNIC (Pakistan) or Passport (other) ─────
                    _isPakistan
                        ? _buildInputField(
                      controller: _cnicController,
                      hint: 'CNIC (00000-0000000-0)',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_CnicFormatter()],
                      maxLength: 15,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'CNIC is required';
                        }
                        if (value.trim().length != 15) {
                          return 'Enter complete 13-digit CNIC';
                        }
                        return null;
                      },
                    )
                        : _buildInputField(
                      controller: _passportController,
                      hint: 'Passport Number',
                      icon: Icons.badge_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Passport number is required';
                        }
                        if (value.trim().length < 5) {
                          return 'Enter a valid passport number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Password field (min length updated to 8) ─────
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      onChanged: _updateStrength, // NEW
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),

                    // NEW — password strength hint
                    if (_strengthText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _strengthText,
                            style: TextStyle(
                              color: _strengthColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // ── NEW: Confirm Password field ──────────────────
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Create Account Button (UNCHANGED) ────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSigningUp ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF2D6A4F).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: _isSigningUp
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── "or" Divider (UNCHANGED) ─────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.6),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.6),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Google Button (UNCHANGED) ────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        child: _isGoogleLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF4285F4),
                            strokeWidth: 2.5,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── "Already have an account? login" (UNCHANGED) ─
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'login',
                            style: TextStyle(
                              color: Color(0xFF40916C),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF40916C),
                              decorationThickness: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role Selector (COMPLETELY UNCHANGED) ────────────────────────────
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'donor'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedRole == 'donor'
                      ? const Color(0xFF2D6A4F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 16,
                      color: _selectedRole == 'donor'
                          ? Colors.white
                          : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Donor',
                      style: TextStyle(
                        color: _selectedRole == 'donor'
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: _selectedRole == 'donor'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'volunteer'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedRole == 'volunteer'
                      ? const Color(0xFF2D6A4F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 16,
                      color: _selectedRole == 'volunteer'
                          ? Colors.white
                          : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Volunteer',
                      style: TextStyle(
                        color: _selectedRole == 'volunteer'
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: _selectedRole == 'volunteer'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NEW: Country dropdown — matches existing pill style ─────────────
  Widget _buildCountryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CountryOption>(
          value: _selectedCountry,
          isExpanded: true,
          dropdownColor: const Color(0xFF2D6A4F),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withOpacity(0.85)),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          selectedItemBuilder: (context) {
            return _countries.map((c) {
              return Row(
                children: [
                  Icon(Icons.public, color: Colors.white.withOpacity(0.85), size: 20),
                  const SizedBox(width: 10),
                  Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 15)),
                ],
              );
            }).toList();
          },
          items: _countries.map((c) {
            return DropdownMenuItem<_CountryOption>(
              value: c,
              child: Text('${c.name} (${c.dialCode})',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCountry = value;
              // Clear identity fields when switching country type
              _cnicController.clear();
              _passportController.clear();
            });
          },
        ),
      ),
    );
  }

  // ── NEW: Mobile field with auto country code prefix ──────────────────
  Widget _buildMobileField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.85), size: 20),
          const SizedBox(width: 10),
          Text(
            _selectedCountry.dialCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white.withOpacity(0.4),
          ),
          Expanded(
            child: TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                final digits = value.trim();
                if (digits.length < _selectedCountry.minDigits ||
                    digits.length > _selectedCountry.maxDigits) {
                  return '${_selectedCountry.name} number must be ${_selectedCountry.minDigits == _selectedCountry.maxDigits ? _selectedCountry.minDigits : '${_selectedCountry.minDigits}-${_selectedCountry.maxDigits}'} digits';
                }
                if (_isPakistan && !digits.startsWith('3')) {
                  return 'Pakistani mobile numbers start with 3';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Input field (extended with optional onChanged + inputFormatters) ──
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged, // NEW
    List<TextInputFormatter>? inputFormatters, // NEW
    int? maxLength, // NEW
  }) {
    final bool obscure = isPassword &&
        (controller == _passwordController
            ? _isPasswordHidden
            : _isConfirmPasswordHidden);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 14,
        ),
        counterText: '',
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (controller == _passwordController
                ? _isPasswordHidden
                : _isConfirmPasswordHidden)
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          onPressed: () => setState(() {
            if (controller == _passwordController) {
              _isPasswordHidden = !_isPasswordHidden;
            } else {
              _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
            }
          }),
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
      ),
    );
  }
}