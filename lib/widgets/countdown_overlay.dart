import 'package:flutter/material.dart';
import 'dart:async';

/// A fullscreen countdown overlay (3, 2, 1, GO!) before workout starts.
/// Prevents false positives while user is positioning their phone.
class CountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final int seconds;
  final Color themeColor;

  const CountdownOverlay({
    super.key,
    required this.onComplete,
    this.seconds = 3,
    this.themeColor = const Color(0xFFF97316),
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentCount;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.seconds;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _animationController.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCount > 0) {
        setState(() {
          _currentCount--;
        });
        _animationController.forward(from: 0);
      } else {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Ready!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.themeColor.withOpacity(0.2),
                        border: Border.all(color: widget.themeColor, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          _currentCount > 0 ? '$_currentCount' : 'GO!',
                          style: TextStyle(
                            color: widget.themeColor,
                            fontSize: _currentCount > 0 ? 72 : 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'Position yourself in frame',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
