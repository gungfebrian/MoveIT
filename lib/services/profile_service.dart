// lib/services/profile_service.dart
// Service for managing user profile data (avatar, status, custom photo) with SharedPreferences
// Provides streams for real-time sync between screens

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Stream controllers for reactive updates
  final _avatarController = StreamController<int>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _customPhotoController = StreamController<String?>.broadcast();

  Stream<int> get avatarStream => _avatarController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<String?> get customPhotoStream => _customPhotoController.stream;

  // Avatar options - emoji-based avatars for simplicity
  static const List<String> avatarEmojis = [
    '💪', // Flexed bicep
    '🏃', // Running
    '🏋️', // Weightlifting
    '🧘', // Yoga
    '🚴', // Cycling
    '⚡', // Lightning
    '🔥', // Fire
    '🌟', // Star
    '🎯', // Target
    '🏆', // Trophy
    '👊', // Fist bump
    '🦾', // Mechanical arm
  ];

  // Status options
  static const List<String> statusOptions = [
    "Let's crush it! 💪",
    "No pain, no gain! 🔥",
    "Beast mode activated! 🦁",
    "Stronger every day! ⚡",
    "Making gains! 📈",
    "Stay consistent! 🎯",
    "One rep at a time! 💪",
    "Push your limits! 🚀",
    "Champions train! 🏆",
    "Never give up! 🙌",
  ];

  // Keys for SharedPreferences
  static const String _avatarKey = 'user_avatar_index';
  static const String _statusKey = 'user_status';
  static const String _customPhotoKey = 'user_custom_photo_path';

  // Get current avatar index (-1 means custom photo is used)
  Future<int> getAvatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_avatarKey) ?? 0;
  }

  // Set avatar index (-1 for custom photo)
  Future<void> setAvatarIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarKey, index);
    _avatarController.add(index);
  }

  // Get current status
  Future<String> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_statusKey) ?? statusOptions[0];
  }

  // Set status
  Future<void> setStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status);
    _statusController.add(status);
  }

  // Get custom photo path
  Future<String?> getCustomPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPhotoKey);
  }

  // Set custom photo path
  Future<void> setCustomPhotoPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_customPhotoKey, path);
      await setAvatarIndex(-1); // -1 indicates custom photo
    } else {
      await prefs.remove(_customPhotoKey);
    }
    _customPhotoController.add(path);
  }

  // Get avatar emoji by index
  String getAvatarEmoji(int index) {
    if (index >= 0 && index < avatarEmojis.length) {
      return avatarEmojis[index];
    }
    return avatarEmojis[0];
  }

  // Dispose streams
  void dispose() {
    _avatarController.close();
    _statusController.close();
    _customPhotoController.close();
  }
}
