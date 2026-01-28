import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'settings_screen.dart';
import '../utils/responsive.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic> _userStats = {'workouts': 0, 'streak': 0};

  // Profile customization
  final ProfileService _profileService = ProfileService();
  int _avatarIndex = 0;
  String _userStatus = ProfileService.statusOptions[0];
  String? _customPhotoPath;

  // Theme Colors - using AppTheme
  static Color get pDarkBg => AppTheme.background;
  static Color get pCardBg => AppTheme.card;
  static Color get primaryOrange => AppTheme.primary;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _loadProfileCustomization();
  }

  Future<void> _loadProfileCustomization() async {
    final avatarIndex = await _profileService.getAvatarIndex();
    final status = await _profileService.getStatus();
    final customPhotoPath = await _profileService.getCustomPhotoPath();
    setState(() {
      _avatarIndex = avatarIndex;
      _userStatus = status;
      _customPhotoPath = customPhotoPath;
    });
  }

  Future<void> _pickCustomPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      await _profileService.setCustomPhotoPath(image.path);
      setState(() {
        _customPhotoPath = image.path;
        _avatarIndex = -1; // -1 indicates custom photo
      });
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
          SnackBar(
            content: const Text('Workout history cleared'),
            backgroundColor: primaryOrange,
          ),
        );
        _loadUserStats(); // Refresh stats
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: pCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.width(context, 0.06)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 0.06)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Avatar',
              style: TextStyle(
                fontSize: Responsive.text(context, 0.05),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.height(context, 0.025)),
            Wrap(
              spacing: Responsive.width(context, 0.03),
              runSpacing: Responsive.width(context, 0.03),
              children: [
                // Custom Photo Button
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickCustomPhoto();
                  },
                  child: Container(
                    width: Responsive.width(context, 0.14),
                    height: Responsive.width(context, 0.14),
                    decoration: BoxDecoration(
                      color: _avatarIndex == -1
                          ? primaryOrange.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        Responsive.width(context, 0.04),
                      ),
                      border: Border.all(
                        color: _avatarIndex == -1
                            ? primaryOrange
                            : primaryOrange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _customPhotoPath != null && _avatarIndex == -1
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Responsive.width(context, 0.035),
                            ),
                            child: Image.file(
                              File(_customPhotoPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: primaryOrange,
                                size: Responsive.icon(context, 0.06),
                              ),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  fontSize: Responsive.text(context, 0.025),
                                  color: primaryOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                // Emoji Avatars
                ...List.generate(
                  ProfileService.avatarEmojis.length,
                  (index) => GestureDetector(
                    onTap: () async {
                      await _profileService.setAvatarIndex(index);
                      setState(() => _avatarIndex = index);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: Responsive.width(context, 0.14),
                      height: Responsive.width(context, 0.14),
                      decoration: BoxDecoration(
                        color: _avatarIndex == index
                            ? primaryOrange.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(
                          Responsive.width(context, 0.04),
                        ),
                        border: Border.all(
                          color: _avatarIndex == index
                              ? primaryOrange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          ProfileService.avatarEmojis[index],
                          style: TextStyle(
                            fontSize: Responsive.text(context, 0.07),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(context, 0.02)),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    final TextEditingController customStatusController =
        TextEditingController();
    const int maxChars = 50;

    showModalBottomSheet(
      context: context,
      backgroundColor: pCardBg,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.width(context, 0.06)),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.all(Responsive.padding(context, 0.06)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: Responsive.width(context, 0.1),
                  height: Responsive.height(context, 0.005),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.02)),
              Text(
                'Choose Status',
                style: TextStyle(
                  fontSize: Responsive.text(context, 0.05),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.02)),

              // Custom Status Input
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context, 0.04),
                  vertical: Responsive.padding(context, 0.02),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(
                    Responsive.width(context, 0.04),
                  ),
                  border: Border.all(color: primaryOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: primaryOrange,
                      size: Responsive.icon(context, 0.05),
                    ),
                    SizedBox(width: Responsive.width(context, 0.03)),
                    Expanded(
                      child: TextField(
                        controller: customStatusController,
                        maxLength: maxChars,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.text(context, 0.038),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write custom status...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: Responsive.text(context, 0.038),
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: Responsive.text(context, 0.03),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final customStatus = customStatusController.text.trim();
                        if (customStatus.isNotEmpty) {
                          await _profileService.setStatus(customStatus);
                          setState(() => _userStatus = customStatus);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(
                          Responsive.padding(context, 0.02),
                        ),
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(
                            Responsive.width(context, 0.02),
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: Responsive.icon(context, 0.045),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.height(context, 0.02)),
              Text(
                'Or choose from presets:',
                style: TextStyle(
                  fontSize: Responsive.text(context, 0.035),
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              SizedBox(height: Responsive.height(context, 0.01)),

              // Scrollable preset list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ProfileService.statusOptions.length,
                  itemBuilder: (context, index) {
                    final status = ProfileService.statusOptions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: Responsive.width(context, 0.06),
                        height: Responsive.width(context, 0.06),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _userStatus == status
                              ? primaryOrange
                              : Colors.white.withOpacity(0.1),
                          border: Border.all(
                            color: _userStatus == status
                                ? primaryOrange
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: _userStatus == status
                            ? Icon(
                                Icons.check,
                                size: Responsive.icon(context, 0.04),
                                color: Colors.white,
                              )
                            : null,
                      ),
                      title: Text(
                        status,
                        style: TextStyle(
                          fontSize: Responsive.text(context, 0.038),
                          color: Colors.white,
                          fontWeight: _userStatus == status
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      onTap: () async {
                        await _profileService.setStatus(status);
                        setState(() => _userStatus = status);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      'Change Status',
                      Icons.mood_rounded,
                      onTap: _showStatusPicker,
                    ),
                    _buildDivider(),
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
        // Tappable Avatar
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Stack(
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
                  child: _avatarIndex == -1 && _customPhotoPath != null
                      ? Image.file(
                          File(_customPhotoPath!),
                          fit: BoxFit.cover,
                          width: Responsive.width(context, 0.28),
                          height: Responsive.width(context, 0.28),
                        )
                      : Center(
                          child: Text(
                            _profileService.getAvatarEmoji(_avatarIndex),
                            style: TextStyle(
                              fontSize: Responsive.text(context, 0.12),
                            ),
                          ),
                        ),
                ),
              ),
              // Edit badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: pDarkBg, width: 3),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          if (isLoggedIn) {
            // User is logged in - sign out
            await AuthService().signOut();
          }
          // Navigate to login page
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
          backgroundColor: isLoggedIn
              ? const Color(0xFF2A1215) // Dark Red for logout
              : primaryOrange.withOpacity(0.15), // Orange tint for login
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
              color: primaryOrange,
              size: Responsive.icon(context, 0.05),
            ),
            SizedBox(width: Responsive.width(context, 0.02)),
            Text(
              isLoggedIn ? 'Log Out' : 'Login here',
              style: TextStyle(
                color: primaryOrange,
                fontSize: Responsive.text(context, 0.04),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
