// lib/screens/all_workouts_screen.dart
// Shows all available workout routines with a premium design

import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'workout_player_screen.dart';

class AllWorkoutsScreen extends StatefulWidget {
  const AllWorkoutsScreen({super.key});

  @override
  State<AllWorkoutsScreen> createState() => _AllWorkoutsScreenState();
}

class _AllWorkoutsScreenState extends State<AllWorkoutsScreen> {
  // Premium Colors
  static const Color _bgColor = Color(0xFF08080C);
  static const Color _cardBg = Color(0xFF16161F);
  static const Color _primaryOrange = Color(0xFFF97316);

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Strength',
    'HIIT',
    'Cardio',
    'Flexibility',
  ];

  @override
  Widget build(BuildContext context) {
    // Filter workouts
    final allWorkouts = WorkoutData.allRoutines;
    final filteredWorkouts = _selectedCategory == 'All'
        ? allWorkouts
        : allWorkouts.where((w) {
            // Simple keyword matching for demo categories
            final id = w.id.toLowerCase();
            final title = w.title.toLowerCase();
            if (_selectedCategory == 'Strength') {
              return id.contains('push') ||
                  id.contains('pull') ||
                  id.contains('leg') ||
                  title.contains('Strength');
            } else if (_selectedCategory == 'HIIT') {
              return id.contains('hiit') || id.contains('abs');
            } else if (_selectedCategory == 'Cardio') {
              return id.contains('cardio') || title.contains('Cardio');
            } else if (_selectedCategory == 'Flexibility') {
              return id.contains('stretch') || title.contains('Flexibility');
            }
            return true;
          }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Immersive Header
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: _bgColor,
            scrolledUnderElevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cardBg.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              expandedTitleScale: 1.5,
              title: const Text(
                'Explore\nWorkouts',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.left,
              ),
              background: Stack(
                children: [
                  // Ambient Glow
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryOrange.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryOrange.withOpacity(0.2),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories List
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryOrange : _cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _primaryOrange
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(top: 10)),

          // Results Count
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${filteredWorkouts.length} Workouts Found',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Workout Grid/List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final workout = filteredWorkouts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRichWorkoutCard(context, workout),
                );
              }, childCount: filteredWorkouts.length),
            ),
          ),

          // Bottom Spacing
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  // A Richer, Premium Card Design
  Widget _buildRichWorkoutCard(BuildContext context, WorkoutRoutine workout) {
    // UNIFIED THEME: Use Primary Orange for everything to match app
    // User requested removal of gradient and matching app theme.

    const themeColor = _primaryOrange;
    IconData icon;

    final idLower = workout.id.toLowerCase();

    if (idLower.contains('hiit') ||
        idLower.contains('abs') ||
        idLower.contains('burn')) {
      icon = Icons.local_fire_department_rounded;
    } else if (idLower.contains('flex') ||
        idLower.contains('stretch') ||
        idLower.contains('yoga')) {
      icon = Icons.self_improvement_rounded;
    } else if (idLower.contains('cardio')) {
      icon = Icons.directions_run_rounded;
    } else {
      icon = Icons.fitness_center_rounded;
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
        height: 140,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1), // Subtle Single Color
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: themeColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: themeColor, size: 30),
              ),

              const SizedBox(width: 20),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      workout.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workout.description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Metadata Row
                    Row(
                      children: [
                        _buildMiniTag(
                          Icons.timer_outlined,
                          workout.durationString,
                        ),
                        const SizedBox(width: 12),
                        _buildMiniTag(Icons.bolt_rounded, workout.difficulty),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
