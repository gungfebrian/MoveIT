import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Premium Palette
  static const Color _bgColor = Color(0xFF08080C); // Deeper black
  static const Color _surfaceColor = Color(0xFF12121A);
  static const Color _primaryOrange = Color(0xFFFF5C00); // More vibrant athletic orange
  static const Color _accentOrange = Color(0xFFFF8A00);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF94949E);

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.bolt_rounded,
      'title': 'ELITE\nPERFORMANCE',
      'subtitle': 'Engineering the ultimate athlete within you through precision tracking.',
    },
    {
      'icon': Icons.biotech_rounded,
      'title': 'AI FORM\nANALYSIS',
      'subtitle': 'Real-time computer vision to perfect your technique and prevent injury.',
    },
    {
      'icon': Icons.leaderboard_rounded,
      'title': 'DOMINATE\nGOALS',
      'subtitle': 'Track streaks, break records, and lead your community.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _LoginBottomSheet(authService: _authService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background "Glow" for depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryOrange.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Hero Section
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryOrange.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/tmoo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryOrange, _accentOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.fitness_center_rounded, size: 100, color: Colors.white),
                            ),
                          ),
                          // Subtle overlay for text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Section
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemCount: _slides.length,
                            itemBuilder: (context, index) {
                              final slide = _slides[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slide['title'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                      color: _textPrimary,
                                      height: 1.0,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    slide['subtitle'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: _textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Animated Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            bool isSelected = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isSelected ? 30 : 6,
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryOrange : _textSecondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),

                        // Action Buttons
                        _buildButton(
                          text: 'GET STARTED',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterPage())),
                          isPrimary: true,
                        ),
                        const SizedBox(height: 12),
                        _buildButton(
                          text: 'SIGN IN',
                          onPressed: _showLoginModal,
                          isPrimary: false,
                        ),

                        // Demo Mode
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage())),
                          child: const Text(
                            'Enter as Guest',
                            style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed, bool isPrimary = true}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: _textPrimary,
                side: BorderSide(color: _textSecondary.withOpacity(0.3), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
    );
  }
}

class _LoginBottomSheet extends StatefulWidget {
  final AuthService authService;
  const _LoginBottomSheet({required this.authService});

  @override
  State<_LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<_LoginBottomSheet> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(28, 20, 28, 28 + bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF14141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 32),
            const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const Text('Resume your evolution.', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),
            
            _buildField(controller: _email, hint: 'Email', icon: Icons.alternate_email_rounded),
            const SizedBox(height: 16),
            _buildField(
              controller: _pass, 
              hint: 'Password', 
              icon: Icons.lock_person_rounded, 
              isPass: true,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _loading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            // Social Login
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Colors.white),
                label: const Text('Continue with Google', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, bool isPass = false, Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: isPass && _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: const Color(0xFFFF5C00), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF5C00), width: 1),
        ),
      ),
    );
  }

  void _handleLogin() async {
    setState(() => _loading = true);
    final error = await widget.authService.signInWithEmailPassword(email: _email.text, password: _pass.text);
    if (error == null && mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const HomePage()), (r) => false);
    } else {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Login Failed')));
      }
    }
  }
}