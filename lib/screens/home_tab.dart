import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_setup_screen.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  // Warna dipertahankan untuk konsistensi dengan skema gelap.
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color darkBg = const Color(0xFF0A0E1A);
  final Color cardBg = const Color(0xFF1A1F2E);
  final Color secondaryTextColor = Colors.white.withOpacity(0.7);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- Fungsi Backend dan Dialog Dipertahankan ---

  Future<void> _showInstructionsDialog(BuildContext context) async {
    if (AuthService().currentUser == null) {
      await _showLoginRequiredDialog(
        context,
        'To start a workout session and save your results',
      );
      return;
    }

    // Tampilan Dialog Instruksi dipertahankan karena sudah baik dan fungsional
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: cardBg,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera Setup',
                  style: TextStyle(
                    fontSize: 22, // Sedikit lebih besar
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow these tips for best results',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSimpleInstruction(
                  Icons.phone_iphone,
                  'Place your phone **2–3 meters** from your workout area',
                ),
                const SizedBox(height: 16),
                _buildSimpleInstruction(
                  Icons.accessibility_new,
                  'Ensure your **full body** is visible on camera',
                ),
                const SizedBox(height: 16),
                _buildSimpleInstruction(
                  Icons.wb_sunny_outlined,
                  'Use an area with **good lighting**',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600, // Sedikit lebih bold
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _proceedToCamera(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Workout', // Ubah teks untuk lebih jelas
                          style: TextStyle(
                            fontSize: 16, // Sedikit lebih besar
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper untuk Instruksi, tambahkan parsing Markdown sederhana untuk bold
  Widget _buildSimpleInstruction(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.15), // Opacity ditingkatkan
            borderRadius: BorderRadius.circular(
              10,
            ), // Radius sedikit lebih besar
          ),
          child: Icon(
            icon,
            size: 22,
            color: primaryBlue,
          ), // Ikon sedikit lebih besar
        ),
        const SizedBox(width: 16), // Jarak lebih lebar
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              _processInstructionText(text),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9), // Kontras ditingkatkan
                fontSize: 15, // Ukuran sedikit lebih besar
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Fungsi untuk memproses teks dengan bold (**text**)
  TextSpan _processInstructionText(String text) {
    final parts = text.split('**');
    final children = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        children.add(
          TextSpan(
            text: parts[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        children.add(TextSpan(text: parts[i]));
      }
    }
    return TextSpan(children: children);
  }

  // --- Fungsi yang terhubung ke Backend (dipertahankan) ---

  Future<void> _proceedToCamera(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        // Navigate to workout setup screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSetupScreen(camera: frontCamera),
          ),
        );
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
          const SnackBar(
            content: Text('Camera permission is required to start'),
          ),
        );
      }
    }
  }

  Future<void> _saveWorkoutToFirestore(int pullUpCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .add({
            'pullUpCount': pullUpCount,
            'timestamp': FieldValue.serverTimestamp(),
            'date': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error saving workout: $e');
    }
  }

  Stream<int> _getUserGoalStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(100);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('goal')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return doc.data()!['targetPullUps'] as int? ?? 100;
          }
          return 100;
        });
  }

  Future<int> _getTotalPullUps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .get();

      int totalPullUps = 0;
      for (var doc in workoutsSnapshot.docs) {
        totalPullUps += (doc.data()['pullUpCount'] as int? ?? 0);
      }

      return totalPullUps;
    } catch (e) {
      debugPrint('Error fetching total pull-ups: $e');
      return 0;
    }
  }

  Future<void> _saveUserGoal(int targetPullUps) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goal')
          .set({
            'targetPullUps': targetPullUps,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  Future<void> _showSetGoalDialog(BuildContext context, int currentGoal) async {
    final TextEditingController goalController = TextEditingController(
      text: currentGoal.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Update Pull-Up Goal', // Judul lebih spesifik
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700, // Dibuat lebih tebal
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is your total pull-up goal?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: goalController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ), // Teks input lebih menonjol
              decoration: InputDecoration(
                hintText: 'Example: 100',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(
                  0.08,
                ), // Fill color lebih gelap
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryBlue,
                    width: 2,
                  ), // Border fokus lebih tebal
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(goalController.text.trim());
              if (goal == null || goal <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid number'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(context, goal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ), // Padding lebih besar
            ),
            child: const Text(
              'Save Goal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveUserGoal(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Goal updated successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showWorkoutSavedDialog(BuildContext context, int count) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: cardBg,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(
                      0.15,
                    ), // Opacity ditingkatkan
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .check_circle_outline, // Ikon diubah untuk lebih ringan
                    color: Colors.green.shade400,
                    size: 56, // Ikon sedikit lebih besar
                  ),
                ),
                const SizedBox(height: 24), // Jarak ditingkatkan
                const Text(
                  'Workout Saved!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count pull-ups recorded',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 28), // Jarak ditingkatkan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ), // Padding ditingkatkan
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done', // Ubah teks tombol
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLoginRequiredDialog(
    BuildContext context,
    String actionPurpose,
  ) async {
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
            '$actionPurpose, please login first.',
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
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Radius disesuaikan
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Login Now', // Ubah teks
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  // --- Widget Build Utama dengan desain baru ---
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
              // Hero Section dengan gambar background
              _buildHeroSection(context),

              const SizedBox(height: 40),

              // Weekly Goal Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) {
                      return _buildLoginPromptCard();
                    }
                    return _buildWeeklyGoalSection();
                  },
                ),
              ),

              const SizedBox(height: 40),

              // History Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user != null) {
                      return _buildHistorySection();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              const SizedBox(height: 100),

              // Camera FAB positioned at bottom
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _proceedToCamera(context),
        backgroundColor: primaryBlue,
        child: const Icon(Icons.videocam, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF0F1419)),
      child: Stack(
        children: [
          // Placeholder for image - leave empty for now
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
              child: Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 100,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Text overlay
          Positioned(
            left: 24,
            right: 24,
            bottom: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ilingo sing tau nolak awakmu !!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Consistency is the key to strength.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<int>(
          stream: _getUserGoalStream(),
          builder: (context, goalSnapshot) {
            final currentGoal = goalSnapshot.data ?? 40;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Goal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                InkWell(
                  onTap: () => _showSetGoalDialog(context, currentGoal),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: primaryBlue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Set Goal',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        StreamBuilder<int>(
          stream: _getUserGoalStream(),
          builder: (context, goalSnapshot) {
            final goal = goalSnapshot.data ?? 40;

            return FutureBuilder<int>(
              future: _getTotalPullUps(),
              builder: (context, currentSnapshot) {
                final current = currentSnapshot.data ?? 0;
                final progress = (current / goal).clamp(0.0, 1.0);

                return Center(
                  child: Column(
                    children: [
                      // Circular Progress
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 18,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(
                                  const Color(0xFF2A3240),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            // Progress circle
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 18,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(primaryBlue),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            // Percentage text
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$current/$goal Pull-ups',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('workouts')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No sessions yet. Start your first workout!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }

            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;
            final reps = data['pullUpCount'] ?? 0;
            final timestamp = data['timestamp'] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();

            String getTimeAgo(DateTime date) {
              final now = DateTime.now();
              final difference = now.difference(date);

              if (difference.inDays > 0) {
                return difference.inDays == 1
                    ? 'Yesterday'
                    : '${difference.inDays} days ago';
              } else if (difference.inHours > 0) {
                return '${difference.inHours} hours ago';
              } else if (difference.inMinutes > 0) {
                return '${difference.inMinutes} minutes ago';
              } else {
                return 'Just now';
              }
            }

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Placeholder image
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2530),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white.withOpacity(0.2),
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Session',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total Reps: $reps',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Form Score: 92%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                getTimeAgo(date),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
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
          },
        ),
      ],
    );
  }

  // Helper untuk Tips Item, menggunakan ikon sederhana
  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: primaryBlue.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Widget baru untuk meminta login
  Widget _buildLoginPromptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade400.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open_rounded,
                color: Colors.red.shade400,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Full Access Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Log in to view progress, save sessions, and set your pull-up goal.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
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
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Login / Sign Up',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
