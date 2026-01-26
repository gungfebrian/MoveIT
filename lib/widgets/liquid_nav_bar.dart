import 'package:flutter/material.dart';

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
          // Solid Background with Shadow and Scoop
          CustomPaint(
            size: Size(size.width, 80),
            painter: LiquidPainter(
              color: const Color(0xFF1E1E1E), // Solid matte dark grey
              shadowColor: Colors.black.withOpacity(0.5), // Subtle shadow
            ),
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
                    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.5),
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
                      colors: [Color(0xFFF97316), Color(0xFFFB923C)],
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
              color: isSelected
                  ? AppTheme.primary
                  : Colors.white.withOpacity(0.7),
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
    // Smoother, wider curve construction
    final double dipWidth = 90; // Slightly wider for ease
    final double dipDepth = 35;

    // Using two cubic curves for a smooth "U" shape instead of sharp "V"
    path.lineTo(centerX - dipWidth * 0.6, 0);

    path.cubicTo(
      centerX - dipWidth * 0.3,
      0, // Control point 1
      centerX - dipWidth * 0.3,
      dipDepth, // Control point 2
      centerX,
      dipDepth, // End point
    );

    path.cubicTo(
      centerX + dipWidth * 0.3,
      dipDepth, // Control point 1
      centerX + dipWidth * 0.3,
      0, // Control point 2
      centerX + dipWidth * 0.6,
      0, // End point
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
