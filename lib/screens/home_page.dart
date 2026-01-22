// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'progress_screen.dart';
import 'profile_tab.dart';
import '../services/auth_service.dart';

import 'package:camera/camera.dart'; // Added for camera access
import 'workout_setup_screen.dart'; // Added for navigation
import '../widgets/liquid_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Using theme colors
  static const Color primaryOrange = AppTheme.primary;
  static const Color cardBg = AppTheme.card;

  static final List<Widget> _pages = <Widget>[
    const HomeTab(),
    const HistoryTab(), // Workouts/History
    const ProgressScreen(), // New Progress Screen
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient Glow (Top Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: primaryOrange.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          _pages[_selectedIndex],

          // Liquid Glass Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              onFabTap: _onStartWorkout,
            ),
          ),
        ],
      ),
    );
  }

  void _onStartWorkout() async {
    final cameras = await availableCameras();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WorkoutSetupScreen(camera: cameras.first, cameras: cameras),
      ),
    );
  }
}
