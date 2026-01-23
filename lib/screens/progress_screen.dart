// lib/screens/progress_screen.dart
// Progress tracking screen with stats, streaks, and weekly journey chart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/streak_service.dart';
import '../utils/responsive.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Premium Dark Theme (Consistent with rest of app)
  final Color primaryOrange = const Color(0xFFFF5C00);
  final Color pDarkBg = const Color(0xFF08080C);
  final Color pCardBg = const Color(0xFF12121A);

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
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),

              SizedBox(height: Responsive.height(context, 0.015)),

              // Title
              Text(
                'Track your\nfitness progress',
                style: TextStyle(
                  fontSize: Responsive.text(context, 0.08),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),

              SizedBox(height: Responsive.height(context, 0.04)),

              // Stats Cards
              if (user != null) _buildStatsCards(context, user.uid),

              SizedBox(height: Responsive.height(context, 0.04)),

              // Streak Section
              if (user != null) _buildStreakSection(context),

              SizedBox(height: Responsive.height(context, 0.05)),

              // Your Journey Section
              if (user != null) _buildJourneySection(context, user.uid),

              // Login prompt for non-logged in users
              if (user == null) _buildLoginPrompt(context),

              SizedBox(height: Responsive.height(context, 0.12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.height(context, 0.02)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildCircleButton(
            context: context,
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context),
          ),

          Text(
            'Progress',
            style: TextStyle(
              fontSize: Responsive.text(context, 0.04),
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),

          // Notification icon
          _buildCircleButton(
            context: context,
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            size: Responsive.icon(context, 0.06),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
    double? size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Responsive.width(context, 0.11),
        height: Responsive.width(context, 0.11),
        decoration: BoxDecoration(color: pCardBg, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: Colors.white,
          size: size ?? Responsive.icon(context, 0.07),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(userId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'workouts': 0, 'minutes': 0, 'calories': 0};

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Workouts',
                '${stats['workouts']}',
              ),
            ),
            SizedBox(width: Responsive.width(context, 0.035)),
            Expanded(
              child: _buildStatCard(context, 'Minutes', '${stats['minutes']}'),
            ),
            SizedBox(width: Responsive.width(context, 0.035)),
            Expanded(
              child: _buildStatCard(
                context,
                'Calories',
                '${stats['calories']}',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.height(context, 0.025),
        horizontal: Responsive.width(context, 0.03),
      ),
      decoration: BoxDecoration(
        color: pCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, 0.032),
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          SizedBox(height: Responsive.height(context, 0.01)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.text(context, 0.055),
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: _streakService.getStreakStream(),
      builder: (context, snapshot) {
        final currentStreak = snapshot.data?['currentStreak'] ?? 0;
        final bestStreak = snapshot.data?['bestStreak'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStreakItem(
                context: context,
                label: 'Current streak',
                value: currentStreak,
                iconColor: primaryOrange,
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            SizedBox(width: Responsive.width(context, 0.05)),
            Expanded(
              child: _buildStreakItem(
                context: context,
                label: 'Best streak',
                value: bestStreak,
                iconColor: const Color(0xFF007AFF),
                icon: Icons.water_drop_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakItem({
    required BuildContext context,
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
            Icon(icon, color: iconColor, size: Responsive.icon(context, 0.05)),
            SizedBox(width: Responsive.width(context, 0.02)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.text(context, 0.035),
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(context, 0.01)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$value ',
              style: TextStyle(
                fontSize: Responsive.text(context, 0.08),
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              'days',
              style: TextStyle(
                fontSize: Responsive.text(context, 0.038),
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

  Widget _buildJourneySection(BuildContext context, String userId) {
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
            GestureDetector(
              onTap: () {
                _showPeriodPicker();
              },
              child: Container(
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
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bar Chart
        FutureBuilder<Map<String, dynamic>>(
          future: _fetchChartData(userId),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            final counts =
                data['counts'] as List<int>? ?? [0, 0, 0, 0, 0, 0, 0];
            final labels =
                data['labels'] as List<String>? ??
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            final maxValue = counts.fold(0, (max, v) => v > max ? v : max);
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
                          final value = counts[index];
                          final label = labels.length > index
                              ? labels[index]
                              : '';
                          final heightPercent = (value / chartMax).clamp(
                            0.0,
                            1.0,
                          );

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$value workouts on $label'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: pCardBg,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: _buildBar(
                                label: label,
                                percent: heightPercent,
                                isActive: value > 0,
                              ),
                            ),
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
      // Determine date range based on selected period
      DateTime? startDate;
      if (_selectedPeriod == 'Weekly') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }
      // 'All Time' = no filter

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts');

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(startDate),
        );
      }

      final workoutsSnapshot = await query.get();

      int totalWorkouts = workoutsSnapshot.docs.length;
      int totalMinutes = 0;
      int totalCalories = 0;

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        // Use actual workout data
        totalMinutes += (data['durationMinutes'] as int?) ?? 0;
        totalCalories += (data['calories'] as int?) ?? 0;
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

  Future<Map<String, dynamic>> _fetchChartData(String userId) async {
    try {
      final now = DateTime.now();

      // Determine date range and labels based on period
      DateTime startDate;
      int periods;
      bool isWeekly = _selectedPeriod == 'Weekly';

      if (isWeekly) {
        // Last 7 days
        periods = 7;
        startDate = now.subtract(
          const Duration(days: 6),
        ); // Start from 6 days ago + today
      } else {
        // Monthly (Last 7 weeks as per inspiration)
        periods = 7;
        startDate = now.subtract(
          const Duration(days: 7 * 6),
        ); // Start from 6 weeks ago + this week
      }

      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              startDate.subtract(const Duration(days: 1)),
            ),
          ) // Buffer
          .get();

      final counts = List.filled(periods, 0);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();

          if (isWeekly) {
            // Calculate day usage
            final diff = date.difference(startDate).inDays;
            if (diff >= 0 && diff < 7) {
              counts[diff]++;
            }
          } else {
            // Calculate week usage
            final diff = now.difference(date).inDays;
            final weekIndex = (diff / 7).floor();
            if (weekIndex >= 0 && weekIndex < 7) {
              counts[6 - weekIndex]++; // Reverse order so w7 is current
            }
          }
        }
      }

      List<String> labels = [];
      if (isWeekly) {
        // Generate day labels (e.g. Mon, Tue)
        for (int i = 0; i < 7; i++) {
          final date = startDate.add(Duration(days: i));
          labels.add(weekdays[date.weekday - 1]);
        }
      } else {
        // Generate week labels (w1...w7)
        for (int i = 1; i <= 7; i++) {
          labels.add('w$i');
        }
      }

      return {'counts': counts, 'labels': labels};
    } catch (e) {
      return {
        'counts': [0, 0, 0, 0, 0, 0, 0],
        'labels': _selectedPeriod == 'Weekly'
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['w1', 'w2', 'w3', 'w4', 'w5', 'w6', 'w7'],
      };
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

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: pCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Period',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPeriodOption('Weekly', Icons.calendar_view_week_rounded),
                _buildPeriodOption('Monthly', Icons.calendar_month_rounded),
                _buildPeriodOption('All Time', Icons.all_inclusive_rounded),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return ListTile(
      onTap: () {
        setState(() => _selectedPeriod = period);
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color: isSelected ? primaryOrange : Colors.white.withOpacity(0.5),
      ),
      title: Text(
        period,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primaryOrange : Colors.white,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: primaryOrange)
          : null,
    );
  }
}
