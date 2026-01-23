import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

/// Abstract base class for all workout detection logic.
/// Each exercise type implements its own detection algorithm.
abstract class WorkoutLogic {
  /// Process a pose frame and update internal state
  void process(Pose pose);

  /// Current feedback message to display to user
  String get feedback;

  /// Current rep count
  int get repCount;

  /// Current rep quality (0.0 to 1.0)
  double get repQuality;

  /// Whether user is in proper form
  bool get isProperForm;

  /// Exercise name for display
  String get exerciseName;

  /// Theme color for UI
  Color get themeColor;

  /// Icon for UI
  IconData get icon;

  /// Reset all state to initial values
  void reset();

  /// Helper to calculate angle between three landmarks
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
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
}

/// Push-Up detection logic based on Python PushUpCounter.py algorithm.
/// Angles: elbow (11,13,15), shoulder (13,11,23), hip (11,23,25)
class PushUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Get in plank position...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // Push-up state machine
  int _direction = 0; // 0 = ready for down, 1 = ready for up
  int _form = 0; // 0 = form not validated, 1 = form OK

  @override
  String get exerciseName => 'Push-Up';

  @override
  Color get themeColor => const Color(0xFFFF5722); // Orange

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
    _feedback = 'Get in plank position...';
    _isProperForm = false;
    _repQuality = 0.0;
    _direction = 0;
    _form = 0;
  }

  @override
  void process(Pose pose) {
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
      _feedback = 'Position full body in frame';
      return;
    }

    // Calculate angles matching Python code
    double elbowAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    double shoulderAngle = WorkoutLogic.calculateAngle(
      leftElbow,
      leftShoulder,
      leftHip,
    );
    double hipAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftHip,
      leftKnee,
    );

    // Calculate quality based on hip alignment
    _repQuality = (hipAngle > 140) ? 0.8 : (hipAngle / 180.0).clamp(0.0, 1.0);

    // Check for proper starting form: elbow > 160, shoulder > 40, hip > 160
    if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
      _form = 1;
    }

    if (_form == 1) {
      // DOWN position: elbow <= 90 AND hip > 160 (body straight)
      if (elbowAngle <= 90 && hipAngle > 160) {
        _feedback = 'Push Up!';
        _isProperForm = true;
        if (_direction == 0) {
          _repCount++;
          _direction = 1;
          debugPrint('💪 Push-up count: $_repCount');
        }
      }
      // UP position: elbow > 160, shoulder > 40, hip > 160
      else if (elbowAngle > 160 && shoulderAngle > 40 && hipAngle > 160) {
        _feedback = 'Go Down!';
        _isProperForm = true;
        if (_direction == 1) {
          _direction = 0;
        }
      } else {
        _feedback = 'Fix Form - Keep body straight';
        _isProperForm = false;
      }
    } else {
      _feedback = 'Get in plank position';
      _isProperForm = false;
    }
  }
}

/// Sit-Up detection logic based on Python situp_realtime.py algorithm.
/// Angle: shoulder(11) -> hip(23) -> knee(25)
/// DOWN: angle >= 117, UP: angle <= 89
class SitUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Lie down to start...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // Sit-up state machine
  String _stage = 'down'; // 'down' or 'up'

  @override
  String get exerciseName => 'Sit-Up';

  @override
  Color get themeColor => const Color(0xFF9C27B0); // Purple

  @override
  IconData get icon => Icons.self_improvement;

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
    _feedback = 'Lie down to start...';
    _isProperForm = false;
    _repQuality = 0.0;
    _stage = 'down';
  }

  @override
  void process(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) {
      _feedback = 'Position body in side view';
      return;
    }

    // Calculate angle: shoulder → hip → knee
    double angle = WorkoutLogic.calculateAngle(leftShoulder, leftHip, leftKnee);

    // Calculate quality based on angle
    _repQuality = angle < 100 ? 1.0 : ((180 - angle) / 80.0).clamp(0.0, 1.0);

    // DOWN state: angle >= 117 (lying flat)
    if (angle >= 117) {
      _stage = 'down';
      _feedback = 'Sit Up!';
      _isProperForm = true;
    }

    // UP state: angle <= 89 AND was in down position
    if (angle <= 89 && _stage == 'down') {
      _stage = 'up';
      _repCount++;
      _feedback = 'Great! Go back down';
      _isProperForm = true;
      debugPrint('💪 Sit-up count: $_repCount');
    } else if (angle > 89 && angle < 117) {
      _feedback = _stage == 'down' ? 'Keep going up!' : 'Go back down';
      _isProperForm = false;
    }
  }
}

/// Pull-Up detection logic.
/// Uses arm angles and wrist-to-shoulder position.
class PullUpLogic extends WorkoutLogic {
  int _repCount = 0;
  String _feedback = 'Detecting pose...';
  bool _isProperForm = false;
  double _repQuality = 0.0;

  // Pull-up state
  bool _isInUpPosition = false;
  DateTime? _lastRepTime;
  static const Duration _minRepDuration = Duration(milliseconds: 1500);
  static const double _minArmAngle = 60.0;
  static const double _maxShoulderDiff = 0.1;
  static const double _minConfidence = 0.7;

  @override
  String get exerciseName => 'Pull-Up';

  @override
  Color get themeColor => const Color(0xFF2196F3); // Blue

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
    _feedback = 'Detecting pose...';
    _isProperForm = false;
    _repQuality = 0.0;
    _isInUpPosition = false;
    _lastRepTime = null;
  }

  @override
  void process(Pose pose) {
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
      _feedback = 'Position full body in frame';
      return;
    }

    // Calculate arm angles
    double leftAngle = WorkoutLogic.calculateAngle(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    double rightAngle = WorkoutLogic.calculateAngle(
      rightShoulder,
      rightElbow,
      rightWrist,
    );

    // Check form criteria
    bool properArmAngles = leftAngle < 60 && rightAngle < 60;
    bool properHeight =
        (leftWrist.y <= leftShoulder.y && rightWrist.y <= rightShoulder.y);
    bool stablePosition = (leftShoulder.y - rightShoulder.y).abs() < 0.1;
    bool highConfidence =
        leftShoulder.likelihood > 0.7 &&
        rightShoulder.likelihood > 0.7 &&
        leftElbow.likelihood > 0.7 &&
        rightElbow.likelihood > 0.7 &&
        leftWrist.likelihood > 0.7 &&
        rightWrist.likelihood > 0.7;

    _isProperForm =
        properArmAngles && properHeight && stablePosition && highConfidence;

    // Calculate quality
    double shoulderStability =
        1.0 -
        (math.min((leftShoulder.y - rightShoulder.y).abs(), _maxShoulderDiff) /
            _maxShoulderDiff);
    double leftHeight = math.max(0, (leftShoulder.y - leftWrist.y));
    double rightHeight = math.max(0, (rightShoulder.y - rightWrist.y));
    double heightQuality = (leftHeight + rightHeight) / 2.0;
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

    _repQuality =
        (shoulderStability * 0.3 +
                heightQuality * 0.3 +
                angleQuality * 0.2 +
                confidenceQuality * 0.2)
            .clamp(0.0, 1.0);

    // Update feedback
    if (!_isProperForm) {
      if (_repQuality < 0.3) {
        _feedback = "Keep your shoulders level and face forward";
      } else if (_repQuality < 0.6) {
        _feedback = "Pull up higher, chin over the bar";
      } else {
        _feedback = "Almost there! Keep going";
      }
    } else {
      _feedback = "Great form!";
    }

    // Count reps
    if (_isProperForm && !_isInUpPosition) {
      final now = DateTime.now();
      if (_lastRepTime == null ||
          now.difference(_lastRepTime!) >= _minRepDuration) {
        _isInUpPosition = true;
        _repCount++;
        _lastRepTime = now;
        debugPrint('💪 Pull-up count: $_repCount');
      }
    } else if (!_isProperForm && _isInUpPosition) {
      _isInUpPosition = false;
    }
  }
}

/// Factory to create the appropriate WorkoutLogic based on exercise type
class WorkoutLogicFactory {
  static WorkoutLogic create(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'push-up':
      case 'pushup':
      case 'push up':
        return PushUpLogic();
      case 'sit-up':
      case 'situp':
      case 'sit up':
        return SitUpLogic();
      case 'pull-up':
      case 'pullup':
      case 'pull up':
      default:
        return PullUpLogic();
    }
  }
}
