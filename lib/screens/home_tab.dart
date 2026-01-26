import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/workout.dart';
import 'workout_player_screen.dart';
import 'all_workouts_screen.dart';
import '../services/streak_service.dart';
import '../services/profile_service.dart';
import '../utils/responsive.dart';

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

  // Profile service for avatar/status sync
  final ProfileService _profileService = ProfileService();
  int _avatarIndex = 0;
  String _userStatus = ProfileService.statusOptions[0];
  String? _customPhotoPath;
  StreamSubscription<int>? _avatarSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<String?>? _customPhotoSub;

  // User name
  String _userName = 'there';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _updateStreak();
    _loadProfileData();
    _listenToProfileChanges();
  }

  @override
  void dispose() {
    _avatarSub?.cancel();
    _statusSub?.cancel();
    _customPhotoSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final avatarIndex = await _profileService.getAvatarIndex();
    final status = await _profileService.getStatus();
    final customPhotoPath = await _profileService.getCustomPhotoPath();
    if (mounted) {
      setState(() {
        _avatarIndex = avatarIndex;
        _userStatus = status;
        _customPhotoPath = customPhotoPath;
      });
    }
  }

  void _listenToProfileChanges() {
    _avatarSub = _profileService.avatarStream.listen((index) {
      if (mounted) setState(() => _avatarIndex = index);
    });
    _statusSub = _profileService.statusStream.listen((status) {
      if (mounted) setState(() => _userStatus = status);
    });
    _customPhotoSub = _profileService.customPhotoStream.listen((path) {
      if (mounted) setState(() => _customPhotoPath = path);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: Responsive.height(context, 0.12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Header
              _buildModernHeader(),

              SizedBox(height: Responsive.height(context, 0.03)),

              // 2. Bento Grid Dashboard
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context, 0.05),
                ),
                child: _buildBentoGrid(),
              ),

              SizedBox(height: Responsive.height(context, 0.04)),

              // 3. For You Section
              _buildForYouSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.padding(context, 0.05),
        Responsive.height(context, 0.02),
        Responsive.padding(context, 0.05),
        0,
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              // Optional: Navigate to profile or show picker
            },
            child: Container(
              width: Responsive.width(context, 0.12),
              height: Responsive.width(context, 0.12),
              decoration: BoxDecoration(
                color: cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryOrange.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _avatarIndex == -1 && _customPhotoPath != null
                    ? Image.file(
                        File(_customPhotoPath!),
                        fit: BoxFit.cover,
                        width: Responsive.width(context, 0.12),
                        height: Responsive.width(context, 0.12),
                      )
                    : Center(
                        child: Text(
                          _profileService.getAvatarEmoji(_avatarIndex),
                          style: TextStyle(
                            fontSize: Responsive.text(context, 0.05),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(width: Responsive.width(context, 0.04)),

          // Name + Status Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: Responsive.text(context, 0.055),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userStatus,
                    style: TextStyle(
                      fontSize: Responsive.text(context, 0.03),
                      fontWeight: FontWeight.w600,
                      color: primaryOrange,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Notification Bell
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('No new notifications'),
                    backgroundColor: cardBg,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: Responsive.width(context, 0.11),
                height: Responsive.width(context, 0.11),
                decoration: BoxDecoration(
                  color: cardBg.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: Responsive.icon(context, 0.055),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate height for the grid items
        final double gridHeight = Responsive.height(context, 0.28);

        return Row(
          children: [
            // Left Column: Tall Streak Card (50% width)
            Expanded(
              flex: 1,
              child: SizedBox(
                height: gridHeight,
                child: StreamBuilder<Map<String, int>>(
                  stream: _streakService.getStreakStream(),
                  builder: (context, snapshot) {
                    final currentStreak = snapshot.data?['currentStreak'] ?? 0;
                    return _buildStreakBentoCard(currentStreak);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right Column: Stacked Cards (50% width)
            Expanded(
              flex: 1,
              child: SizedBox(
                height: gridHeight,
                child: Column(
                  children: [
                    // Top: Weekly Goal (Blue)
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _fetchWeeklyWorkouts(),
                        builder: (context, snapshot) {
                          final weeklyCount = snapshot.data ?? 0;
                          return _buildWeeklyGoalCard(weeklyCount, 5);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bottom: Quick Action (Green)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Pick a random workout
                          final allWorkouts = WorkoutData.allRoutines;
                          if (allWorkouts.isNotEmpty) {
                            final random = Random();
                            final randomWorkout =
                                allWorkouts[random.nextInt(allWorkouts.length)];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WorkoutPlayerScreen(workout: randomWorkout),
                              ),
                            );
                          }
                        },
                        child: _buildInfoBentoCard(
                          title: 'Quick Start',
                          value: 'Surprise Me', // Changed from Random
                          subtitle: 'Daily Pick',
                          icon: Icons.play_arrow_rounded,
                          color: AppTheme.success,
                          isAction: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeeklyGoalCard(int current, int target) {
    // Calculate progress (0.0 to 1.0)
    final double progress = (current / target).clamp(0.0, 1.0);
    final Color color = primaryOrange; // Blue

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'WEEKLY GOAL',
                    style: TextStyle(
                      fontSize: 10, // Small caps
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$current/$target',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Workouts done',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Progress Ring
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              children: [
                // Background Ring
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withOpacity(0.15),
                    ),
                  ),
                ),
                // Progress Ring
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Icon Center
                Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: current >= target
                        ? color
                        : Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBentoCard(int streak) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.2),
                    blurRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: primaryOrange,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DAY STREAK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(
                          0.7,
                        ), // Increased contrast
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep the fire burning!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(
                          0.6,
                        ), // Increased contrast
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isAction = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAction
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          width: isAction ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, color: color.withOpacity(0.8), size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19, // Slightly smaller to fit "Surprise Me"
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(
                          0.6,
                        ), // Increased contrast
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForYouSection() {
    // Smart suggestions based on day
    final today = DateTime.now().weekday;
    List<WorkoutRoutine> suggestedWorkouts = _getSuggestedWorkouts(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "For You",
                style: TextStyle(
                  fontSize: Responsive.text(context, 0.055),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
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
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Horizontal Carousel
        SizedBox(
          height: 250, // Increased height for padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, 0.05),
            ),
            itemCount: suggestedWorkouts.length,
            itemBuilder: (context, index) {
              final workout = suggestedWorkouts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildWorkoutCarouselCard(workout),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCarouselCard(WorkoutRoutine workout) {
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
        width: Responsive.width(context, 0.72), // Slightly wider
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ), // Increased padding
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    workout.difficulty.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primaryOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Play Button - Unified Color
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryOrange, // Unified color
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              workout.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12), // Increased spacing
            Text(
              workout.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6), // Increased contrast
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: Colors.white60),
                const SizedBox(width: 4),
                Text(
                  workout.durationString,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: primaryOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${workout.calories} kcal',
                  style: TextStyle(fontSize: 12, color: primaryOrange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _fetchWeeklyWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final now = DateTime.now();
    // Calculate start of the week (Monday)
    // weekday 1 = Monday, 7 = Sunday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ); // Reset time to 00:00:00

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching weekly workouts: $e');
      return 0;
    }
  }

  List<WorkoutRoutine> _getSuggestedWorkouts(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return [
          WorkoutData.pushDay,
          WorkoutData.absBlast,
          WorkoutData.quickMorningCardio,
        ];
      case DateTime.tuesday:
        return [
          WorkoutData.pullDay,
          WorkoutData.quickMorningCardio,
          WorkoutData.legDay,
        ];
      case DateTime.wednesday:
        return [WorkoutData.legDay, WorkoutData.absBlast, WorkoutData.pushDay];
      case DateTime.thursday:
        return [
          WorkoutData.pushDay,
          WorkoutData.quickMorningCardio,
          WorkoutData.pullDay,
        ];
      case DateTime.friday:
        return [WorkoutData.pullDay, WorkoutData.absBlast, WorkoutData.legDay];
      case DateTime.saturday:
        return [
          WorkoutData.legDay,
          WorkoutData.quickMorningCardio,
          WorkoutData.pushDay,
        ];
      default: // Sunday
        return [
          WorkoutData.quickMorningCardio,
          WorkoutData.absBlast,
          WorkoutData.pullDay,
        ];
    }
  }
}
