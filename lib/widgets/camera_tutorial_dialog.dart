import 'package:flutter/material.dart';
import 'dart:ui';

class CameraTutorialDialog extends StatelessWidget {
  final Color primaryBlue = const Color(0xFF1976D2);
  final Color accentCyan = const Color(0xFF00E5FF);
  final Color darkBlue = const Color(0xFF0D47A1);

  const CameraTutorialDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [darkBlue, primaryBlue]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text('📸', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 10),
                      Text(
                        'Camera Setup Guide',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Follow these steps for accurate detection',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStep(
                        number: '1',
                        icon: Icons.videocam_outlined,
                        title: 'Position Camera',
                        description:
                            'Place phone 1.5-2 meters away at chest height',
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 15),

                      _buildStep(
                        number: '2',
                        icon: Icons.accessibility_new_rounded,
                        title: 'Full Body Visible',
                        description:
                            'Make sure your entire body is in frame from head to feet',
                        color: accentCyan,
                      ),
                      const SizedBox(height: 15),

                      _buildStep(
                        number: '3',
                        icon: Icons.light_mode_outlined,
                        title: 'Good Lighting',
                        description: 'Ensure room is well-lit, avoid backlight',
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 15),

                      _buildStep(
                        number: '4',
                        icon: Icons.sports_gymnastics_rounded,
                        title: 'Proper Form',
                        description:
                            'Pull wrists above shoulders with bent elbows < 60°',
                        color: accentCyan,
                      ),
                      const SizedBox(height: 20),

                      // Detection Tips
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tips_and_updates_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pro Tip',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Wait for "🟢 Tracking Active" status before starting',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Skeleton Preview
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'You\'ll see this skeleton overlay:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CustomPaint(
                              size: const Size(150, 200),
                              painter: SkeletonPreviewPainter(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildColorLegend(Colors.blue, 'Joints'),
                                const SizedBox(width: 15),
                                _buildColorLegend(Colors.green, 'Arms'),
                                const SizedBox(width: 15),
                                _buildColorLegend(Colors.cyan, 'Torso'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: const Text(
                            'Later',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentCyan, primaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Got it! Let\'s Start',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CameraTutorialDialog(),
    );
    return result ?? false;
  }
}

// Custom painter untuk skeleton preview
class SkeletonPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue;

    // Define skeleton points (simplified)
    final head = Offset(size.width / 2, size.height * 0.1);
    final leftShoulder = Offset(size.width * 0.3, size.height * 0.25);
    final rightShoulder = Offset(size.width * 0.7, size.height * 0.25);
    final leftElbow = Offset(size.width * 0.2, size.height * 0.45);
    final rightElbow = Offset(size.width * 0.8, size.height * 0.45);
    final leftWrist = Offset(size.width * 0.15, size.height * 0.65);
    final rightWrist = Offset(size.width * 0.85, size.height * 0.65);
    final leftHip = Offset(size.width * 0.4, size.height * 0.55);
    final rightHip = Offset(size.width * 0.6, size.height * 0.55);
    final leftKnee = Offset(size.width * 0.38, size.height * 0.75);
    final rightKnee = Offset(size.width * 0.62, size.height * 0.75);
    final leftAnkle = Offset(size.width * 0.36, size.height * 0.95);
    final rightAnkle = Offset(size.width * 0.64, size.height * 0.95);

    // Draw torso (cyan)
    paint.color = Colors.cyan;
    canvas.drawLine(leftShoulder, rightShoulder, paint);
    canvas.drawLine(leftShoulder, leftHip, paint);
    canvas.drawLine(rightShoulder, rightHip, paint);
    canvas.drawLine(leftHip, rightHip, paint);

    // Draw arms (green)
    paint.color = Colors.green;
    canvas.drawLine(leftShoulder, leftElbow, paint);
    canvas.drawLine(leftElbow, leftWrist, paint);
    canvas.drawLine(rightShoulder, rightElbow, paint);
    canvas.drawLine(rightElbow, rightWrist, paint);

    // Draw legs (yellow)
    paint.color = Colors.yellow;
    canvas.drawLine(leftHip, leftKnee, paint);
    canvas.drawLine(leftKnee, leftAnkle, paint);
    canvas.drawLine(rightHip, rightKnee, paint);
    canvas.drawLine(rightKnee, rightAnkle, paint);

    // Draw joints (blue circles)
    final joints = [
      head,
      leftShoulder,
      rightShoulder,
      leftElbow,
      rightElbow,
      leftWrist,
      rightWrist,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftAnkle,
      rightAnkle,
    ];

    for (final joint in joints) {
      canvas.drawCircle(joint, 6, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
