import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

import 'session_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Use AppTheme for consistency
  static Color get primaryOrange => AppTheme.primary;
  final Color darkBg = AppTheme.background;
  final Color cardBg = AppTheme.card;

  // Fetch user statistics from Firestore
  Future<Map<String, int>> _fetchUserStats(String userId) async {
    try {
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .get();

      int totalCalories = 0;
      int totalMinutes = 0;
      int totalSessions = workoutsSnapshot.docs.length;

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        totalCalories += (data['calories'] as int?) ?? 0;
        totalMinutes += (data['durationMinutes'] as int?) ?? 0;
      }

      return {
        'totalCalories': totalCalories,
        'totalMinutes': totalMinutes,
        'totalSessions': totalSessions,
      };
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return {'totalCalories': 0, 'totalMinutes': 0, 'totalSessions': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container(
        color: darkBg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 20),
              Text(
                'Please login to view history',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: darkBg,
      child: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Stats Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FutureBuilder<Map<String, int>>(
                future: _fetchUserStats(user.uid),
                builder: (context, statsSnapshot) {
                  final stats =
                      statsSnapshot.data ??
                      {
                        'totalCalories': 0,
                        'totalMinutes': 0,
                        'totalSessions': 0,
                      };

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardBg, cardBg.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('${stats['totalSessions']}', 'Workouts'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem('${stats['totalMinutes']}', 'Minutes'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem('${stats['totalCalories']}', 'Kcal'),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Section Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Recent Activity', // Renamed for better feel
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // List of Last Sessions
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('workouts')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryOrange),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final sessionId = doc.id;

                      // Determine session type
                      final type = data['type'] as String? ?? 'routine';
                      final isMLSession = type == 'camera' || type == 'ml';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(
                                sessionData: data,
                                sessionId: sessionId,
                              ),
                            ),
                          );
                        },
                        child: isMLSession
                            ? _buildMLSessionCard(
                                data: data,
                                isLatest: index == 0,
                              )
                            : _buildRoutineSessionCard(
                                data: data,
                                isLatest: index == 0,
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMLSessionCard({
    required Map<String, dynamic> data,
    bool isLatest = false,
  }) {
    // Explicit Naming: Use exact exercise name
    final exerciseName = data['exerciseType'] as String? ?? 'Pull-Ups';
    final repCount =
        data['pullUpCount'] as int? ?? data['pushUpCount'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    // Determine icon based on exercise type
    IconData exerciseIcon = Icons.fitness_center_rounded;
    Color exerciseColor = const Color(0xFFF97316);

    // Better detection for exercise types
    if (exerciseName.toLowerCase().contains('push')) {
      exerciseIcon = Icons.sports_gymnastics_rounded;
      exerciseColor = const Color(0xFF007AFF);
    } else if (exerciseName.toLowerCase().contains('squat')) {
      exerciseIcon = Icons.accessibility_new_rounded;
      exerciseColor = const Color(0xFF10B981); // Green for legs
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6), // Slightly lighter/translucent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLatest ? primaryOrange.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  exerciseColor.withOpacity(0.2),
                  exerciseColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(exerciseIcon, color: exerciseColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Exercise Name with Reps
                    Text(
                      '$repCount $exerciseName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Explicit "AI (ExerciseName)" Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AI (${exerciseName})', // Explicit naming
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple.shade200,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timestamp != null ? _formatDate(timestamp) : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.2),
            size: 20,
          ),
        ],
      ),
    );
  }

  // Routine session card (Push Day, Leg Day, etc.)
  Widget _buildRoutineSessionCard({
    required Map<String, dynamic> data,
    bool isLatest = false,
  }) {
    // Explicit Naming: Prefer Category if Title is 'Workout'
    String workoutName = data['workoutTitle'] as String? ?? 'Workout';
    final category = data['category'] as String?;

    // If generic name, try to use category for more accuracy
    if (workoutName == 'Workout' && category != null && category.isNotEmpty) {
      workoutName = category; // e.g. "Cardio", "Strength"
    } else if (workoutName == 'Workout') {
      workoutName = 'Routine Workout'; // Better than just "Workout"
    }

    final calories = data['calories'] as int? ?? 0;
    final durationMinutes = data['durationMinutes'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLatest ? primaryOrange.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryOrange.withOpacity(0.2),
                  primaryOrange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workoutName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$durationMinutes min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.circle,
                        size: 4,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Text(
                      '$calories kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2), // Small gap
                Text(
                  timestamp != null ? _formatDate(timestamp) : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.2),
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
