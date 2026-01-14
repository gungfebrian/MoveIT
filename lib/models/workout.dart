// lib/models/workout.dart
// Data models for workout routines

class Exercise {
  final String name;
  final int durationSeconds;
  final String? description;
  final String? imageAsset;

  const Exercise({
    required this.name,
    required this.durationSeconds,
    this.description,
    this.imageAsset,
  });
}

class WorkoutRoutine {
  final String id;
  final String title;
  final String description;
  final int calories;
  final String difficulty;
  final List<Exercise> exercises;

  const WorkoutRoutine({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.difficulty,
    required this.exercises,
  });

  int get totalDurationMinutes {
    final totalSeconds = exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.durationSeconds,
    );
    return (totalSeconds / 60).ceil();
  }

  String get durationString => '$totalDurationMinutes min';
}

// Predefined workout routines
class WorkoutData {
  // ABS WORKOUT (renamed from Core Crusher)
  static const absBlast = WorkoutRoutine(
    id: 'abs_blast',
    title: 'Abs Blast',
    description: 'Sculpt your six-pack with intense core exercises',
    calories: 150,
    difficulty: 'Intermediate',
    exercises: [
      Exercise(
        name: 'Plank',
        durationSeconds: 45,
        description: 'Hold plank position',
      ),
      Exercise(
        name: 'Crunches',
        durationSeconds: 30,
        description: 'Basic ab crunches',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Bicycle Crunches',
        durationSeconds: 45,
        description: 'Alternate elbow to knee',
      ),
      Exercise(
        name: 'Leg Raises',
        durationSeconds: 30,
        description: 'Lift legs while lying down',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Russian Twists',
        durationSeconds: 45,
        description: 'Twist torso side to side',
      ),
      Exercise(
        name: 'Mountain Climbers',
        durationSeconds: 30,
        description: 'Fast-paced ab burner',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Dead Bug',
        durationSeconds: 30,
        description: 'Alternate arm and leg extensions',
      ),
      Exercise(
        name: 'Plank Hold',
        durationSeconds: 45,
        description: 'Final plank challenge',
      ),
    ],
  );

  // PUSH DAY - Chest, Shoulders, Triceps
  static const pushDay = WorkoutRoutine(
    id: 'push_day',
    title: 'Push Day',
    description: 'Build chest, shoulders and triceps with push movements',
    calories: 220,
    difficulty: 'Intermediate',
    exercises: [
      Exercise(
        name: 'Push-Ups',
        durationSeconds: 45,
        description: 'Classic chest builder',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Wide Push-Ups',
        durationSeconds: 40,
        description: 'Target outer chest',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Diamond Push-Ups',
        durationSeconds: 35,
        description: 'Focus on triceps',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Pike Push-Ups',
        durationSeconds: 40,
        description: 'Shoulder focused',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Decline Push-Ups',
        durationSeconds: 40,
        description: 'Upper chest emphasis',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Tricep Dips',
        durationSeconds: 45,
        description: 'Use chair or bench',
      ),
      Exercise(
        name: 'Burnout Push-Ups',
        durationSeconds: 30,
        description: 'Final push to failure',
      ),
    ],
  );

  // PULL DAY - Back, Biceps
  static const pullDay = WorkoutRoutine(
    id: 'pull_day',
    title: 'Pull Day',
    description: 'Strengthen your back and biceps with pull exercises',
    calories: 200,
    difficulty: 'Intermediate',
    exercises: [
      Exercise(
        name: 'Pull-Ups',
        durationSeconds: 45,
        description: 'King of back exercises',
      ),
      Exercise(name: 'Rest', durationSeconds: 25),
      Exercise(
        name: 'Chin-Ups',
        durationSeconds: 40,
        description: 'Bicep focused pull',
      ),
      Exercise(name: 'Rest', durationSeconds: 25),
      Exercise(
        name: 'Inverted Rows',
        durationSeconds: 45,
        description: 'Use table or bar',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Superman Hold',
        durationSeconds: 30,
        description: 'Lower back strength',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Negative Pull-Ups',
        durationSeconds: 45,
        description: 'Slow descent',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Doorway Rows',
        durationSeconds: 40,
        description: 'Use door frame',
      ),
      Exercise(
        name: 'Back Extensions',
        durationSeconds: 30,
        description: 'Strengthen lower back',
      ),
    ],
  );

  // LEG DAY - Quads, Hamstrings, Glutes, Calves
  static const legDay = WorkoutRoutine(
    id: 'leg_day',
    title: 'Leg Day',
    description: 'Build powerful legs with squats, lunges, and more',
    calories: 250,
    difficulty: 'Intermediate',
    exercises: [
      Exercise(
        name: 'Squats',
        durationSeconds: 45,
        description: 'Deep controlled squats',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Lunges',
        durationSeconds: 40,
        description: 'Alternate legs',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Jump Squats',
        durationSeconds: 30,
        description: 'Explosive power',
      ),
      Exercise(name: 'Rest', durationSeconds: 25),
      Exercise(
        name: 'Wall Sit',
        durationSeconds: 45,
        description: 'Hold position against wall',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Calf Raises',
        durationSeconds: 40,
        description: 'Slow and controlled',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Sumo Squats',
        durationSeconds: 40,
        description: 'Wide stance, inner thighs',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Glute Bridges',
        durationSeconds: 45,
        description: 'Squeeze at the top',
      ),
      Exercise(
        name: 'Bulgarian Split Squats',
        durationSeconds: 40,
        description: 'Single leg focus',
      ),
    ],
  );

  // CARDIO - Quick Morning Routine
  static const quickMorningCardio = WorkoutRoutine(
    id: 'quick_morning_cardio',
    title: 'Quick Morning Cardio',
    description: 'Start your day with energy! A quick cardio boost',
    calories: 120,
    difficulty: 'Beginner',
    exercises: [
      Exercise(
        name: 'Jumping Jacks',
        durationSeconds: 45,
        description: 'Jump with arms and legs spread',
      ),
      Exercise(
        name: 'High Knees',
        durationSeconds: 30,
        description: 'Run in place, knees high',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Burpees',
        durationSeconds: 45,
        description: 'Full body explosive movement',
      ),
      Exercise(
        name: 'Mountain Climbers',
        durationSeconds: 30,
        description: 'Plank position, alternate knees',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(name: 'Jumping Jacks', durationSeconds: 45),
      Exercise(
        name: 'Cool Down',
        durationSeconds: 30,
        description: 'Light stretching',
      ),
    ],
  );

  // FULL BODY HIIT - High Intensity
  static const fullBodyHiit = WorkoutRoutine(
    id: 'full_body_hiit',
    title: 'Full Body HIIT',
    description: 'Burn calories fast with high-intensity interval training',
    calories: 300,
    difficulty: 'Advanced',
    exercises: [
      Exercise(
        name: 'Burpees',
        durationSeconds: 40,
        description: 'Explosive full body',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Jump Squats',
        durationSeconds: 40,
        description: 'Explosive legs',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(name: 'Push-Ups', durationSeconds: 40, description: 'Fast pace'),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Mountain Climbers',
        durationSeconds: 40,
        description: 'Core and cardio',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'High Knees',
        durationSeconds: 40,
        description: 'Sprint in place',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Plank Jacks',
        durationSeconds: 40,
        description: 'Plank with jumping legs',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Tuck Jumps',
        durationSeconds: 30,
        description: 'Jump and tuck knees',
      ),
      Exercise(
        name: 'Cool Down',
        durationSeconds: 60,
        description: 'Deep breathing',
      ),
    ],
  );

  // UPPER BODY STRENGTH
  static const upperBodyStrength = WorkoutRoutine(
    id: 'upper_body_strength',
    title: 'Upper Body Strength',
    description: 'Build a powerful upper body with compound movements',
    calories: 180,
    difficulty: 'Intermediate',
    exercises: [
      Exercise(name: 'Push-Ups', durationSeconds: 45, description: 'Wide grip'),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Diamond Push-Ups',
        durationSeconds: 35,
        description: 'Tricep focus',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Pike Push-Ups',
        durationSeconds: 40,
        description: 'Shoulders',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Dips',
        durationSeconds: 40,
        description: 'Use sturdy surface',
      ),
      Exercise(name: 'Rest', durationSeconds: 20),
      Exercise(
        name: 'Arm Circles',
        durationSeconds: 30,
        description: 'Shoulder endurance',
      ),
      Exercise(name: 'Rest', durationSeconds: 15),
      Exercise(
        name: 'Plank to Push-Up',
        durationSeconds: 40,
        description: 'Core and arms',
      ),
      Exercise(
        name: 'Stretch',
        durationSeconds: 45,
        description: 'Arm and shoulder stretch',
      ),
    ],
  );

  // FLEXIBILITY & STRETCH
  static const flexibilityStretch = WorkoutRoutine(
    id: 'flexibility_stretch',
    title: 'Flexibility & Stretch',
    description: 'Improve mobility and relax your muscles',
    calories: 80,
    difficulty: 'Beginner',
    exercises: [
      Exercise(
        name: 'Neck Rolls',
        durationSeconds: 30,
        description: 'Slow circles',
      ),
      Exercise(
        name: 'Shoulder Stretch',
        durationSeconds: 30,
        description: 'Cross arm stretch',
      ),
      Exercise(
        name: 'Cat-Cow',
        durationSeconds: 45,
        description: 'Spine mobility',
      ),
      Exercise(
        name: 'Child\'s Pose',
        durationSeconds: 45,
        description: 'Full body relax',
      ),
      Exercise(
        name: 'Downward Dog',
        durationSeconds: 45,
        description: 'Hamstrings and calves',
      ),
      Exercise(
        name: 'Pigeon Pose',
        durationSeconds: 45,
        description: 'Hip opener',
      ),
      Exercise(
        name: 'Seated Forward Fold',
        durationSeconds: 45,
        description: 'Hamstring stretch',
      ),
      Exercise(
        name: 'Lying Spinal Twist',
        durationSeconds: 45,
        description: 'Spine release',
      ),
      Exercise(
        name: 'Butterfly Stretch',
        durationSeconds: 45,
        description: 'Inner thighs',
      ),
      Exercise(
        name: 'Deep Breathing',
        durationSeconds: 60,
        description: 'Calm and center',
      ),
    ],
  );

  // All routines in display order
  static List<WorkoutRoutine> get allRoutines => [
    absBlast,
    pushDay,
    pullDay,
    legDay,
    fullBodyHiit,
    upperBodyStrength,
    flexibilityStretch,
    quickMorningCardio,
  ];
}
