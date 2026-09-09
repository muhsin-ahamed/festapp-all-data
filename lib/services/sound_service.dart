import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SoundService handles audio feedback for scanner events.
/// It provides a crisp QR scanner beep confirmation sound, haptic feedback,
/// and safeguards against rapid-fire repeated sounds.
class SoundService {
  SoundService._();

  static AudioPlayer? _player;
  static DateTime? _lastPlayTime;
  static bool _isInitializing = false;

  /// Lazily initialize the AudioPlayer
  static Future<AudioPlayer> _getPlayer() async {
    if (_player != null) return _player!;
    if (!_isInitializing) {
      _isInitializing = true;
      try {
        final player = AudioPlayer();
        await player.setVolume(1.0);
        await player.setReleaseMode(ReleaseMode.stop);
        _player = player;
      } catch (e) {
        debugPrint('SoundService AudioPlayer init error: $e');
      } finally {
        _isInitializing = false;
      }
    }
    return _player ?? AudioPlayer();
  }

  /// Plays the authentic scanner beep sound once when a QR code is detected.
  /// Throttled to avoid rapid duplicate beeps.
  static Future<void> playQrScanSound() async {
    final now = DateTime.now();
    if (_lastPlayTime != null &&
        now.difference(_lastPlayTime!).inMilliseconds < 800) {
      return;
    }
    _lastPlayTime = now;

    // 1. Tactile feedback on mobile devices
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // 2. Audible scanner confirmation beep
    try {
      final player = await _getPlayer();
      await player.stop();
      await player.play(
        AssetSource('sounds/qr_beep.wav'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Audio playback error, falling back to SystemSound: $e');
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    try {
      await _player?.dispose();
      _player = null;
    } catch (_) {}
  }
}
