// lib/screens/profile_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _localPhotoPath;
  String? _avatarEmoji;
  PoseModelChoice _poseModelChoice = PoseModelChoice.accurate;

  // Dark theme colors
  final Color backgroundColor = const Color(0xFF0A1929);
  final Color cardColor = const Color(0xFF1A2B3D);
  final Color accentColor = const Color(0xFF4FC3F7);
  final Color textColor = const Color(0xFFFFFFFF);
  final Color subtitleColor = const Color(0xFF6B7D8F);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadPoseModelChoice();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString('profile_photo_${user.uid}');

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            if (photoPath != null && File(photoPath).existsSync()) {
              _localPhotoPath = photoPath;
            }
            _avatarEmoji = doc.data()?['avatar'];
          });
        }
      } catch (e) {
        debugPrint('Error loading profile data: $e');
      }
    }
  }

  Future<void> _loadPoseModelChoice() async {
    final service = SettingsService();
    final choice = await service.getPoseModelChoice();
    if (!mounted) return;
    setState(() => _poseModelChoice = choice);
  }

  Future<void> _choosePoseModel() async {
    final selected = await showDialog<PoseModelChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Pose Model', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<PoseModelChoice>(
              title: Text(
                'Accurate (better quality)',
                style: TextStyle(color: textColor),
              ),
              value: PoseModelChoice.accurate,
              groupValue: _poseModelChoice,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              activeColor: accentColor,
            ),
            RadioListTile<PoseModelChoice>(
              title: Text(
                'Base (smaller, faster)',
                style: TextStyle(color: textColor),
              ),
              value: PoseModelChoice.base,
              groupValue: _poseModelChoice,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              activeColor: accentColor,
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await SettingsService().setPoseModelChoice(selected);
      if (!mounted) return;
      setState(() => _poseModelChoice = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pose model preference saved'),
          backgroundColor: accentColor,
        ),
      );
    }
  }

  Widget _buildProfilePhoto() {
    if (_localPhotoPath != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withOpacity(0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(_localPhotoPath!)),
        ),
      );
    } else if (_avatarEmoji != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withOpacity(0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFFE8C5A5),
          child: Text(_avatarEmoji!, style: const TextStyle(fontSize: 60)),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withOpacity(0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFFE8C5A5),
          child: Icon(Icons.person, size: 60, color: cardColor),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final User? user = AuthService().currentUser;
    final String displayName = user?.displayName ?? 'User';
    final String email = user?.email ?? 'Not registered';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              // Profile Title
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 30),

              // Profile Photo with Glow Effect
              _buildProfilePhoto(),
              const SizedBox(height: 20),

              // User Name
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),

              // User Email
              Text(email, style: TextStyle(fontSize: 16, color: subtitleColor)),
              const SizedBox(height: 40),

              // Menu Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Dark Mode Toggle
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.dark_mode_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: Colors.white,
                            activeTrackColor: accentColor,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                        color: subtitleColor.withOpacity(0.2),
                      ),

                      // Edit Profile
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.edit_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        title: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: subtitleColor,
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                          if (result == true) {
                            _loadProfileData();
                          }
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                        color: subtitleColor.withOpacity(0.2),
                      ),

                      // Settings
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.settings_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        title: Text(
                          'Pose Model',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _poseModelChoice == PoseModelChoice.accurate
                              ? 'Accurate (better quality)'
                              : 'Base (smaller, faster)',
                          style: TextStyle(fontSize: 13, color: subtitleColor),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: subtitleColor,
                        ),
                        onTap: _choosePoseModel,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                        color: subtitleColor.withOpacity(0.2),
                      ),

                      // Settings
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.settings_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        title: Text(
                          'Settings',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: subtitleColor,
                        ),
                        onTap: () {
                          // Navigate to settings page
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 24,
                        endIndent: 24,
                        color: subtitleColor.withOpacity(0.2),
                      ),

                      // Pull-Up History
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        leading: Icon(
                          Icons.history_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        title: Text(
                          'Pull-Up History',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: subtitleColor,
                        ),
                        onTap: () {
                          // Navigate to history page
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A1A1A),
                      foregroundColor: const Color(0xFFFF5555),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 24),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
