// lib/screens/all_workouts_screen.dart
// Shows all available workout routines

import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'workout_player_screen.dart';

class AllWorkoutsScreen extends StatelessWidget {
  const AllWorkoutsScreen({super.key});

  // Premium Dark Theme
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _cardBg = Color(0xFF12121A);
  static const Color _primaryOrange = Color(0xFFFF5C00);

  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        'All Workouts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose a workout to start',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Workout List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: WorkoutData.allRoutines.length,
                    itemBuilder: (context, index) {
                      final workout = WorkoutData.allRoutines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildWorkoutCard(context, workout),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutRoutine workout) {
    // Icon based on workout type
    IconData workoutIcon;
    Color iconColor;

    if (workout.id.contains('push')) {
      workoutIcon = Icons.fitness_center_rounded;
      iconColor = const Color(0xFFFF5C00);
    } else if (workout.id.contains('pull')) {
      workoutIcon = Icons.accessibility_new_rounded;
      iconColor = const Color(0xFF007AFF);
    } else if (workout.id.contains('leg')) {
      workoutIcon = Icons.directions_run_rounded;
      iconColor = const Color(0xFF34C759);
    } else if (workout.id.contains('abs')) {
      workoutIcon = Icons.sports_gymnastics_rounded;
      iconColor = const Color(0xFFFF9500);
    } else {
      workoutIcon = Icons.bolt_rounded;
      iconColor = const Color(0xFFAF52DE);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutPlayerScreen(workout: workout),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(workoutIcon, color: iconColor, size: 28),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(Icons.timer_outlined, workout.durationString),
                      const SizedBox(width: 12),
                      _buildChip(Icons.flash_on_rounded, workout.difficulty),
                      const SizedBox(width: 12),
                      _buildChip(
                        Icons.local_fire_department_rounded,
                        '${workout.calories} kcal',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
