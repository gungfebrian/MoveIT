import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'settings_screen.dart';
import '../utils/responsive.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _localPhotoPath;
  Map<String, dynamic> _userStats = {'workouts': 0, 'streak': 0};

  // Theme Colors
  static const Color pDarkBg = Color(0xFF08080C);
  static const Color pCardBg = Color(0xFF12121A);
  static const Color primaryOrange = Color(0xFFFF5C00);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadUserStats();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString('profile_photo_${user.uid}');

      if (photoPath != null && File(photoPath).existsSync()) {
        setState(() {
          _localPhotoPath = photoPath;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch stats (mock or real)
      // For now, let's just get workout count
      final workouts = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .count()
          .get();

      setState(() {
        _userStats = {
          'workouts': workouts.count,
          'streak': 0, // Gets updated by StreakService usually
        };
      });
    }
  }

  Future<void> _handleManageData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Manage Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You can clear your workout history here. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearWorkoutHistory();
            },
            child: const Text(
              'Clear History',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearWorkoutHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .get();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout history cleared'),
            backgroundColor: primaryOrange,
          ),
        );
        _loadUserStats(); // Refresh stats
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Athlete';
    final email = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: pDarkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, 0.06),
          ),
          child: Column(
            children: [
              SizedBox(height: Responsive.height(context, 0.025)),
              // Profile Header
              _buildProfileHeader(context, displayName, email),
              SizedBox(height: Responsive.height(context, 0.04)),

              // Stats Row
              _buildStatsRow(context),
              SizedBox(height: Responsive.height(context, 0.04)),

              // Menu Options
              Container(
                decoration: BoxDecoration(
                  color: pCardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      'Settings',
                      Icons.settings_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      'Manage Data',
                      Icons.storage_rounded,
                      onTap: _handleManageData,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      'Help & Support',
                      Icons.help_outline_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.03)),

              // Logout Button
              _buildLogoutButton(context),
              SizedBox(
                height: Responsive.height(context, 0.12),
              ), // Space for navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    return Column(
      children: [
        Container(
          width: Responsive.width(context, 0.28),
          height: Responsive.width(context, 0.28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryOrange, width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            color: pCardBg,
          ),
          child: ClipOval(
            child: _localPhotoPath != null
                ? Image.file(File(_localPhotoPath!), fit: BoxFit.cover)
                : Icon(
                    Icons.person_rounded,
                    size: Responsive.icon(context, 0.15),
                    color: Colors.white,
                  ),
          ),
        ),
        SizedBox(height: Responsive.height(context, 0.025)),
        Text(
          name,
          style: TextStyle(
            fontSize: Responsive.text(context, 0.06),
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: Responsive.height(context, 0.01)),
        Text(
          email,
          style: TextStyle(
            fontSize: Responsive.text(context, 0.035),
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            'Workouts',
            '${_userStats['workouts']}',
          ),
        ),
        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
        Expanded(child: _buildStatItem(context, 'Check-in', 'Daily')),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.text(context, 0.06),
            fontWeight: FontWeight.w800,
            color: primaryOrange,
          ),
        ),
        SizedBox(height: Responsive.height(context, 0.005)),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, 0.03),
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 68,
      endIndent: 20,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          await AuthService().signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.height(context, 0.02),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF2A1215), // Dark Red
        ),
        child: Text(
          'Log Out',
          style: TextStyle(
            color: const Color(0xFFFF4545),
            fontSize: Responsive.text(context, 0.04),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
