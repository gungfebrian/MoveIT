import 'package:shared_preferences/shared_preferences.dart';

enum PoseModelChoice { accurate, base }

class SettingsService {
  static const _poseModelKey = 'pose_model_choice';

  Future<PoseModelChoice> getPoseModelChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_poseModelKey);
    switch (value) {
      case 'base':
        return PoseModelChoice.base;
      case 'accurate':
      default:
        return PoseModelChoice.accurate;
    }
  }

  Future<void> setPoseModelChoice(PoseModelChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _poseModelKey,
      choice == PoseModelChoice.base ? 'base' : 'accurate',
    );
  }
}
