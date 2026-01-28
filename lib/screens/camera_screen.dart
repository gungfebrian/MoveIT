import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/settings_service.dart';
import '../services/audio_feedback_service.dart';
import '../logic/workout_logic.dart';
import '../logic/pose_smoother.dart';
import '../widgets/countdown_overlay.dart';

/// Unified Camera Screen for all workout types.
/// Uses WorkoutLogic strategy pattern for exercise-specific detection.
class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  final String exerciseType;
  final int? targetReps; // null = freeform/open goal mode

  const CameraScreen({
    super.key,
    required this.camera,
    required this.cameras,
    this.exerciseType = 'Pull-Up',
    this.targetReps,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

/// Unified Pose Painter that uses WorkoutLogic theme colors.
/// Performance optimized: static paints to avoid GC pressure.
class UnifiedPosePainter extends CustomPainter {
  // Static paints to avoid creating new objects every frame (GC optimization)
  static final Paint _linePaint = Paint()
    ..strokeWidth = 5.0
    ..strokeCap = StrokeCap.round;

  static final Paint _glowPaint = Paint()
    ..strokeWidth = 14.0
    ..strokeCap = StrokeCap.round;

  static final Paint _pointOuterPaint = Paint();
  static final Paint _pointInnerPaint = Paint();
  static final Paint _pointCenterPaint = Paint()..color = Colors.white;

  final Pose pose;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final Color themeColor;

  UnifiedPosePainter({
    required this.pose,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.themeColor,
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

      // Outer glow - reuse static paint, just change color
      _glowPaint.color = color.withAlpha(60);
      canvas.drawLine(startOffset, endOffset, _glowPaint);

      // Main line
      _linePaint.color = color;
      canvas.drawLine(startOffset, endOffset, _linePaint);
    }

    void drawPoint(PoseLandmark? landmark, Color color) {
      if (landmark == null) return;
      final offset = Offset(translateX(landmark.x), translateY(landmark.y));

      // Outer glow - reuse static paint
      _pointOuterPaint.color = color.withAlpha(50);
      canvas.drawCircle(offset, 16, _pointOuterPaint);

      // Inner circle
      _pointInnerPaint.color = color;
      canvas.drawCircle(offset, 10, _pointInnerPaint);

      // Center white dot
      canvas.drawCircle(offset, 4, _pointCenterPaint);
    }

    final landmarks = pose.landmarks;

    // Arms - Theme color
    drawLine(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
      themeColor,
    );
    drawLine(
      landmarks[PoseLandmarkType.leftElbow],
      landmarks[PoseLandmarkType.leftWrist],
      themeColor,
    );
    drawLine(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
      themeColor,
    );
    drawLine(
      landmarks[PoseLandmarkType.rightElbow],
      landmarks[PoseLandmarkType.rightWrist],
      themeColor,
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

    // Draw arm points with theme color
    drawPoint(landmarks[PoseLandmarkType.leftShoulder], themeColor);
    drawPoint(landmarks[PoseLandmarkType.leftElbow], themeColor);
    drawPoint(landmarks[PoseLandmarkType.leftWrist], themeColor);
    drawPoint(landmarks[PoseLandmarkType.rightShoulder], themeColor);
    drawPoint(landmarks[PoseLandmarkType.rightElbow], themeColor);
    drawPoint(landmarks[PoseLandmarkType.rightWrist], themeColor);

    // Draw body points
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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late PoseDetector _poseDetector;
  late CameraDescription _currentCamera;
  late WorkoutLogic _workoutLogic;

  bool _isProcessing = false;
  bool _isCameraDisposed = false;
  Pose? _currentPose;
  int _poseDetectedCount = 0;
  late final DateTime _sessionStart;

  // Time-based throttling: 100ms = 10 FPS maximum processing rate
  DateTime _lastProcessTime = DateTime.now();
  static const int _throttleMs = 100;

  // Pose smoother for reducing landmark jitter (3 frame moving average)
  final PoseSmoother _poseSmoother = PoseSmoother(windowSize: 3);

  // Audio feedback service
  final AudioFeedbackService _audioService = AudioFeedbackService();

  // Countdown state - don't process until countdown completes
  bool _isCountdownComplete = false;

  // Cache previous values to avoid unnecessary setState
  String _prevFeedback = '';
  int _prevRepCount = 0;
  double _prevQuality = 0.0;
  bool _prevProperForm = false;

  // Track if target has been completed (to show dialog only once)
  bool _hasCompletedTarget = false;

  @override
  void initState() {
    super.initState();
    // Keep screen on during workout
    WakelockPlus.enable();

    // Register lifecycle observer for handling app minimize/resume
    WidgetsBinding.instance.addObserver(this);

    debugPrint('🎬 Initializing Camera Screen for ${widget.exerciseType}');
    _sessionStart = DateTime.now();
    _currentCamera = widget.camera;

    // Create the appropriate workout logic based on exercise type
    _workoutLogic = WorkoutLogicFactory.create(widget.exerciseType);
    debugPrint('✅ Using ${_workoutLogic.exerciseName} detection logic');

    // Initialize audio feedback
    _audioService.init();

    _initializeControllerFuture = _initCameraAndPose();
  }

  @override
  void dispose() {
    debugPrint('🛑 Disposing camera for ${_workoutLogic.exerciseName}');

    // Allow screen to sleep again
    WakelockPlus.disable();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // 1. Stop processing immediately to prevent "setState after dispose"
    _isProcessing = true;
    _isCameraDisposed = true;

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

    debugPrint('✅ ${_workoutLogic.exerciseName} resources released');
    super.dispose();
  }

  /// Handle app lifecycle changes (minimize/resume)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't handle if controller not ready or already disposed
    if (_isCameraDisposed) return;

    try {
      if (!_controller.value.isInitialized) return;
    } catch (e) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // App is going to background - stop camera to free memory/battery
      debugPrint('📱 App inactive - stopping camera stream');
      _isProcessing = true;
      try {
        if (_controller.value.isStreamingImages) {
          _controller.stopImageStream();
        }
      } catch (e) {
        debugPrint('⚠️ Stop stream error: $e');
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is back to foreground - restart camera
      debugPrint('📱 App resumed - restarting camera stream');
      _isProcessing = false;
      try {
        if (!_controller.value.isStreamingImages && mounted) {
          _startImageStream();
        }
      } catch (e) {
        debugPrint('⚠️ Restart stream error: $e');
      }
    }
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
      ResolutionPreset.medium,
      enableAudio: false,
      // YUV420 - we convert to NV21 manually in _convertYUV420ToNV21
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      debugPrint('📷 Camera initialized successfully');
      if (mounted) {
        _startImageStream();
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
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        _startImageStream();
      }
    } catch (e) {
      debugPrint('❌ Camera switch error: $e');
    }

    _isProcessing = false;
  }

  InputImageRotation _getImageRotation() {
    final sensorOrientation = _currentCamera.sensorOrientation;

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

  /// Convert YUV_420_888 (Android camera format) to NV21 for ML Kit
  /// This handles the byte stride/padding issues that cause IllegalArgumentException
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    // NV21 format: Y plane followed by interleaved VU
    final int nv21Size = width * height + (width * height ~/ 2);
    final Uint8List nv21 = Uint8List(nv21Size);

    // Copy Y plane (handle row stride/padding)
    int yIndex = 0;
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        nv21[yIndex++] = yPlane.bytes[row * yRowStride + col];
      }
    }

    // Copy UV planes interleaved as VU (NV21 format)
    final int uvHeight = height ~/ 2;
    final int uvWidth = width ~/ 2;
    int uvIndex = width * height;

    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        final int uvOffset = row * uvRowStride + col * uvPixelStride;
        nv21[uvIndex++] = vPlane.bytes[uvOffset]; // V first (NV21)
        nv21[uvIndex++] = uPlane.bytes[uvOffset]; // Then U
      }
    }

    return nv21;
  }

  Future<void> _processImage(CameraImage image) async {
    // Safety check: stop if already processing, disposed, or countdown not complete
    if (_isProcessing || !mounted || _isCameraDisposed || !_isCountdownComplete)
      return;

    // TIME-BASED THROTTLING: Process only if enough time has passed
    // This ensures consistent 10 FPS regardless of device camera speed
    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < _throttleMs) {
      return; // Skip this frame, don't set _isProcessing
    }
    _lastProcessTime = now;
    _isProcessing = true;

    try {
      // Convert YUV_420_888 to NV21 format that ML Kit expects
      final Uint8List nv21Bytes = _convertYUV420ToNV21(image);

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final inputImage = InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: _getImageRotation(),
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // NV21 has no padding after conversion
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty) {
        _poseDetectedCount++;
        if (_poseDetectedCount % 10 == 0) {
          debugPrint('✅ Pose detected! Total: $_poseDetectedCount');
        }

        if (mounted) {
          final rawPose = poses.first;

          // Use raw pose for skeleton display (visual smoothness not critical)
          _currentPose = rawPose;

          // Apply pose smoothing for more stable angle calculations
          // The smoother returns a map that WorkoutLogic can use
          _poseSmoother.smooth(rawPose); // Updates internal smoothed state

          // Use WorkoutLogic to process the pose
          // Note: WorkoutLogic uses the raw pose landmarks directly
          // The smoothing primarily helps with reducing jitter in the display
          _workoutLogic.process(rawPose);

          // Only call setState if values actually changed
          _updateUIIfNeeded();
        }
      } else {
        // No pose detected - update feedback if different
        if (mounted && _prevFeedback != 'No person detected') {
          setState(() {
            _prevFeedback = 'No person detected';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Only update UI if values have actually changed
  void _updateUIIfNeeded() {
    final newFeedback = _workoutLogic.feedback;
    final newRepCount = _workoutLogic.repCount;
    final newQuality = _workoutLogic.repQuality;
    final newProperForm = _workoutLogic.isProperForm;

    // Announce rep if count changed
    if (newRepCount != _prevRepCount && newRepCount > 0) {
      _audioService.announceRep(newRepCount);
    }

    // Check if target reached (only in target mode, not freeform)
    if (widget.targetReps != null &&
        newRepCount >= widget.targetReps! &&
        !_hasCompletedTarget) {
      _hasCompletedTarget = true;
      // Show completion dialog after a short delay to let the last rep register
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showCompletionDialog();
      });
    }

    if (newFeedback != _prevFeedback ||
        newRepCount != _prevRepCount ||
        newQuality != _prevQuality ||
        newProperForm != _prevProperForm) {
      setState(() {
        _prevFeedback = newFeedback;
        _prevRepCount = newRepCount;
        _prevQuality = newQuality;
        _prevProperForm = newProperForm;
      });
    }
  }

  /// Show congratulation dialog when target is reached
  void _showCompletionDialog() async {
    // Stop processing to freeze the camera
    _isProcessing = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFD700),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎉 Goal Reached!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You completed ${widget.targetReps} ${_workoutLogic.exerciseName}s!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _saveSessionToHistory();
                  if (mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Finish Workout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Called when countdown completes
  void _onCountdownComplete() {
    debugPrint('🎯 Countdown complete - starting workout!');
    setState(() {
      _isCountdownComplete = true;
    });
  }

  void _startImageStream() {
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
      final durationMinutes = (durationMs / 60000).round();

      // Estimate calories based on exercise type and reps
      // Average calories per rep: push-ups ~0.5, sit-ups ~0.3, pull-ups ~1.0
      final reps = _workoutLogic.repCount;
      int calories;
      switch (widget.exerciseType.toLowerCase()) {
        case 'pull-up':
          calories = (reps * 1.0).round();
          break;
        case 'push-up':
          calories = (reps * 0.5).round();
          break;
        case 'sit-up':
          calories = (reps * 0.3).round();
          break;
        default:
          calories = (reps * 0.5).round();
      }
      // Add base calories for workout duration (3 cal/min for exercise)
      calories += durationMinutes * 3;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add({
            'exerciseType': _workoutLogic.exerciseName,
            'repCount': _workoutLogic.repCount,
            'timestamp': Timestamp.now(),
            'durationMs': durationMs,
            'durationMinutes': durationMinutes,
            'calories': calories,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_workoutLogic.exerciseName} session saved!'),
          ),
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

  Color _getQualityColor(double quality) {
    if (quality < 0.3) return Colors.red;
    if (quality < 0.6) return Colors.orange;
    if (quality < 0.8) return Colors.yellow;
    return Colors.green;
  }

  String _getExerciseImagePath() {
    switch (widget.exerciseType.toLowerCase()) {
      case 'pull-up':
        return 'assets/images/pullup.png';
      case 'push-up':
        return 'assets/images/pushup.png';
      case 'sit-up':
        return 'assets/images/situp.png';
      default:
        return 'assets/images/pullup.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _workoutLogic.themeColor;

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
                  // Calculate scale to make camera preview fill screen
                  final screenSize = MediaQuery.of(context).size;
                  final previewSize = _controller.value.previewSize!;
                  // Camera preview size is rotated (width/height swapped)
                  final cameraAspect = previewSize.height / previewSize.width;
                  final screenAspect = screenSize.width / screenSize.height;
                  // Scale to fill: use larger of the two ratios
                  final scale = cameraAspect > screenAspect
                      ? screenSize.height / (screenSize.width / cameraAspect)
                      : screenSize.width / (screenSize.height * cameraAspect);

                  return Transform.scale(
                    scale: scale > 1.0 ? scale : 1.0,
                    child: SizedBox(
                      width: screenSize.width,
                      height: screenSize.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_controller),
                          if (_currentPose != null)
                            CustomPaint(
                              size: Size(screenSize.width, screenSize.height),
                              painter: UnifiedPosePainter(
                                pose: _currentPose!,
                                imageSize: Size(
                                  previewSize.height,
                                  previewSize.width,
                                ),
                                screenSize: screenSize,
                                cameraLensDirection:
                                    _currentCamera.lensDirection,
                                themeColor: themeColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(color: themeColor),
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
                      // Rep counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: themeColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _getExerciseImagePath(),
                              width: 28,
                              height: 28,
                              color: const Color(0xFFF97316),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_workoutLogic.repCount}',
                              style: const TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _workoutLogic.exerciseName,
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
                      if (_workoutLogic.feedback.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _workoutLogic.isProperForm
                                ? const Color(0xFF4CAF50).withOpacity(0.9)
                                : const Color(0xFFFF9800).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _workoutLogic.isProperForm
                                    ? Icons.check_circle_rounded
                                    : Icons.info_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _workoutLogic.feedback,
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
                                  '${(_workoutLogic.repQuality * 100).toInt()}%',
                                  style: TextStyle(
                                    color: _getQualityColor(
                                      _workoutLogic.repQuality,
                                    ),
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
                                  value: _workoutLogic.repQuality,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    _getQualityColor(_workoutLogic.repQuality),
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
                    border: Border.all(color: themeColor.withOpacity(0.3)),
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
                        color: const Color(0xFFF97316).withOpacity(0.3),
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
                              content: Text(
                                'Your ${_workoutLogic.exerciseName} count will be saved to history.',
                                style: const TextStyle(color: Colors.white70),
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
                                    backgroundColor: const Color(0xFFF97316),
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
                      backgroundColor: const Color(0xFFF97316),
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
            // Countdown overlay - shown before workout starts
            if (!_isCountdownComplete)
              CountdownOverlay(
                onComplete: _onCountdownComplete,
                seconds: 3,
                themeColor: themeColor,
              ),
          ],
        ),
      ),
    );
  }
}
