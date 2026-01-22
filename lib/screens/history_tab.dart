import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'session_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  final Color primaryBlue = AppTheme.primary;
  final Color darkBg = AppTheme.background;
  final Color cardBg = AppTheme.card;

  const HistoryTab({super.key});

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
      print('Error fetching user stats: $e');
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
            // Statistics Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<Map<String, int>>(
                future: _fetchUserStats(user.uid),
                builder: (context, statsSnapshot) {
                  if (statsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      ),
                    );
                  }

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
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              '${stats['totalSessions']}',
                              'Total\nWorkouts',
                              Icons.fitness_center_rounded,
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            _buildStatColumn(
                              '${stats['totalCalories']}',
                              'Total\nCalories',
                              Icons.local_fire_department_rounded,
                            ),
                            Container(
                              height: 50,
                              width: 1,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            _buildStatColumn(
                              '${stats['totalMinutes']}',
                              'Total\nMinutes',
                              Icons.timer_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Section Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  const Text(
                    'Recent Sessions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Simple List of Last Sessions
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
                      child: CircularProgressIndicator(color: primaryBlue),
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
                            Icons.fitness_center_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No workouts yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your first workout!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: snapshot.data!.docs.length,
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

  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLSessionCard({
    required Map<String, dynamic> data,
    bool isLatest = false,
  }) {
    final exerciseName = data['exerciseType'] as String? ?? 'Pull-Ups';
    final repCount =
        data['pullUpCount'] as int? ?? data['pushUpCount'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    // Determine icon based on exercise type
    IconData exerciseIcon = Icons.fitness_center_rounded;
    Color exerciseColor = const Color(0xFFFF5C00);
    if (exerciseName.toLowerCase().contains('push')) {
      exerciseIcon = Icons.sports_gymnastics_rounded;
      exerciseColor = const Color(0xFF007AFF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: primaryBlue.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: exerciseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
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
                    Text(
                      '$repCount $exerciseName',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp != null ? _formatDate(timestamp) : 'Unknown date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 24,
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
    final workoutName = data['workoutTitle'] as String? ?? 'Workout';
    final calories = data['calories'] as int? ?? 0;
    final durationMinutes = data['durationMinutes'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isLatest
            ? Border.all(color: primaryBlue.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: primaryBlue,
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
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$durationMinutes min',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$calories kcal',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp != null ? _formatDate(timestamp) : 'Unknown date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 24,
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
