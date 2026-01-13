import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  // Premium Dark Palette
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _surfaceColor = Color(0xFF14141C);
  static const Color _primaryOrange = Color(0xFFFF5C00);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF94949E);

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.shutter_speed_rounded,
      'title': "Precision\nTracking",
      'description':
          "AI-powered computer vision analyzes your form in real-time.",
    },
    {
      'icon': Icons.insights_rounded,
      'title': "Data-Driven\nProgress",
      'description': "Visualize your fitness journey with detailed analytics.",
    },
    {
      'icon': Icons.emoji_events_rounded,
      'title': "Compete &\nConquer",
      'description': "Join the elite community. Set records and dominate.",
    },
  ];

  void _onComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _handleNext() {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _bgColor,
              Color(0xFF0F0F16),
              Color(0xFF181824), // Subtle lighter dark to blend
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Very subtle ambient light at bottom right to make it "alive"
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryOrange.withOpacity(0.08), // Extremely subtle
                  boxShadow: [
                    BoxShadow(
                      color: _primaryOrange.withOpacity(0.08),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _onComplete,
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Content Area
                  SizedBox(
                    height: 480,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentSlide = index),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon Circle - Clean & Minimal
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: _surfaceColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  slide['icon'] as IconData,
                                  size: 48,
                                  color: _primaryOrange,
                                ),
                              ),
                              const SizedBox(height: 64),

                              // Title
                              Text(
                                slide['title'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                  fontFamily: 'Inter',
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Description
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  slide['description'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: _textSecondary,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 32,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Indicators
                        Row(
                          children: List.generate(_slides.length, (index) {
                            final isActive = index == _currentSlide;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 6,
                              width: isActive ? 24 : 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _primaryOrange
                                    : _surfaceColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),

                        // Next Button
                        ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _currentSlide == _slides.length - 1
                                    ? 'START'
                                    : 'NEXT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontSize: 14,
                                ),
                              ),
                              if (_currentSlide != _slides.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
