import 'dart:collection';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Smooths pose landmarks using a moving average filter.
/// This reduces jitter in ML Kit output and makes angle calculations more stable.
class PoseSmoother {
  /// Number of frames to average (3-5 recommended)
  final int windowSize;

  /// History of landmark positions for each landmark type
  final Map<PoseLandmarkType, Queue<_LandmarkPoint>> _history = {};

  /// Key landmarks to smooth (the ones used for angle calculations)
  static const List<PoseLandmarkType> _keyLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  PoseSmoother({this.windowSize = 3});

  /// Returns a smoothed version of the pose landmarks.
  /// Non-key landmarks are returned as-is.
  Map<PoseLandmarkType, PoseLandmark> smooth(Pose pose) {
    final smoothedLandmarks = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final landmark = entry.value;

      if (_keyLandmarks.contains(type)) {
        // Smooth key landmarks
        smoothedLandmarks[type] = _smoothLandmark(type, landmark);
      } else {
        // Pass through non-key landmarks unchanged
        smoothedLandmarks[type] = landmark;
      }
    }

    return smoothedLandmarks;
  }

  /// Smooth a single landmark using moving average
  PoseLandmark _smoothLandmark(PoseLandmarkType type, PoseLandmark landmark) {
    // Initialize queue if needed
    _history.putIfAbsent(type, () => Queue<_LandmarkPoint>());
    final queue = _history[type]!;

    // Add current point to history
    queue.addLast(
      _LandmarkPoint(
        x: landmark.x,
        y: landmark.y,
        z: landmark.z,
        likelihood: landmark.likelihood,
      ),
    );

    // Remove old points if we exceed window size
    while (queue.length > windowSize) {
      queue.removeFirst();
    }

    // Calculate weighted average (more recent = higher weight)
    double sumX = 0, sumY = 0, sumZ = 0, sumLikelihood = 0;
    double totalWeight = 0;
    int weight = 1;

    for (final point in queue) {
      sumX += point.x * weight;
      sumY += point.y * weight;
      sumZ += point.z * weight;
      sumLikelihood += point.likelihood * weight;
      totalWeight += weight;
      weight++; // Increase weight for more recent frames
    }

    // Return smoothed landmark with averaged coordinates
    return PoseLandmark(
      type: type,
      x: sumX / totalWeight,
      y: sumY / totalWeight,
      z: sumZ / totalWeight,
      likelihood: sumLikelihood / totalWeight,
    );
  }

  /// Clear all history (call when switching exercises or resetting)
  void reset() {
    _history.clear();
  }
}

/// Internal class to store landmark position data
class _LandmarkPoint {
  final double x;
  final double y;
  final double z;
  final double likelihood;

  _LandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });
}
