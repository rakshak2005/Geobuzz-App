import 'package:flutter/services.dart';

class DeviceChannelService {
  static const MethodChannel _channel = MethodChannel('com.geobuzz/device_channel');

  static Future<String> getRingerMode() async {
    try {
      final String mode = await _channel.invokeMethod('getRingerMode');
      return mode;
    } on PlatformException catch (_) {
      return 'NORMAL';
    }
  }

  static Future<bool> setRingerMode(String mode) async {
    try {
      final bool result = await _channel.invokeMethod('setRingerMode', {'mode': mode});
      return result;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception('DND_PERMISSION_REQUIRED');
      }
      return false;
    }
  }

  static Future<bool> isNotificationPolicyAccessGranted() async {
    try {
      final bool result = await _channel.invokeMethod('isNotificationPolicyAccessGranted');
      return result;
    } on PlatformException catch (_) {
      return true;
    }
  }

  static Future<void> openNotificationPolicySettings() async {
    try {
      await _channel.invokeMethod('openNotificationPolicySettings');
    } on PlatformException catch (_) {}
  }

  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } on PlatformException catch (_) {}
  }

  static Future<void> openBluetoothSettings() async {
    try {
      await _channel.invokeMethod('openBluetoothSettings');
    } on PlatformException catch (_) {}
  }
}
