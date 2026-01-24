import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// Abstract base class for all workout detection logic.
abstract class WorkoutLogic {
  void process(Pose pose);
  String get feedback;
  int get repCount;
  double get repQuality;
  bool get isProperForm;
  String get exerciseName;
  Color get themeColor;
  IconData get icon;
  void reset();

  /// Calculates the angle between three landmarks: A -> B -> C
  /// Uses the robust vector dot product method
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Vector from B to A
    double dx1 = a.x - b.x;
    double dy1 = a.y - b.y;
    // Vector from B to C
    double dx2 = c.x - b.x;
    double dy2 = c.y - b.y;

    // Use dot product formula: cos(angle) = (v1 · v2) / (|v1| * |v2|)
    double dotProduct = dx1 * dx2 + dy1 * dy2;
    double magnitude1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    double magnitude2 = math.sqrt(dx2 * dx2 + dy2 * dy2);

    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    double cosAngle = dotProduct / (magnitude1 * magnitude2);
    // Clamp to prevent NaN from floating point errors
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    double angle = math.acos(cosAngle) * (180 / math.pi);
    return angle.isNaN ? 0 : angle;
  }
}

/// Push-Up detection logic based on Python PushUpCounter.py algorithm.
/// Key Landmarks:
/// 11(Left Shoulder), 13(Left Elbow), 15(Left Wrist) -> Elbow Angle
/// 11(Left Shoulder), 23(Left Hip), 25(Left Knee) -> Hip/Body Alignment
class PushUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Get in plank position...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // State Machine
  // 0 = Up/Start (Elbow > 160)
  // 1 = Going Down
  // 2 = Bottom (Elbow < 90)
  int _direction = 0;

  @override
  String get exerciseName => 'Push-Up';

  @override
  Color get themeColor => const Color(0xFFFF5722); // Deep Orange

  @override
  IconData get icon => Icons.fitness_center;

  @override
  String get feedback => _feedback;

  @override
  int get repCount => _repCount;

  @override
  double get repQuality => _repQuality;

  @override
  bool get isProperForm => _isProperForm;

  @override
  void reset() {
    _repCount = 0;
    _feedback = 'Get in plank position...';
    _isProperForm = false;
    _repQuality = 0.0;
    _direction = 0;
  }

  @override
  void process(Pose pose) {
    // We primarily use the LEFT side for standard side-view detection
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    // Safety Check: Ensure all points are visible
    if (leftShoulder == null ||
        leftElbow == null ||
        leftWrist == null ||
        leftHip == null ||
        leftKnee == null ||
        leftShoulder.likelihood < 0.5 ||
        leftElbow.likelihood < 0.5) {
      _feedback = 'Position full body in frame';
      return;
    }

    // 1. Calculate Angles
    // Elbow Angle (Arm straightness)
    double elbowAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );

    // Hip Angle (Body straightness) - Important for form
    double hipAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee,
    );

    // Debug: Log angles periodically (only in debug mode)
    assert(() {
      // This runs only in debug mode
      if (_repCount % 5 == 0 || _direction == 1) {
        debugPrint(
          '💪 Elbow: ${elbowAngle.toStringAsFixed(0)}° | Hip: ${hipAngle.toStringAsFixed(0)}° | Reps: $_repCount',
        );
      }
      return true;
    }());

    // 2. Assess Form Quality (0.0 to 1.0)
    // Good form means body is straight (hip angle close to 180)
    // If hip drops or pikes (angle < 150), quality drops
    double bodyStraightness = (hipAngle / 180.0);
    if (hipAngle < 150) {
      _isProperForm = false;
      _feedback = "Keep body straight!";
      _repQuality = bodyStraightness * 0.5; // Penalize bad form
    } else {
      _isProperForm = true;
      _repQuality = bodyStraightness;
    }

    // 3. Rep Counting Logic (State Machine)
    // Thresholds from your Python script:
    // UP: Elbow > 160
    // DOWN: Elbow < 90

    // Going DOWN
    if (elbowAngle <= 90) {
      if (_direction == 0) {
        // Successful rep completion from top to bottom?
        // No, typically we count when they come back UP.
        // But we mark "bottom reached" here.
        _direction = 1; // 1 means we hit bottom
        _feedback = "Push Up!";
      }
    }

    // Going UP (Back to start)
    if (elbowAngle >= 160) {
      if (_direction == 1) {
        // We were at bottom, now we are at top -> Count it!
        _repCount++;
        _direction = 0; // Reset state
        _feedback = "Good rep!";
      } else {
        if (_isProperForm) {
          _feedback = "Go Down";
        }
      }
    }

    // Intermediate feedback
    if (_direction == 0 && elbowAngle < 160 && elbowAngle > 90) {
      _feedback = "Lower...";
    } else if (_direction == 1 && elbowAngle > 90 && elbowAngle < 160) {
      _feedback = "Push...";
    }
  }
}

/// Sit-Up detection logic based on Python situp_realtime.py.
/// Key Landmarks: 11(Shoulder), 23(Hip), 25(Knee)
class SitUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Lie down...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // State Machine
  // 0 = Down (Lying flat)
  // 1 = Up (Sitting up)
  int _state = 0;

  @override
  String get exerciseName => 'Sit-Up';

  @override
  Color get themeColor => const Color(0xFF9C27B0); // Purple

  @override
  IconData get icon => Icons.accessibility_new;

  @override
  String get feedback => _feedback;

  @override
  int get repCount => _repCount;

  @override
  double get repQuality => _repQuality;

  @override
  bool get isProperForm => _isProperForm;

  @override
  void reset() {
    _repCount = 0;
    _feedback = 'Lie down...';
    _isProperForm = false;
    _repQuality = 0.0;
    _state = 0;
  }

  @override
  void process(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) {
      _feedback = 'Show side view';
      return;
    }

    // Calculate Torso-Leg Angle
    double angle = WorkoutLogic.calculateAngle(leftShoulder, leftHip, leftKnee);

    // Python Logic Translation:
    // angle > 117  -> DOWN (Lying)
    // angle < 55   -> UP (Curled close to knees)
    // angle < 89   -> Standard UP threshold

    // Quality metric: How close to vertical/knees did they get?
    // Max compression is ~40 degrees. Flat is ~180.
    if (angle < 90) {
      _repQuality = (90 - angle) / 50.0; // Higher score for tighter curl
      if (_repQuality > 1.0) _repQuality = 1.0;
    } else {
      _repQuality = 0.5;
    }

    // State Machine
    if (angle > 117) {
      // User is lying down
      if (_state == 1) {
        // They just finished a rep
        _feedback = "Go Up!";
      } else {
        _feedback = "Ready";
      }
      _state = 0; // Reset to down state
      _isProperForm = true;
    } else if (angle < 80) {
      // Using 80 as a robust "UP" threshold (python used 89/55)
      // User is sitting up
      if (_state == 0) {
        _repCount++;
        _state = 1; // Mark as Up
        _feedback = "Good! Down";
      }
      _isProperForm = true;
    } else {
      // In motion
      if (_state == 0)
        _feedback = "Up...";
      else
        _feedback = "Down...";
    }
  }
}

/// Pull-Up detection logic.
/// Key Landmarks: Shoulders, Elbows, Wrists
class PullUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Hang from bar...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // State: 0 = Down (Arms straight), 1 = Up (Chin over bar)
  int _state = 0;

  @override
  String get exerciseName => 'Pull-Up';

  @override
  Color get themeColor => const Color(0xFF2196F3); // Blue

  @override
  IconData get icon => Icons.arrow_upward;

  @override
  String get feedback => _feedback;

  @override
  int get repCount => _repCount;

  @override
  double get repQuality => _repQuality;

  @override
  bool get isProperForm => _isProperForm;

  @override
  void reset() {
    _repCount = 0;
    _feedback = 'Hang from bar...';
    _isProperForm = false;
    _repQuality = 0.0;
    _state = 0;
  }

  @override
  void process(Pose pose) {
    // We check both arms for pullups
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null ||
        leftElbow == null ||
        leftWrist == null ||
        rightShoulder == null ||
        rightElbow == null ||
        rightWrist == null) {
      _feedback = 'Full upper body needed';
      return;
    }

    // Calculate Angles
    double leftArmAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    double rightArmAngle = WorkoutLogic.calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );

    double avgArmAngle = (leftArmAngle + rightArmAngle) / 2;

    // Logic:
    // DOWN: Arms straight (Angle > 150)
    // UP: Arms bent (Angle < 70) AND Chin likely above bar (Wrist close to Shoulder Y)

    // Quality: How high did they pull? (Lower angle = higher pull)
    if (avgArmAngle < 90) {
      _repQuality = (90 - avgArmAngle) / 40.0;
      if (_repQuality > 1.0) _repQuality = 1.0;
    }

    // State Machine
    if (avgArmAngle > 150) {
      // Arms fully extended
      if (_state == 1) {
        _feedback = "Pull Up!";
      } else {
        _feedback = "Ready";
      }
      _state = 0; // Down state
      _isProperForm = true;
    } else if (avgArmAngle < 70) {
      // Arms flexed (Top position)
      if (_state == 0) {
        _repCount++;
        _state = 1; // Up state
        _feedback = "Good! Lower";
      }
      _isProperForm = true;
    } else {
      // Motion
      if (_state == 0)
        _feedback = "Higher...";
      else
        _feedback = "Lower...";
    }
  }
}

class WorkoutLogicFactory {
  static WorkoutLogic create(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'push-up':
      case 'pushup':
        return PushUpLogic();
      case 'sit-up':
      case 'situp':
        return SitUpLogic();
      case 'pull-up':
      case 'pullup':
      default:
        return PullUpLogic();
    }
  }
}
