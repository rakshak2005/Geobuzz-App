import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._init();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _stopTimer;
  final ValueNotifier<bool> isAlarmActive = ValueNotifier<bool>(false);
  final ValueNotifier<String?> activeAlarmRuleName = ValueNotifier<String?>(null);

  AlarmService._init();

  Future<void> triggerAlarm({
    required String ruleName,
    int durationSeconds = 15,
    bool enableVibration = true,
  }) async {
    // Stop any currently running alarm
    await stopAlarm();

    isAlarmActive.value = true;
    activeAlarmRuleName.value = ruleName;

    // Start Vibration Pattern if on mobile
    if (!kIsWeb && enableVibration) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(
            pattern: [500, 500, 500, 500, 500, 500],
            repeat: 0,
          );
        }
      } catch (_) {}
    }

    // Play Alarm Tone
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // High quality Google Actions alarm sound
      await _audioPlayer.play(
        UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'),
      );
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }

    // Auto-stop after duration
    _stopTimer?.cancel();
    _stopTimer = Timer(Duration(seconds: durationSeconds), () {
      stopAlarm();
    });
  }

  Future<void> stopAlarm() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    isAlarmActive.value = false;
    activeAlarmRuleName.value = null;

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await Vibration.cancel();
      } catch (_) {}
    }
  }
}
