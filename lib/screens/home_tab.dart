  import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';
import 'workout_player_screen.dart';
import 'all_workouts_screen.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import 'login_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Theme colors
  final Color primaryOrange = AppTheme.primary;
  final Color darkBg = AppTheme.background;
  final Color cardBg = AppTheme.card;
  final Color textSecondary = AppTheme.textSecondary;

  // Streak service
  final StreakService _streakService = StreakService();

  // User name
  String _userName = 'there';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _updateStreak();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get display name
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() {
          _userName = user.displayName!.split(' ').first;
        });
      } else {
        // Try to get from Firestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data()?['name'] != null) {
            setState(() {
              _userName = (doc.data()!['name'] as String).split(' ').first;
            });
          }
        } catch (e) {
          debugPrint('Error loading user name: $e');
        }
      }
    }
  }

  Future<void> _updateStreak() async {
    await _streakService.calculateAndUpdateStreak();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(),

              const SizedBox(height: 24),

              // Streak Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStreakSection(),
              ),

              const SizedBox(height: 24),

              // Stats Cards Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsCards(),
              ),

              const SizedBox(height: 32),

              // Today's Workouts Section
              _buildTodaysWorkoutsSection(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: user?.photoURL != null
                  ? Image.network(
                      user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 24,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $_userName',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Let's crush it! 💪",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardBg.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.white.withOpacity(0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildLoginPromptCard();
    }

    return StreamBuilder<Map<String, int>>(
      stream: _streakService.getStreakStream(),
      builder: (context, snapshot) {
        final currentStreak = snapshot.data?['currentStreak'] ?? 0;
        final bestStreak = snapshot.data?['bestStreak'] ?? 0;

        return Row(
          children: [
            // Current Streak
            Expanded(
              child: _buildStreakCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Current streak',
                value: currentStreak,
                color: const Color(0xFFFF5C00),
                tag: 'ACTIVE',
              ),
            ),
            const SizedBox(width: 16),
            // Best Streak
            Expanded(
              child: _buildStreakCard(
                icon: Icons.bolt_rounded,
                label: 'Best streak',
                value: bestStreak,
                color: const Color(0xFF007AFF),
                tag: 'RECORD',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg.withOpacity(0.8), cardBg.withOpacity(0.4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Workouts',
              '0',
              Icons.fitness_center_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Minutes', '0', Icons.timer_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Calories',
              '0',
              Icons.local_fire_department_rounded,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<Map<String, int>>(
      future: _fetchUserStats(user.uid),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'workouts': 0, 'minutes': 0, 'calories': 0};

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Workouts',
                '${stats['workouts']}',
                Icons.fitness_center_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Minutes',
                '${stats['minutes']}',
                Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Calories',
                '${stats['calories']}',
                Icons.local_fire_department_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _fetchUserStats(String userId) async {
    try {
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .get();

      int totalWorkouts = workoutsSnapshot.docs.length;
      int totalMinutes = 0;
      int totalCalories = 0;

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final pullUps = data['pullUpCount'] as int? ?? 0;
        // Estimate: ~3 seconds per pull-up, 7 calories per pull-up
        totalMinutes += (pullUps * 3 / 60).round();
        totalCalories += pullUps * 7;
      }

      return {
        'workouts': totalWorkouts,
        'minutes': totalMinutes,
        'calories': totalCalories,
      };
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return {'workouts': 0, 'minutes': 0, 'calories': 0};
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg.withOpacity(0.8), cardBg.withOpacity(0.4)],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryOrange, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkoutsSection() {
    // Smart suggestion: rotate workouts based on day of week
    final today = DateTime.now().weekday;
    List<WorkoutRoutine> suggestedWorkouts;
    String suggestionReason;

    switch (today) {
      case DateTime.monday:
        suggestedWorkouts = [WorkoutData.pushDay, WorkoutData.absBlast];
        suggestionReason = 'Monday: Push + Abs';
        break;
      case DateTime.tuesday:
        suggestedWorkouts = [
          WorkoutData.pullDay,
          WorkoutData.quickMorningCardio,
        ];
        suggestionReason = 'Tuesday: Pull + Cardio';
        break;
      case DateTime.wednesday:
        suggestedWorkouts = [WorkoutData.legDay, WorkoutData.absBlast];
        suggestionReason = 'Wednesday: Legs + Abs';
        break;
      case DateTime.thursday:
        suggestedWorkouts = [
          WorkoutData.pushDay,
          WorkoutData.quickMorningCardio,
        ];
        suggestionReason = 'Thursday: Push + Cardio';
        break;
      case DateTime.friday:
        suggestedWorkouts = [WorkoutData.pullDay, WorkoutData.absBlast];
        suggestionReason = 'Friday: Pull + Abs';
        break;
      case DateTime.saturday:
        suggestedWorkouts = [
          WorkoutData.legDay,
          WorkoutData.quickMorningCardio,
        ];
        suggestionReason = 'Saturday: Legs + Cardio';
        break;
      default: // Sunday
        suggestedWorkouts = [
          WorkoutData.quickMorningCardio,
          WorkoutData.absBlast,
        ];
        suggestionReason = 'Sunday: Active Recovery';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Workouts",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestionReason,
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryOrange.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllWorkoutsScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: primaryOrange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Suggested Workout Cards (2-3 based on day)
        ...suggestedWorkouts
            .map(
              (workout) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWorkoutCardClickable(workout),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildWorkoutCardClickable(WorkoutRoutine workout) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutPlayerScreen(workout: workout),
          ),
        );
      },
      child: _buildWorkoutCard(
        title: workout.title,
        description: workout.description,
        calories: workout.calories,
        duration: workout.durationString,
        difficulty: workout.difficulty,
        exercises: workout.exercises.length,
      ),
    );
  }

  Widget _buildWorkoutCard({
    required String title,
    required String description,
    required int calories,
    required String duration,
    required String difficulty,
    required int exercises,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Play Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Calories
          Text(
            '$calories kcal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
          // Bottom info row
          Row(
            children: [
              _buildInfoChip(Icons.timer_outlined, duration),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.flash_on_rounded, difficulty),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.fitness_center_rounded,
                '$exercises exercise',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildLoginPromptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryOrange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open_rounded, color: primaryOrange, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Unlock Full Features',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Log in to track your streaks, save workouts, and set goals.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Login / Sign Up',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
