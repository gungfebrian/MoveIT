import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Service for providing audio feedback during workouts.
/// Supports voice announcements and rep counting.
class AudioFeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Track last spoken values to avoid repetition
  String _lastFeedback = '';
  int _lastRepCount = 0;

  /// Initialize TTS engine
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Moderate speed
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('🔊 Audio feedback initialized');
    } catch (e) {
      debugPrint('⚠️ TTS initialization failed: $e');
    }
  }

  /// Speak the current rep count
  Future<void> announceRep(int count) async {
    if (!_isInitialized || _isSpeaking) return;
    if (count == _lastRepCount) return; // Don't repeat same count

    _lastRepCount = count;
    _isSpeaking = true;

    try {
      await _tts.speak('$count');
    } catch (e) {
      debugPrint('⚠️ TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  /// Speak form correction feedback
  Future<void> speakFeedback(String feedback) async {
    if (!_isInitialized || _isSpeaking) return;
    if (feedback == _lastFeedback) return; // Don't repeat same feedback
    if (feedback.isEmpty) return;

    // Only speak certain important messages
    final importantPhrases = [
      'Push Up!',
      'Go Down!',
      'Sit Up!',
      'Great form!',
      'Fix Form',
      'Position',
    ];

    bool shouldSpeak = importantPhrases.any(
      (phrase) => feedback.contains(phrase),
    );

    if (!shouldSpeak) return;

    _lastFeedback = feedback;
    _isSpeaking = true;

    try {
      await _tts.speak(feedback);
    } catch (e) {
      debugPrint('⚠️ TTS speak error: $e');
      _isSpeaking = false;
    }
  }

  /// Announce countdown number (3, 2, 1, GO!)
  Future<void> announceCountdown(int number) async {
    if (!_isInitialized) return;

    _isSpeaking = true;
    try {
      if (number > 0) {
        await _tts.speak('$number');
      } else {
        await _tts.speak('Go!');
      }
    } catch (e) {
      debugPrint('⚠️ TTS countdown error: $e');
    }
    _isSpeaking = false;
  }

  /// Stop any current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('⚠️ TTS stop error: $e');
    }
  }

  /// Reset tracked values (call when starting new session)
  void reset() {
    _lastFeedback = '';
    _lastRepCount = 0;
    _isSpeaking = false;
  }

  /// Clean up resources
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
