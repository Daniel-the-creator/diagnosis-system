import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service responsible for queue call vocal announcements on waiting room TV displays
/// and consultation desk terminals.
class AudioAnnouncementService {
  AudioAnnouncementService({bool initialEnabled = true})
      : _isEnabled = initialEnabled;

  FlutterTts? _tts;
  bool _isEnabled;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  Future<void> initialize({
    String language = 'en-US',
    double speechRate = 0.9,
  }) async {
    if (_isInitialized) return;
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage(language);
      await _tts?.setSpeechRate(speechRate);
      await _tts?.setPitch(1.0);
      await _tts?.setVolume(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('AudioAnnouncementService init warning: $e');
    }
  }

  /// Announces when a patient is called to a consultation room.
  /// Example speech:
  /// "Queue number DOC-024, please proceed to Consultation Room 103."
  Future<void> announcePatientCall({
    required String queueNumber,
    required String roomName,
  }) async {
    if (!_isEnabled) return;

    if (!_isInitialized) {
      await initialize();
    }

    // Format clean spoken room text
    String formattedRoom = roomName.trim();
    if (!formattedRoom.toLowerCase().contains('room')) {
      formattedRoom = 'Room $formattedRoom';
    }

    // Spoken queue number with spacing for clarity (e.g. D O C 0 2 4)
    final spokenNumber = queueNumber.replaceAllMapped(
      RegExp(r'([A-Za-z]+)-?(\d+)'),
      (m) => '${m[1]?.toUpperCase() ?? ''}, ${m[2]?.split('').join(' ') ?? ''}',
    );

    final phrase =
        'Queue number $spokenNumber, please proceed to $formattedRoom.';

    try {
      await _tts?.stop();
      await _tts?.speak(phrase);
    } catch (e) {
      debugPrint('Audio announcement speech error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
