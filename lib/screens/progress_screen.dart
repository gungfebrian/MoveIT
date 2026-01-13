// lib/screens/progress_screen.dart
// Progress tracking screen with stats, streaks, and weekly journey chart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/streak_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Exact colors from reference
  final Color primaryOrange = const Color(0xFFFF6B4A);
  final Color pDarkBg = const Color(0xFF000000); // True black background
  final Color pCardBg = const Color(0xFF1C1C1E); // Dark gray cards

  final StreakService _streakService = StreakService();
  String _selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: pDarkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 12),

              // Title
              const Text(
                'Track your\nfitness progress',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),

              const SizedBox(height: 32),

              // Stats Cards
              if (user != null) _buildStatsCards(user.uid),

              const SizedBox(height: 32),

              // Streak Section
              if (user != null) _buildStreakSection(),

              const SizedBox(height: 40),

              // Your Journey Section
              if (user != null) _buildJourneySection(user.uid),

              // Login prompt for non-logged in users
              if (user == null) _buildLoginPrompt(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context),
          ),

          const Text(
            'Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),

          // Notification icon
          _buildCircleButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: pCardBg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildStatsCards(String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(userId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'workouts': 0, 'minutes': 0, 'calories': 0};

        return Row(
          children: [
            Expanded(child: _buildStatCard('Workouts', '${stats['workouts']}')),
            const SizedBox(width: 14),
            Expanded(child: _buildStatCard('Minutes', '${stats['minutes']}')),
            const SizedBox(width: 14),
            Expanded(child: _buildStatCard('Calories', '${stats['calories']}')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: pCardBg,
        borderRadius: BorderRadius.circular(20),
        // No border as per reference
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return StreamBuilder<Map<String, int>>(
      stream: _streakService.getStreakStream(),
      builder: (context, snapshot) {
        final currentStreak = snapshot.data?['currentStreak'] ?? 0;
        final bestStreak = snapshot.data?['bestStreak'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStreakItem(
                label: 'Current streak',
                value: currentStreak,
                iconColor: primaryOrange,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStreakItem(
                label: 'Best streak',
                value: bestStreak,
                iconColor: const Color(0xFF007AFF), // Apple Blue
                icon: Icons.water_drop_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakItem({
    required String label,
    required int value,
    required Color iconColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$value ',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              'days',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneySection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
            // Period dropdown
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
              decoration: BoxDecoration(
                color: pCardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bar Chart
        FutureBuilder<List<int>>(
          future: _fetchWeeklyData(userId),
          builder: (context, snapshot) {
            final weeklyData = snapshot.data ?? [0, 0, 0, 0, 0, 0, 0];
            final maxValue = weeklyData.fold(0, (max, v) => v > max ? v : max);
            final chartMax = maxValue > 0 ? maxValue : 12;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: pCardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(
                height: 220,
                child: Row(
                  children: [
                    // Y-Axis Labels
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildYLabel('${chartMax} wo'),
                        _buildYLabel('${(chartMax * 0.75).round()} wo'),
                        _buildYLabel('${(chartMax * 0.5).round()} wo'),
                        _buildYLabel('${(chartMax * 0.25).round()} wo'),
                        _buildYLabel('1 wo'),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Bars
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final value = weeklyData[index];
                          final heightPercent = (value / chartMax).clamp(
                            0.0,
                            1.0,
                          );

                          return _buildBar(
                            label: 'w${index + 1}',
                            percent: heightPercent,
                            isActive: value > 0,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withOpacity(0.3),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double percent,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background Track
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Active Bar
              FractionallySizedBox(
                heightFactor: percent > 0.05
                    ? percent
                    : 0.05, // Minimum visual height
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    color: isActive
                        ? primaryOrange
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<Map<String, int>> _fetchStats(String userId) async {
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
        totalMinutes += (pullUps * 3 / 60).round();
        totalCalories += pullUps * 7;
      }

      return {
        'workouts': totalWorkouts,
        'minutes': totalMinutes > 0 ? totalMinutes : totalWorkouts * 15,
        'calories': totalCalories > 0 ? totalCalories : totalWorkouts * 120,
      };
    } catch (e) {
      return {'workouts': 0, 'minutes': 0, 'calories': 0};
    }
  }

  Future<List<int>> _fetchWeeklyData(String userId) async {
    try {
      final now = DateTime.now();
      final sevenWeeksAgo = now.subtract(const Duration(days: 49));

      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenWeeksAgo))
          .get();

      final weekCounts = List.filled(7, 0);

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final weeksAgo = now.difference(date).inDays ~/ 7;
          if (weeksAgo >= 0 && weeksAgo < 7) {
            weekCounts[6 - weeksAgo]++;
          }
        }
      }

      return weekCounts;
    } catch (e) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pCardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Login to track your progress',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
