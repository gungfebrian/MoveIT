// lib/screens/workout_player_screen.dart
// Workout player with timer and exercise progression

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final WorkoutRoutine workout;

  const WorkoutPlayerScreen({super.key, required this.workout});

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen>
    with TickerProviderStateMixin {
  // Premium Dark Theme
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _cardBg = Color(0xFF12121A);
  static const Color _primaryOrange = Color(0xFFF97316);
  static const Color _accentOrange = Color(0xFFFB923C);

  // State
  int _currentExerciseIndex = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;
  late AnimationController _pulseController;

  Exercise get _currentExercise =>
      widget.workout.exercises[_currentExerciseIndex];
  bool get _isLastExercise =>
      _currentExerciseIndex >= widget.workout.exercises.length - 1;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _currentExercise.durationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _nextExercise();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _nextExercise() {
    if (_isLastExercise) {
      _completeWorkout();
    } else {
      setState(() {
        _currentExerciseIndex++;
        _remainingSeconds = _currentExercise.durationSeconds;
      });
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _remainingSeconds = _currentExercise.durationSeconds;
      });
    }
  }

  Future<void> _completeWorkout() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });

    // Save to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .add({
              'workoutId': widget.workout.id,
              'workoutTitle': widget.workout.title,
              'calories': widget.workout.calories,
              'durationMinutes': widget.workout.totalDurationMinutes,
              'timestamp': Timestamp.now(),
              'type': 'routine',
            });
      }
    } catch (e) {
      debugPrint('Error saving workout: $e');
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryOrange.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 24),

                // Progress
                _buildProgressIndicator(),

                const Spacer(),

                // Current Exercise
                _buildCurrentExercise(),

                const Spacer(),

                // Timer
                _buildTimer(),

                const SizedBox(height: 32),

                // Controls
                _buildControls(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _cardBg, shape: BoxShape.circle),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.workout.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentExerciseIndex + 1} / ${widget.workout.exercises.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(widget.workout.exercises.length, (index) {
          final isCompleted = index < _currentExerciseIndex;
          final isCurrent = index == _currentExerciseIndex;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? _primaryOrange
                    : isCurrent
                    ? _primaryOrange.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentExercise() {
    final isRest = _currentExercise.name.toLowerCase().contains('rest');

    return Column(
      children: [
        // Exercise Icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_isRunning ? _pulseController.value * 0.1 : 0);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isRest
                        ? [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.1),
                          ]
                        : [
                            _primaryOrange.withOpacity(0.2),
                            _accentOrange.withOpacity(0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isRest
                      ? Icons.self_improvement_rounded
                      : Icons.fitness_center_rounded,
                  size: 48,
                  color: isRest ? Colors.green : _primaryOrange,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Exercise Name
        Text(
          _currentExercise.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        // Description
        if (_currentExercise.description != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _currentExercise.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimer() {
    final progress = _remainingSeconds / _currentExercise.durationSeconds;

    return Column(
      children: [
        // Circular Timer
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Circle
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Progress Circle
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(_primaryOrange),
                ),
              ),
              // Time Text
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous
          IconButton(
            onPressed: _currentExerciseIndex > 0 ? _previousExercise : null,
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 36,
              color: _currentExerciseIndex > 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),

          // Play/Pause
          GestureDetector(
            onTap: _isRunning ? _pauseTimer : _startTimer,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_primaryOrange, _accentOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          // Next
          IconButton(
            onPressed: _nextExercise,
            icon: const Icon(
              Icons.skip_next_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _primaryOrange.withOpacity(0.2),
                      _accentOrange.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: _primaryOrange,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Workout Complete! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'You burned ${widget.workout.calories} calories',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 48),

              // Done Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryOrange, _accentOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Workout?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Your progress will not be saved.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
