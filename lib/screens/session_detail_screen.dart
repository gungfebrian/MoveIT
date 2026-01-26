// lib/screens/session_detail_screen.dart
// Shows details of a completed workout session

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.sessionData,
    required this.sessionId,
  });

  // Premium Dark Theme
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _cardBg = Color(0xFF12121A);
  static const Color _primaryOrange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final type = sessionData['type'] as String? ?? 'routine';
    final isMLSession = type == 'camera' || type == 'ml';

    // ML session data
    final exerciseName = sessionData['exerciseType'] as String? ?? 'Pull-Ups';
    final repCount =
        sessionData['pullUpCount'] as int? ??
        sessionData['pushUpCount'] as int? ??
        0;

    // Routine session data
    final workoutTitle = sessionData['workoutTitle'] as String? ?? 'Workout';
    final calories = sessionData['calories'] as int? ?? 0;
    final durationMinutes = sessionData['durationMinutes'] as int? ?? 0;

    final timestamp = (sessionData['timestamp'] as Timestamp?)?.toDate();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isMLSession ? 'Exercise Session' : 'Workout Session',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Card
                        _buildHeroCard(
                          isMLSession: isMLSession,
                          exerciseName: exerciseName,
                          repCount: repCount,
                          workoutTitle: workoutTitle,
                          calories: calories,
                          durationMinutes: durationMinutes,
                          timestamp: timestamp,
                        ),

                        const SizedBox(height: 24),

                        // Stats Grid
                        if (isMLSession) ...[
                          _buildMLStats(repCount, exerciseName),
                        ] else ...[
                          _buildRoutineStats(calories, durationMinutes),
                        ],

                        const SizedBox(height: 24),

                        // Date/Time
                        _buildDateTimeCard(timestamp),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required bool isMLSession,
    required String exerciseName,
    required int repCount,
    required String workoutTitle,
    required int calories,
    required int durationMinutes,
    DateTime? timestamp,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryOrange.withOpacity(0.2),
            _primaryOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryOrange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMLSession
                  ? Icons.fitness_center_rounded
                  : Icons.emoji_events_rounded,
              size: 40,
              color: _primaryOrange,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            isMLSession ? '$repCount $exerciseName' : workoutTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            isMLSession
                ? 'AI-Tracked Session'
                : '$durationMinutes min • $calories kcal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLStats(int repCount, String exerciseName) {
    // Estimate calories: ~1 calorie per pull-up, ~0.5 per push-up
    final caloriesPerRep = exerciseName.toLowerCase().contains('pull')
        ? 1.0
        : 0.5;
    final estimatedCalories = (repCount * caloriesPerRep).round();
    final estimatedMinutes = (repCount * 3 / 60).round().clamp(1, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.repeat_rounded,
                label: 'Total Reps',
                value: '$repCount',
                color: _primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Est. Calories',
                value: '$estimatedCalories',
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: '~$estimatedMinutes min',
                color: Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Tracked By',
                value: 'AI',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineStats(int calories, int durationMinutes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: '$calories',
                color: _primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: '$durationMinutes min',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard(DateTime? timestamp) {
    final dateStr = timestamp != null
        ? '${_dayName(timestamp.weekday)}, ${timestamp.day} ${_monthName(timestamp.month)} ${timestamp.year}'
        : 'Unknown date';
    final timeStr = timestamp != null
        ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (timeStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _dayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
