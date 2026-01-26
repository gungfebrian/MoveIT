import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class WorkoutSetupScreen extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;

  const WorkoutSetupScreen({
    super.key,
    required this.camera,
    required this.cameras,
  });

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  // Premium Colors
  final Color primaryOrange = const Color(0xFFF97316);
  final Color pDarkBg = const Color(0xFF08080C);
  final Color pCardBg = const Color(0xFF12121A);

  // State
  int _selectedTabIndex = 0; // 0: Free Session, 1: Guided Focus
  String _selectedExercise = 'Pull-Up';
  String _goalType = 'reps'; // 'reps' or 'time'
  int _targetReps = 10;

  final List<String> _exercises = ['Pull-Up', 'Push-Up', 'Sit-Up'];
  final List<int> _repsOptions = [8, 10, 12, 15, 20];

  void _startWorkout() {
    // Use unified CameraScreen for all exercise types
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: widget.camera,
          cameras: widget.cameras,
          exerciseType: _selectedExercise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTabs(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: _selectedTabIndex == 0
                    ? _buildFreeSessionView()
                    : _buildGuidedFocusView(),
              ),
            ),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: pCardBg, shape: BoxShape.circle),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Workout Setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('Free Session', 0)),
          Expanded(child: _buildTabItem('Guided Focus', 1)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSessionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Exercise',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              return _buildExerciseCard(_exercises[index]);
            },
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Set Goal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: pCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildGoalTypeBtn('Target Reps', 'reps')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGoalTypeBtn('Open Goal', 'time')),
                ],
              ),
              const SizedBox(height: 24),
              if (_goalType == 'reps') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _repsOptions.map((reps) {
                    final isSelected = _targetReps == reps;
                    return GestureDetector(
                      onTap: () => setState(() => _targetReps = reps),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryOrange
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                        ),
                        child: Center(
                          child: Text(
                            '$reps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else
                Center(
                  child: Text(
                    'Just workout freely!',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidedFocusView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ondemand_video_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Guided Workouts Coming Soon',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(String exercise) {
    final isSelected = _selectedExercise == exercise;
    IconData icon;
    if (exercise == 'Pull-Up')
      icon = Icons.fitness_center;
    else if (exercise == 'Push-Up')
      icon = Icons.accessibility_new;
    else
      icon = Icons.self_improvement; // Sit-Up icon (person sitting)

    return GestureDetector(
      onTap: () => setState(() => _selectedExercise = exercise),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : pCardBg,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              exercise,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeBtn(String label, String value) {
    final isSelected = _goalType == value;
    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryOrange : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Start Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
