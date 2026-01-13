import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'workout_setup_screen.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import 'login_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
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
      backgroundColor: darkBg,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startWorkout(context),
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text(
          'Start Workout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
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
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $_userName',
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Let's crush today's workout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Notification Bell
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle),
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
                icon: '🔥',
                label: 'Current streak',
                value: currentStreak,
                valueColor: primaryOrange,
              ),
            ),
            const SizedBox(width: 16),
            // Best Streak
            Expanded(
              child: _buildStreakCard(
                icon: '💧',
                label: 'Best streak',
                value: bestStreak,
                valueColor: const Color(0xFF007AFF),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard({
    required String icon,
    required String label,
    required int value,
    required Color valueColor,
  }) {
    return Container(
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
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'days',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.5),
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
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Workouts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Workout Cards
        _buildWorkoutCard(
          title: 'Quick Morning Cardio',
          description:
              'Start your day with energy! A quick cardio session to boost your metabolism',
          calories: 120,
          duration: '15 min',
          difficulty: 'Beginner',
          exercises: 4,
        ),
        const SizedBox(height: 12),
        _buildWorkoutCard(
          title: 'Core Crusher',
          description: 'Build a strong core with targeted exercises',
          calories: 180,
          duration: '20 min',
          difficulty: 'Intermediate',
          exercises: 6,
        ),
      ],
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

  Future<void> _startWorkout(BuildContext context) async {
    if (AuthService().currentUser == null) {
      await _showLoginRequiredDialog(context);
      return;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSetupScreen(camera: frontCamera),
          ),
        );

        // Update streak after workout
        _updateStreak();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No camera found')));
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
    }
  }

  Future<void> _showLoginRequiredDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Login Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Please login to start a workout and save your results.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Login Now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
