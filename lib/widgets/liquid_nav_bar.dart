import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../theme/app_theme.dart';

class LiquidNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabTap;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return SizedBox(
      height: 100, // Total height including FAB space
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Shape with Glass Effect
          CustomPaint(
            size: Size(size.width, 80),
            painter: LiquidPainter(
              color: AppTheme.card.withOpacity(0.6), // Glass base color
              shadowColor: Colors.black.withOpacity(0.3),
            ),
            child: ClipPath(
              clipper: LiquidClipper(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 80,
                  width: size.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.card.withOpacity(0.7),
                        AppTheme.card.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Glass Border and Highlight (Overlay Painter)
          CustomPaint(
            size: Size(size.width, 80),
            painter: LiquidBorderPainter(),
          ),

          // Navigation Items
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, 0, "Home"),
                _buildNavItem(Icons.trending_up_rounded, 1, "History"),
                const SizedBox(width: 60), // Space for FAB
                _buildNavItem(Icons.pie_chart_rounded, 2, "Progress"),
                _buildNavItem(Icons.person_rounded, 3, "Profile"),
              ],
            ),
          ),

          // Center FAB
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onFabTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5C00).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(2), // Border width
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF5C00), Color(0xFFFF8A00)],
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon stays in one place
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            // Static Indicator dot (no animation to prevent constraints error)
            Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  LiquidPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    
    // Starting point
    path.moveTo(0, 0);
    
    // Top line with liquid dip
    final double centerX = size.width / 2;
    final double dipWidth = 80;
    final double dipDepth = 35; // How deep the curve goes (positive is down for us since we want to cradle the button or up?)
    // Actually for "Liquid", usually the button floats and the bar curves AWAY or AROUND it.
    // If we want the button to float "in" a dip:
    
    //  ____      ____
    //      \___/
    
    path.lineTo(centerX - dipWidth * 0.8, 0);
    
    // The Curve
    path.cubicTo(
      centerX - dipWidth * 0.4, 0,
      centerX - dipWidth * 0.4, dipDepth,
      centerX, dipDepth,
    );
    path.cubicTo(
      centerX + dipWidth * 0.4, dipDepth,
      centerX + dipWidth * 0.4, 0,
      centerX + dipWidth * 0.8, 0,
    );
    
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Shadow
    canvas.drawShadow(path, shadowColor, 10, true);
    
    // Fill
    final Paint paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LiquidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    path.moveTo(0, 0);
    
    final double centerX = size.width / 2;
    final double dipWidth = 80;
    final double dipDepth = 35;
    
    path.lineTo(centerX - dipWidth * 0.8, 0);
    
    path.cubicTo(
      centerX - dipWidth * 0.4, 0,
      centerX - dipWidth * 0.4, dipDepth,
      centerX, dipDepth,
    );
    path.cubicTo(
      centerX + dipWidth * 0.4, dipDepth,
      centerX + dipWidth * 0.4, 0,
      centerX + dipWidth * 0.8, 0,
    );
    
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LiquidBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    
    path.moveTo(0, 0);
    
    final double centerX = size.width / 2;
    final double dipWidth = 80;
    final double dipDepth = 35;
    
    path.lineTo(centerX - dipWidth * 0.8, 0);
    path.cubicTo(
      centerX - dipWidth * 0.4, 0,
      centerX - dipWidth * 0.4, dipDepth,
      centerX, dipDepth,
    );
    path.cubicTo(
      centerX + dipWidth * 0.4, dipDepth,
      centerX + dipWidth * 0.4, 0,
      centerX + dipWidth * 0.8, 0,
    );
    path.lineTo(size.width, 0);

    // Gradient Border (Top only generally looks best for glass)
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
