// lib/services/streak_service.dart
// Service for calculating and managing workout streaks

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's UID
  String? get _userId => _auth.currentUser?.uid;

  // Reference to the streak document
  DocumentReference? get _streakDoc {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('streak');
  }

  // Reference to the workouts collection
  CollectionReference? get _workoutsCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('workouts');
  }

  /// Get streak data as a stream for real-time updates
  Stream<Map<String, int>> getStreakStream() {
    if (_streakDoc == null) {
      return Stream.value({'currentStreak': 0, 'bestStreak': 0});
    }

    return _streakDoc!.snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'currentStreak': data['currentStreak'] as int? ?? 0,
          'bestStreak': data['bestStreak'] as int? ?? 0,
        };
      }
      return {'currentStreak': 0, 'bestStreak': 0};
    });
  }

  /// Calculate and update workout streak based on workout history
  Future<Map<String, int>> calculateAndUpdateStreak() async {
    if (_workoutsCollection == null || _streakDoc == null) {
      return {'currentStreak': 0, 'bestStreak': 0};
    }

    try {
      // Get all workouts sorted by date
      final workoutsSnapshot = await _workoutsCollection!
          .orderBy('timestamp', descending: true)
          .get();

      if (workoutsSnapshot.docs.isEmpty) {
        await _streakDoc!.set({
          'currentStreak': 0,
          'bestStreak': 0,
          'lastWorkoutDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return {'currentStreak': 0, 'bestStreak': 0};
      }

      // Get unique workout dates (normalized to date only, no time)
      final workoutDates = <DateTime>{};
      for (var doc in workoutsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          workoutDates.add(DateTime(date.year, date.month, date.day));
        }
      }

      // Sort dates in descending order
      final sortedDates = workoutDates.toList()..sort((a, b) => b.compareTo(a));

      // Calculate current streak
      int currentStreak = 0;
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);

      // Check if worked out today or yesterday to count the streak
      if (sortedDates.isNotEmpty) {
        final mostRecentWorkout = sortedDates.first;
        final daysSinceLastWorkout = todayNormalized
            .difference(mostRecentWorkout)
            .inDays;

        // If last workout was more than 1 day ago, streak is broken
        if (daysSinceLastWorkout > 1) {
          currentStreak = 0;
        } else {
          // Count consecutive days
          currentStreak = 1;
          for (int i = 1; i < sortedDates.length; i++) {
            final prevDate = sortedDates[i - 1];
            final currDate = sortedDates[i];
            final diff = prevDate.difference(currDate).inDays;

            if (diff == 1) {
              currentStreak++;
            } else {
              break;
            }
          }
        }
      }

      // Calculate best streak (longest consecutive days ever)
      int bestStreak = 0;
      if (sortedDates.isNotEmpty) {
        int tempStreak = 1;
        bestStreak = 1;

        // Sort ascending for best streak calculation
        final ascDates = sortedDates.reversed.toList();

        for (int i = 1; i < ascDates.length; i++) {
          final prevDate = ascDates[i - 1];
          final currDate = ascDates[i];
          final diff = currDate.difference(prevDate).inDays;

          if (diff == 1) {
            tempStreak++;
            if (tempStreak > bestStreak) {
              bestStreak = tempStreak;
            }
          } else {
            tempStreak = 1;
          }
        }
      }

      // Ensure best streak is at least as high as current streak
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }

      // Get previous best streak to compare
      final existingDoc = await _streakDoc!.get();
      if (existingDoc.exists) {
        final data = existingDoc.data() as Map<String, dynamic>?;
        final previousBest = data?['bestStreak'] as int? ?? 0;
        if (previousBest > bestStreak) {
          bestStreak = previousBest;
        }
      }

      // Update Firestore
      await _streakDoc!.set({
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastWorkoutDate': sortedDates.isNotEmpty
            ? Timestamp.fromDate(sortedDates.first)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'currentStreak': currentStreak, 'bestStreak': bestStreak};
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return {'currentStreak': 0, 'bestStreak': 0};
    }
  }

  /// Get current streak value (one-time fetch)
  Future<int> getCurrentStreak() async {
    final streaks = await calculateAndUpdateStreak();
    return streaks['currentStreak'] ?? 0;
  }

  /// Get best streak value (one-time fetch)
  Future<int> getBestStreak() async {
    final streaks = await calculateAndUpdateStreak();
    return streaks['bestStreak'] ?? 0;
  }
}
