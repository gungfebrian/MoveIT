// lib/screens/register_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final AuthService _authService = AuthService();

  // Premium Palette (Matching Login Page)
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _surfaceColor = Color(0xFF14141C); // Matches Login Modal
  static const Color _primaryOrange = Color(0xFFF97316);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF94949E);

  void _register() async {
    // 1. Validate Input
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() => _isLoading = true);

    // 2. Call Firebase Register Service
    String? errorMessage = await _authService.registerWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    // 3. Handle Result
    if (errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to login
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.height(context, 0.015)),
              Text(
                'Create Account',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: Responsive.text(context, 0.08),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.01)),
              Text(
                'Begin your transformation today.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: Responsive.text(context, 0.04),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.05)),

              // Form Container
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 0.07)),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Column(
                  children: [
                    _buildField(
                      context: context,
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_rounded,
                    ),
                    SizedBox(height: Responsive.height(context, 0.02)),

                    _buildField(
                      context: context,
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                    ),
                    SizedBox(height: Responsive.height(context, 0.02)),

                    _buildField(
                      context: context,
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPass: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    SizedBox(height: Responsive.height(context, 0.02)),

                    _buildField(
                      context: context,
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_clock_rounded,
                      isPass: true,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityChanged: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),

                    SizedBox(height: Responsive.height(context, 0.04)),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.height(context, 0.07),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: Responsive.icon(context, 0.06),
                                height: Responsive.icon(context, 0.06),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontSize: Responsive.text(context, 0.04),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.height(context, 0.05)),

              // Sign In Link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: Responsive.text(context, 0.038),
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.text(context, 0.038),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pop(context);
                          },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.025)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
    bool isVisible = false,
    VoidCallback? onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass && !isVisible,
      style: TextStyle(
        color: Colors.white,
        fontSize: Responsive.text(context, 0.04),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white30,
          fontSize: Responsive.text(context, 0.04),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFF97316),
          size: Responsive.icon(context, 0.05),
        ),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white38,
                ),
                onPressed: onVisibilityChanged,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.width(context, 0.05),
          vertical: Responsive.height(context, 0.02),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
