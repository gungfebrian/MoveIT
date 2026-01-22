import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/settings_service.dart';
import 'dart:math' as math;

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  final String exerciseType;

  const CameraScreen({
    super.key,
    required this.camera,
    required this.cameras,
    this.exerciseType = 'Pull-Up',
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;

  PosePainter({
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

    double translateY(double y) {
      return y * scaleY;
    }

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

    void drawPoint(PoseLandmark? landmark, Color color) {
      if (landmark == null) return;
      final offset = Offset(translateX(landmark.x), translateY(landmark.y));

      // Outer glow
      canvas.drawCircle(offset, 16, Paint()..color = color.withAlpha(50));
      // Inner circle
      canvas.drawCircle(offset, 10, Paint()..color = color);
      // Center white dot
      canvas.drawCircle(offset, 4, Paint()..color = Colors.white);
    }

    // Draw all landmarks
    final landmarks = pose.landmarks;

    // Left arm - BLUE (Pull-up theme)
    drawLine(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
      const Color(0xFF2196F3),
    );
    drawLine(
      landmarks[PoseLandmarkType.leftElbow],
      landmarks[PoseLandmarkType.leftWrist],
      const Color(0xFF2196F3),
    );

    // Right arm - BLUE (Pull-up theme)
    drawLine(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
      const Color(0xFF2196F3),
    );
    drawLine(
      landmarks[PoseLandmarkType.rightElbow],
      landmarks[PoseLandmarkType.rightWrist],
      const Color(0xFF2196F3),
    );

    // Shoulders - YELLOW
    drawLine(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.rightShoulder],
      Colors.yellow,
    );

    // Torso - GREEN
    drawLine(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftHip],
      Colors.green,
    );
    drawLine(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightHip],
      Colors.green,
    );
    drawLine(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.rightHip],
      Colors.green,
    );

    // Left leg - CYAN
    drawLine(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      Colors.cyan,
    );
    drawLine(
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
      Colors.cyan,
    );

    // Right leg - PURPLE
    drawLine(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      Colors.purple,
    );
    drawLine(
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
      Colors.purple,
    );

    // Draw all points with blue theme for Pull-Up
    drawPoint(
      landmarks[PoseLandmarkType.leftShoulder],
      const Color(0xFF2196F3),
    );
    drawPoint(landmarks[PoseLandmarkType.leftElbow], const Color(0xFF2196F3));
    drawPoint(landmarks[PoseLandmarkType.leftWrist], const Color(0xFF2196F3));

    drawPoint(
      landmarks[PoseLandmarkType.rightShoulder],
      const Color(0xFF2196F3),
    );
    drawPoint(landmarks[PoseLandmarkType.rightElbow], const Color(0xFF2196F3));
    drawPoint(landmarks[PoseLandmarkType.rightWrist], const Color(0xFF2196F3));

    drawPoint(landmarks[PoseLandmarkType.leftHip], Colors.green);
    drawPoint(landmarks[PoseLandmarkType.rightHip], Colors.green);

    drawPoint(landmarks[PoseLandmarkType.leftKnee], Colors.cyan);
    drawPoint(landmarks[PoseLandmarkType.leftAnkle], Colors.cyan);

    drawPoint(landmarks[PoseLandmarkType.rightKnee], Colors.purple);
    drawPoint(landmarks[PoseLandmarkType.rightAnkle], Colors.purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late PoseDetector _poseDetector;
  late CameraDescription _currentCamera;
  bool _isProcessing = false;
  int _repCount = 0;
  bool _isInUpPosition = false;
  Pose? _currentPose;
  int _frameCount = 0;
  int _poseDetectedCount = 0;
  late final DateTime _sessionStart;

  // Status gerakan
  String _formFeedback = 'Detecting pose...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // Threshold dan konstanta (Pull-up)
  static const double _minArmAngle = 60.0;
  static const double _maxShoulderDiff = 0.1;
  static const double _minConfidence = 0.7;
  static const Duration _minRepDuration = Duration(milliseconds: 1500);
  DateTime? _lastRepTime;

  // Push-up state (from Python algorithm)
  int _pushUpDirection = 0; // 0 = down, 1 = up
  int _pushUpForm = 0; // 0 = not ready, 1 = form validated

  // Sit-up state (from Python algorithm)
  String _sitUpStage = 'down'; // 'down' or 'up'

  @override
  void initState() {
    super.initState();

    debugPrint('🎬 Initializing Camera Screen');
    _sessionStart = DateTime.now();
    _currentCamera = widget.camera;

    _initializeControllerFuture = _initCameraAndPose();
  }

  @override
  void dispose() {
    debugPrint('🛑 Disposing Pull-Up camera');

    // 1. Stop processing immediately to prevent "setState after dispose"
    _isProcessing = true;

    // 2. Dispose pose detector first to stop ML calculations
    try {
      _poseDetector.close();
    } catch (e) {
      debugPrint('⚠️ PoseDetector dispose error: $e');
    }

    // 3. Dispose camera controller (internally stops the stream)
    try {
      _controller.dispose();
    } catch (e) {
      debugPrint('⚠️ Camera dispose error: $e');
    }

    debugPrint('✅ Pull-Up resources released');
    super.dispose();
  }

  Future<void> _initCameraAndPose() async {
    // Read user preference for pose model
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
      _currentCamera,
      ResolutionPreset.low, // Use low resolution to reduce memory pressure
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      debugPrint('📷 Camera initialized successfully');
      if (mounted) {
        _initializeCamera();
      }
    } catch (error) {
      debugPrint('❌ Camera initialization error: $error');
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    _isProcessing = true;

    try {
      _controller.dispose();
    } catch (e) {
      debugPrint('⚠️ Camera dispose error: $e');
    }

    final newCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection != _currentCamera.lensDirection,
      orElse: () => widget.cameras.first,
    );

    setState(() {
      _currentCamera = newCamera;
      _currentPose = null;
    });

    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        _initializeCamera();
      }
    } catch (e) {
      debugPrint('❌ Camera switch error: $e');
    }

    _isProcessing = false;
  }

  InputImageRotation _getImageRotation() {
    final sensorOrientation = _currentCamera.sensorOrientation;
    debugPrint('📐 Sensor orientation: $sensorOrientation');

    // Map common Android sensor orientations to ML Kit rotation
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _processImage(CameraImage image) async {
    // Safety check: stop if already processing or widget is disposed
    if (_isProcessing || !mounted) return;
    _isProcessing = true;
    _frameCount++;

    // Skip frames for better performance (process every 5th frame to reduce CPU/RAM pressure)
    if (_frameCount % 5 != 0) {
      _isProcessing = false;
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: _getImageRotation(),
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        _poseDetectedCount++;
        if (_poseDetectedCount % 10 == 0) {
          debugPrint('✅ Pose detected! Total: $_poseDetectedCount');
          debugPrint('   Landmarks count: ${poses.first.landmarks.length}');
        }

        if (mounted) {
          _currentPose = poses.first;
          _processPose(poses.first);
        }
      } else {
        if (_frameCount % 30 == 0) {
          debugPrint('⚠️ No pose detected in frame $_frameCount');
        }
        if (mounted) {
          setState(() {
            _formFeedback = 'No person detected';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      if (mounted) {
        setState(() {
          _formFeedback = 'Error: $e';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _initializeCamera() {
    debugPrint('🎥 Starting image stream');
    _controller.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  Future<void> _saveSessionToHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot save session: user not logged in');
        return;
      }

      final durationMs = DateTime.now()
          .difference(_sessionStart)
          .inMilliseconds;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add({
            'exerciseType': widget.exerciseType,
            'repCount': _repCount,
            'timestamp': Timestamp.now(),
            'durationMs': durationMs,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved to history')),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to save session: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  /// Routes pose processing to the correct detection method based on exercise type
  void _processPose(Pose pose) {
    debugPrint('🏋️ Processing pose for exercise: ${widget.exerciseType}');
    switch (widget.exerciseType.toLowerCase()) {
      case 'push-up':
      case 'pushup':
      case 'push up':
        debugPrint('✅ Using PUSH-UP detection');
        _checkPushUp(pose);
        break;
      case 'sit-up':
      case 'situp':
      case 'sit up':
        debugPrint('✅ Using SIT-UP detection');
        _checkSitUp(pose);
        break;
      case 'pull-up':
      case 'pullup':
      case 'pull up':
      default:
        debugPrint('✅ Using PULL-UP detection');
        _checkPullUp(pose);
        break;
    }
  }

  /// Push-up detection based on Python PushUpCounter.py algorithm
  /// Uses elbow angle, shoulder angle, and hip angle
  void _checkPushUp(Pose pose) {
    final PoseLandmark? leftShoulder =
        pose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final PoseLandmark? leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null ||
        leftElbow == null ||
        leftWrist == null ||
        leftHip == null ||
        leftKnee == null) {
      setState(() {
        _formFeedback = 'Position your full body in frame';
      });
      return;
    }

    // Calculate angles (matching Python: 11, 13, 15 for elbow)
    double elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    // Shoulder angle: elbow → shoulder → hip (13, 11, 23)
    double shoulderAngle = _calculateAngle(leftElbow, leftShoulder, leftHip);
    // Hip angle: shoulder → hip → knee (11, 23, 25)
    double hipAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);

    // Calculate quality based on form
    double quality = (hipAngle > 140) ? 0.8 : (hipAngle / 180.0);

    setState(() {
      _repQuality = quality.clamp(0.0, 1.0);

      // Check for proper starting form: elbow > 160, shoulder > 40, hip > 160
      if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
        _pushUpForm = 1;
      }

      if (_pushUpForm == 1) {
        // DOWN position: elbow <= 90 AND hip > 160 (body straight)
        if (elbowAngle <= 90 && hipAngle > 160) {
          _formFeedback = 'Push Up!';
          _isProperForm = true;
          if (_pushUpDirection == 0) {
            _repCount++;
            _pushUpDirection = 1;
            debugPrint('💪 Push-up DOWN counted! Total: $_repCount');
          }
        }
        // UP position: elbow > 160, shoulder > 40, hip > 160
        else if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
          _formFeedback = 'Go Down!';
          _isProperForm = true;
          if (_pushUpDirection == 1) {
            _pushUpDirection = 0;
          }
        } else {
          _formFeedback = 'Fix Form - Keep body straight';
          _isProperForm = false;
        }
      } else {
        _formFeedback = 'Get in plank position with arms straight';
        _isProperForm = false;
      }
    });
  }

  /// Sit-up detection based on Python situp_realtime.py algorithm
  /// Uses shoulder-hip-knee angle (landmarks 11, 23, 25)
  void _checkSitUp(Pose pose) {
    final PoseLandmark? leftShoulder =
        pose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final PoseLandmark? leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) {
      setState(() {
        _formFeedback = 'Position your body in frame (side view)';
      });
      return;
    }

    // Calculate angle: shoulder → hip → knee (11, 23, 25)
    double angle = _calculateAngle(leftShoulder, leftHip, leftKnee);

    // Calculate quality based on angle
    double quality = angle < 100 ? 1.0 : (180 - angle) / 80.0;

    setState(() {
      _repQuality = quality.clamp(0.0, 1.0);

      // DOWN state: angle >= 117 (lying flat)
      if (angle >= 117) {
        _sitUpStage = 'down';
        _formFeedback = 'Sit Up!';
        _isProperForm = true;
      }

      // UP state: angle <= 89 AND was in down position
      if (angle <= 89 && _sitUpStage == 'down') {
        _sitUpStage = 'up';
        _repCount++;
        _formFeedback = 'Great! Go back down';
        _isProperForm = true;
        debugPrint('💪 Sit-up counted! Total: $_repCount');
      } else if (angle > 89 && angle < 117) {
        _formFeedback = _sitUpStage == 'down'
            ? 'Keep going up!'
            : 'Go back down';
        _isProperForm = false;
      }
    });
  }

  void _checkPullUp(Pose pose) {
    final PoseLandmark? leftShoulder =
        pose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final PoseLandmark? leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final PoseLandmark? rightShoulder =
        pose.landmarks[PoseLandmarkType.rightShoulder];
    final PoseLandmark? rightElbow =
        pose.landmarks[PoseLandmarkType.rightElbow];
    final PoseLandmark? rightWrist =
        pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder != null &&
        leftElbow != null &&
        leftWrist != null &&
        rightShoulder != null &&
        rightElbow != null &&
        rightWrist != null) {
      bool isProperForm = _isArmsBent(
        leftShoulder,
        leftElbow,
        leftWrist,
        rightShoulder,
        rightElbow,
        rightWrist,
      );

      double quality = _calculateRepQuality(
        leftShoulder,
        leftElbow,
        leftWrist,
        rightShoulder,
        rightElbow,
        rightWrist,
      );

      setState(() {
        _isProperForm = isProperForm;
        _repQuality = quality;

        if (!isProperForm) {
          if (quality < 0.3) {
            _formFeedback = "Keep your shoulders level and face forward";
          } else if (quality < 0.6) {
            _formFeedback = "Pull up higher, chin over the bar";
          } else {
            _formFeedback = "Almost there! Keep going";
          }
        } else {
          _formFeedback = "Great form!";
        }

        if (isProperForm && !_isInUpPosition) {
          final now = DateTime.now();
          if (_lastRepTime == null ||
              now.difference(_lastRepTime!) >= _minRepDuration) {
            _isInUpPosition = true;
            _repCount++;
            _lastRepTime = now;
            debugPrint('💪 Pull-up counted! Total: $_repCount');
          }
        } else if (!isProperForm && _isInUpPosition) {
          _isInUpPosition = false;
        }
      });
    }
  }

  double _calculateRepQuality(
    PoseLandmark leftShoulder,
    PoseLandmark leftElbow,
    PoseLandmark leftWrist,
    PoseLandmark rightShoulder,
    PoseLandmark rightElbow,
    PoseLandmark rightWrist,
  ) {
    double shoulderStability =
        1.0 -
        (math.min((leftShoulder.y - rightShoulder.y).abs(), _maxShoulderDiff) /
            _maxShoulderDiff);

    double leftHeight = math.max(0, (leftShoulder.y - leftWrist.y));
    double rightHeight = math.max(0, (rightShoulder.y - rightWrist.y));
    double heightQuality = (leftHeight + rightHeight) / 2.0;

    double leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    double angleQuality =
        1.0 - (math.min(leftAngle, rightAngle) / _minArmAngle);

    double confidenceQuality =
        math.min(
          math.min(leftShoulder.likelihood, rightShoulder.likelihood),
          math.min(
            math.min(leftElbow.likelihood, rightElbow.likelihood),
            math.min(leftWrist.likelihood, rightWrist.likelihood),
          ),
        ) /
        _minConfidence;

    return (shoulderStability * 0.3 +
            heightQuality * 0.3 +
            angleQuality * 0.2 +
            confidenceQuality * 0.2)
        .clamp(0.0, 1.0);
  }

  bool _isArmsBent(
    PoseLandmark leftShoulder,
    PoseLandmark leftElbow,
    PoseLandmark leftWrist,
    PoseLandmark rightShoulder,
    PoseLandmark rightElbow,
    PoseLandmark rightWrist,
  ) {
    double leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);

    double leftWristY = leftWrist.y;
    double rightWristY = rightWrist.y;
    double leftShoulderY = leftShoulder.y;
    double rightShoulderY = rightShoulder.y;

    bool properArmAngles = leftAngle < 60 && rightAngle < 60;
    bool properHeight =
        (leftWristY <= leftShoulderY && rightWristY <= rightShoulderY);
    bool stablePosition = (leftShoulderY - rightShoulderY).abs() < 0.1;
    bool highConfidence =
        leftShoulder.likelihood > 0.7 &&
        rightShoulder.likelihood > 0.7 &&
        leftElbow.likelihood > 0.7 &&
        rightElbow.likelihood > 0.7 &&
        leftWrist.likelihood > 0.7 &&
        rightWrist.likelihood > 0.7;

    return properArmAngles && properHeight && stablePosition && highConfidence;
  }

  double _calculateAngle(
    PoseLandmark shoulder,
    PoseLandmark elbow,
    PoseLandmark wrist,
  ) {
    double dx1 = shoulder.x - elbow.x;
    double dy1 = shoulder.y - elbow.y;
    double dx2 = wrist.x - elbow.x;
    double dy2 = wrist.y - elbow.y;

    double angle =
        (180 / math.pi) *
        math.acos(
          (dx1 * dx2 + dy1 * dy2) /
              (math.sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2))),
        );

    return angle;
  }

  Color _getQualityColor(double quality) {
    if (quality < 0.3) {
      return Colors.red;
    } else if (quality < 0.6) {
      return Colors.orange;
    } else if (quality < 0.8) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Auto-save session when user swipes back
        await _saveSessionToHistory();
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
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
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.height,
                            ),
                            painter: PosePainter(
                              pose: _currentPose!,
                              imageSize: Size(
                                _controller.value.previewSize!.height,
                                _controller.value.previewSize!.width,
                              ),
                              screenSize: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height,
                              ),
                              cameraLensDirection: _currentCamera.lensDirection,
                            ),
                          ),
                        if (_currentPose != null) const SizedBox.shrink(),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2196F3)),
                  );
                }
              },
            ),
            // Top HUD with modern design
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Pull-up counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fitness_center_rounded,
                              color: Color(0xFF2196F3),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_repCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.exerciseType,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Form feedback
                      if (_formFeedback.isNotEmpty)
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isProperForm
                                    ? Icons.check_circle_rounded
                                    : Icons.info_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _formFeedback,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
                                    fontWeight: FontWeight.w600,
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
                              child: SizedBox(
                                height: 6,
                                child: LinearProgressIndicator(
                                  value: _repQuality,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    _getQualityColor(_repQuality),
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
            // Rotate Camera Button
            if (widget.cameras.length > 1)
              Positioned(
                bottom: 100,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E).withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                    ),
                  ),
                  child: IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Switch Camera',
                  ),
                ),
              ),
            // Bottom END button with modern design
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm =
                          await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1F2E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'End Session?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: const Text(
                                'Your pull-up count will be saved to history.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'End Session',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirm) return;

                      await _saveSessionToHistory();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
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
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 24),
                    label: const Text(
                      'End Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
