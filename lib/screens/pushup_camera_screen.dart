import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/settings_service.dart';
import 'dart:math' as math;

/// Skeleton painter for pose visualization
class PushUpPosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;

  PushUpPosePainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = screenSize.width / imageSize.width;
    double scaleY = screenSize.height / imageSize.height;

    double translateX(double x) {
      double mapped = x * scaleX;
      return cameraLensDirection == CameraLensDirection.front
          ? screenSize.width - mapped
          : mapped;
    }

    double translateY(double y) => y * scaleY;

    void drawLine(PoseLandmark? start, PoseLandmark? end, Color color) {
      if (start == null || end == null) return;
      final startOffset = Offset(translateX(start.x), translateY(start.y));
      final endOffset = Offset(translateX(end.x), translateY(end.y));

      // Outer glow
      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = color.withAlpha(60)
          ..strokeWidth = 14.0
          ..strokeCap = StrokeCap.round,
      );
      // Main line
      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = color
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round,
      );
    }

    void drawPoint(PoseLandmark? lm, Color color) {
      if (lm == null) return;
      final offset = Offset(translateX(lm.x), translateY(lm.y));
      // Outer glow
      canvas.drawCircle(offset, 16, Paint()..color = color.withAlpha(50));
      // Inner circle
      canvas.drawCircle(offset, 10, Paint()..color = color);
      // Center white dot
      canvas.drawCircle(offset, 4, Paint()..color = Colors.white);
    }

    final lm = pose.landmarks;
    // Arms - Orange for push-up
    drawLine(
      lm[PoseLandmarkType.leftShoulder],
      lm[PoseLandmarkType.leftElbow],
      const Color(0xFFFF5722),
    );
    drawLine(
      lm[PoseLandmarkType.leftElbow],
      lm[PoseLandmarkType.leftWrist],
      const Color(0xFFFF5722),
    );
    drawLine(
      lm[PoseLandmarkType.rightShoulder],
      lm[PoseLandmarkType.rightElbow],
      const Color(0xFFFF5722),
    );
    drawLine(
      lm[PoseLandmarkType.rightElbow],
      lm[PoseLandmarkType.rightWrist],
      const Color(0xFFFF5722),
    );
    // Torso
    drawLine(
      lm[PoseLandmarkType.leftShoulder],
      lm[PoseLandmarkType.rightShoulder],
      Colors.yellow,
    );
    drawLine(
      lm[PoseLandmarkType.leftShoulder],
      lm[PoseLandmarkType.leftHip],
      Colors.green,
    );
    drawLine(
      lm[PoseLandmarkType.rightShoulder],
      lm[PoseLandmarkType.rightHip],
      Colors.green,
    );
    drawLine(
      lm[PoseLandmarkType.leftHip],
      lm[PoseLandmarkType.rightHip],
      Colors.green,
    );
    // Legs
    drawLine(
      lm[PoseLandmarkType.leftHip],
      lm[PoseLandmarkType.leftKnee],
      Colors.cyan,
    );
    drawLine(
      lm[PoseLandmarkType.leftKnee],
      lm[PoseLandmarkType.leftAnkle],
      Colors.cyan,
    );
    drawLine(
      lm[PoseLandmarkType.rightHip],
      lm[PoseLandmarkType.rightKnee],
      Colors.purple,
    );
    drawLine(
      lm[PoseLandmarkType.rightKnee],
      lm[PoseLandmarkType.rightAnkle],
      Colors.purple,
    );
    // Points
    drawPoint(lm[PoseLandmarkType.leftShoulder], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.leftElbow], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.leftWrist], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.rightShoulder], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.rightElbow], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.rightWrist], const Color(0xFFFF5722));
    drawPoint(lm[PoseLandmarkType.leftHip], Colors.green);
    drawPoint(lm[PoseLandmarkType.rightHip], Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dedicated Push-Up Camera Screen
/// Uses algorithm from lib/Detection/Pushup/PushUpCounter.py
class PushUpCameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const PushUpCameraScreen({super.key, required this.camera});

  @override
  State<PushUpCameraScreen> createState() => _PushUpCameraScreenState();
}

class _PushUpCameraScreenState extends State<PushUpCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late PoseDetector _poseDetector;
  bool _isProcessing = false;
  int _repCount = 0;
  Pose? _currentPose;
  int _frameCount = 0;
  late final DateTime _sessionStart;

  // Status
  String _formFeedback = 'Get in plank position...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // Push-up state (from Python PushUpCounter.py)
  int _direction = 0; // 0 = ready for down, 1 = ready for up
  int _form = 0; // 0 = form not validated, 1 = form OK

  @override
  void initState() {
    super.initState();
    debugPrint('🏋️ Initializing Push-Up Camera Screen');
    _sessionStart = DateTime.now();
    _initializeControllerFuture = _initCameraAndPose();
  }

  @override
  void dispose() {
    debugPrint('🛑 Disposing Push-Up camera');
    _disposeResources();
    super.dispose();
  }

  Future<void> _disposeResources() async {
    try {
      if (_controller.value.isStreamingImages) {
        await _controller.stopImageStream();
      }
      await _controller.dispose();
    } catch (e) {
      debugPrint('⚠️ Camera dispose error: $e');
    }
    try {
      await _poseDetector.close();
    } catch (e) {
      debugPrint('⚠️ PoseDetector dispose error: $e');
    }
    debugPrint('✅ Push-Up resources released');
  }

  Future<void> _initCameraAndPose() async {
    final choice = await SettingsService().getPoseModelChoice();
    final model = choice == PoseModelChoice.base
        ? PoseDetectionModel.base
        : PoseDetectionModel.accurate;

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: model,
      ),
    );

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      debugPrint('📷 Push-Up camera initialized');
      if (mounted) {
        _controller.startImageStream(_processImage);
      }
    } catch (error) {
      debugPrint('❌ Camera error: $error');
    }
  }

  InputImageRotation _getImageRotation() {
    switch (widget.camera.sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _frameCount++;

    // Skip frames for better performance (process every 3rd frame)
    if (_frameCount % 3 != 0) {
      _isProcessing = false;
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getImageRotation(),
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty && mounted) {
        _currentPose = poses.first;
        _checkPushUp(poses.first); // This now handles setState internally, once
      } else if (mounted) {
        setState(() => _formFeedback = 'No person detected');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Push-Up Detection Algorithm from PushUpCounter.py
  /// Angles: elbow (11,13,15), shoulder (13,11,23), hip (11,23,25)
  void _checkPushUp(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null ||
        leftElbow == null ||
        leftWrist == null ||
        leftHip == null ||
        leftKnee == null) {
      if (mounted)
        setState(() => _formFeedback = 'Position full body in frame');
      return;
    }

    // Calculate angles matching Python code
    double elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double shoulderAngle = _calculateAngle(leftElbow, leftShoulder, leftHip);
    double hipAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);

    // Calculate new state values BEFORE setState
    double newQuality = (hipAngle > 140)
        ? 0.8
        : (hipAngle / 180.0).clamp(0.0, 1.0);
    String newFeedback = _formFeedback;
    bool newProperForm = _isProperForm;
    int newForm = _form;
    int newDirection = _direction;
    int newRepCount = _repCount;

    // Check form
    if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
      newForm = 1;
    }

    if (newForm == 1) {
      if (elbowAngle <= 90 && hipAngle > 160) {
        newFeedback = 'Push Up!';
        newProperForm = true;
        if (_direction == 0) {
          newRepCount++;
          newDirection = 1;
          debugPrint('💪 Push-up count: $newRepCount');
        }
      } else if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
        newFeedback = 'Go Down!';
        newProperForm = true;
        if (_direction == 1) {
          newDirection = 0;
        }
      } else {
        newFeedback = 'Fix Form - Keep body straight';
        newProperForm = false;
      }
    } else {
      newFeedback = 'Get in plank position';
      newProperForm = false;
    }

    // SINGLE setState call per frame
    if (mounted) {
      setState(() {
        _repQuality = newQuality;
        _formFeedback = newFeedback;
        _isProperForm = newProperForm;
        _form = newForm;
        _direction = newDirection;
        _repCount = newRepCount;
      });
    }
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    double dx1 = a.x - b.x;
    double dy1 = a.y - b.y;
    double dx2 = c.x - b.x;
    double dy2 = c.y - b.y;

    double angle =
        (180 / math.pi) *
        math.acos(
          (dx1 * dx2 + dy1 * dy2) /
              (math.sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2))),
        );
    return angle.isNaN ? 0 : angle;
  }

  Future<void> _saveSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add({
            'exerciseType': 'Push-Up',
            'repCount': _repCount,
            'timestamp': Timestamp.now(),
            'durationMs': DateTime.now()
                .difference(_sessionStart)
                .inMilliseconds,
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push-Up session saved!')));
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
    }
  }

  Color _getQualityColor(double q) {
    if (q < 0.3) return Colors.red;
    if (q < 0.6) return Colors.orange;
    if (q < 0.8) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller),
                      if (_currentPose != null)
                        CustomPaint(
                          painter: PushUpPosePainter(
                            pose: _currentPose!,
                            imageSize: Size(
                              _controller.value.previewSize!.height,
                              _controller.value.previewSize!.width,
                            ),
                            screenSize: MediaQuery.of(context).size,
                            cameraLensDirection: widget.camera.lensDirection,
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5722)),
              );
            },
          ),
          // HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF5722).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.accessibility_new,
                            color: Color(0xFFFF5722),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_repCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Push-Ups',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Feedback
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isProperForm
                            ? const Color(0xFF4CAF50).withOpacity(0.9)
                            : const Color(0xFFFF9800).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _formFeedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quality bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Form Quality',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(_repQuality * 100).toInt()}%',
                                style: TextStyle(
                                  color: _getQualityColor(_repQuality),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _repQuality,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(
                                _getQualityColor(_repQuality),
                              ),
                              minHeight: 6,
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
          // End button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _saveSession();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text(
                  'End Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
