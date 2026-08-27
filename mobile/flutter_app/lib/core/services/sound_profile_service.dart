import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'device_channel_service.dart';

class SoundProfileService {
  static final SoundProfileService instance = SoundProfileService._init();
  SoundProfileService._init();

  static const String _prevModeKey = 'previous_sound_mode';

  Future<String> getCurrentMode() async {
    return await DeviceChannelService.getRingerMode();
  }

  Future<bool> applySoundProfile(String targetMode, {bool saveCurrentState = true}) async {
    try {
      if (saveCurrentState) {
        final currentMode = await getCurrentMode();
        // Save current mode so it can be restored on exit
        await DatabaseHelper.instance.setDeviceState(_prevModeKey, currentMode);
      }

      await DeviceChannelService.setRingerMode(targetMode.toUpperCase());
      return true;
    } catch (e) {
      debugPrint('Sound profile apply error: $e');
      rethrow;
    }
  }

  Future<bool> restorePreviousSoundProfile() async {
    try {
      final savedMode = await DatabaseHelper.instance.getDeviceState(_prevModeKey);
      if (savedMode != null && savedMode.isNotEmpty) {
        await DeviceChannelService.setRingerMode(savedMode);
        return true;
      } else {
        // Fallback to NORMAL
        await DeviceChannelService.setRingerMode('NORMAL');
        return true;
      }
    } catch (e) {
      debugPrint('Sound profile restore error: $e');
      return false;
    }
  }
}
