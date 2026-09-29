// ============================================================
// FILE: lib/screens/auth/login_screen_web.dart
//
// Premium desktop web login for Admin & Manager only.
// Uses EXISTING AuthService (Firebase Auth + Firestore role check),
// EXISTING ForgotPasswordScreen, EXISTING project assets
// (assets/images/hand_image.jpeg, assets/images/logo.png).
// Does not touch mobile LoginScreen, dashboards, or Firebase logic.
// ============================================================

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreenWeb extends StatefulWidget {
  const LoginScreenWeb({super.key});

  @override
  State<LoginScreenWeb> createState() => _LoginScreenWebState();
}

class _LoginScreenWebState extends State<LoginScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;
  bool _forgotHover = false;
  bool _btnHover = false;

  final AuthService _authService = AuthService();

  // ── Premium green + white palette ─────────────────────────────────────
  static const Color _deepGreen = Color(0xFF0B3D24);
  static const Color _emerald = Color(0xFF14532D);
  static const Color _accentGreen = Color(0xFF1B6B3A);
  static const Color _mint = Color(0xFF2FBF87);
  static const Color _softBg = Color(0xFFF6F9F7);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    final role = result['role'];

    // Web panel is Admin/Manager only — donor/volunteer blocked here.
    if (result['success'] == true && role != 'admin' && role != 'manager') {
      await _authService.signOut();
      setState(() => _isLoading = false);
      _showError('This web panel is for Admin/Manager accounts only.');
      return;
    }

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard_web');
      } else {
        Navigator.pushReplacementNamed(context, '/manager_dashboard_web');
      }
    } else {
      _showError(result['message'] ?? 'Login failed. Please try again.');
    }
  }

  void _showError(String message) {
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
      backgroundColor: _softBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool showBrandPanel = constraints.maxWidth >= 900;

          if (!showBrandPanel) {
            // Smaller laptop / tablet-width fallback — form only, still premium.
            return _RightPanel(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              isPasswordHidden: _isPasswordHidden,
              isLoading: _isLoading,
              forgotHover: _forgotHover,
              btnHover: _btnHover,
              onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
              onForgotHover: (v) => setState(() => _forgotHover = v),
              onBtnHover: (v) => setState(() => _btnHover = v),
              onLogin: _handleLogin,
              onForgotTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              compact: true,
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: _BrandPanel(deepGreen: _deepGreen, emerald: _emerald, mint: _mint)),
              Expanded(
                flex: 4,
                child: _RightPanel(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isPasswordHidden: _isPasswordHidden,
                  isLoading: _isLoading,
                  forgotHover: _forgotHover,
                  btnHover: _btnHover,
                  onTogglePassword: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                  onForgotHover: (v) => setState(() => _forgotHover = v),
                  onBtnHover: (v) => setState(() => _btnHover = v),
                  onLogin: _handleLogin,
                  onForgotTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  compact: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// LEFT — BRAND / HUMANITARIAN IMAGE PANEL
// ============================================================
class _BrandPanel extends StatelessWidget {
  final Color deepGreen;
  final Color emerald;
  final Color mint;

  const _BrandPanel({required this.deepGreen, required this.emerald, required this.mint});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Wide-desktop composed image — cover + center alignment so it
        // never looks like a cropped mobile portrait photo.
        Image.asset(
          'assets/images/hand_image.jpeg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Container(color: deepGreen),
        ),
        // Elegant green overlay for legibility — top darker, fading toward
        // center, darker again at the bottom where the message sits.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                deepGreen.withOpacity(0.88),
                emerald.withOpacity(0.55),
                deepGreen.withOpacity(0.9),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 44, 48, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo + brand ─────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.volunteer_activism_rounded, color: deepGreen, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DonateHub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                        Text('Little Smiles Orphan Home', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // ── Emotional message ────────────────────────────────
                Text(
                  'Every donation,\nevery act of care —\nmanaged with purpose.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A secure workspace for the people who keep DonateHub\nrunning — approving donations, coordinating volunteers,\nand tracking every rupee of impact.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(width: 34, height: 3, decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 10, height: 3, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RIGHT — LOGIN FORM PANEL
// ============================================================
class _RightPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final bool isLoading;
  final bool forgotHover;
  final bool btnHover;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onForgotHover;
  final ValueChanged<bool> onBtnHover;
  final VoidCallback onLogin;
  final VoidCallback onForgotTap;
  final bool compact;

  static const Color _deepGreen = Color(0xFF0B3D24);
  static const Color _accentGreen = Color(0xFF1B6B3A);
  static const Color _mint = Color(0xFF2FBF87);

  const _RightPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.isLoading,
    required this.forgotHover,
    required this.btnHover,
    required this.onTogglePassword,
    required this.onForgotHover,
    required this.onBtnHover,
    required this.onLogin,
    required this.onForgotTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: compact ? 24 : 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compact) ...[
                    Row(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE6F5EE)),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.volunteer_activism_rounded, color: _accentGreen)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('DonateHub', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _deepGreen)),
                    ]),
                    const SizedBox(height: 36),
                  ],

                  const Text('Welcome Back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF14251E), letterSpacing: 0.2)),
                  const SizedBox(height: 8),
                  Text('Sign in to your DonateHub account', style: TextStyle(fontSize: 14.5, color: Colors.grey[600])),
                  const SizedBox(height: 36),

                  const Text('Email', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF14251E))),
                  const SizedBox(height: 8),
                  _PremiumField(
                    controller: emailController,
                    icon: Icons.mail_outline_rounded,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 20),

                  const Text('Password', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF14251E))),
                  const SizedBox(height: 8),
                  _PremiumField(
                    controller: passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: '••••••••',
                    isPassword: true,
                    isPasswordHidden: isPasswordHidden,
                    onTogglePassword: onTogglePassword,
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => onForgotHover(true),
                      onExit: (_) => onForgotHover(false),
                      child: GestureDetector(
                        onTap: onForgotTap,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: forgotHover ? _deepGreen : _accentGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: forgotHover ? TextDecoration.underline : TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => onBtnHover(true),
                    onExit: (_) => onBtnHover(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: btnHover ? [_deepGreen, _accentGreen] : [_accentGreen, _mint],
                        ),
                        boxShadow: [
                          BoxShadow(color: _accentGreen.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isLoading ? null : onLogin,
                          child: Center(
                            child: isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(color: const Color(0xFFF3F8F5), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 15, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Authorized Admin & Manager access only',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PREMIUM TEXT FIELD
// ============================================================
class _PremiumField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool isPassword;
  final bool isPasswordHidden;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _PremiumField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    this.isPasswordHidden = true,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<_PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<_PremiumField> {
  bool _focused = false;

  static const Color _accentGreen = Color(0xFF1B6B3A);

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? widget.isPasswordHidden : false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF14251E)),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(widget.icon, size: 20, color: _focused ? _accentGreen : Colors.grey[400]),
          suffixIcon: widget.isPassword
              ? IconButton(
            icon: Icon(
              widget.isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: Colors.grey[400],
            ),
            onPressed: widget.onTogglePassword,
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF7FAF9),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentGreen, width: 1.6)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC0392B))),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.6)),
        ),
      ),
    );
  }
}